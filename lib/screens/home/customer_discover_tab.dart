import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../customer_location_prefs.dart';
import '../../customer_session_prefs.dart';
import '../../l10n/app_localizations.dart';
import '../../data/bundled_cuisines.dart';
import '../../models/customer_cuisine.dart';
import '../../models/customer_dish_category.dart';
import '../../models/customer_featured_kitchen.dart';
import '../../models/customer_home_slider.dart';
import '../../models/dish_detail_entry.dart';
import '../../models/customer_order.dart';
import '../../navigation/customer_shell_navigation.dart';
import '../../services/customer_orders_store.dart';
import '../../services/optica2_api.dart';
import '../../services/recently_viewed_dishes_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../utils/app_system_ui.dart';
import '../../utils/image_dominant_color.dart';
import '../../widgets/cuisines_section.dart';
import '../../widgets/delivery_location_sheet.dart';
import '../../widgets/customer_home_slider_carousel.dart';
import '../../widgets/discover_section_heading.dart';
import '../../widgets/dish_categories_section.dart';
import '../../widgets/floating_food_icons.dart';
import '../../widgets/kitchen_browse_chrome.dart';
import '../../widgets/kitchen_list_card.dart';
import '../../widgets/pending_order_status_card.dart';
import '../../widgets/recently_viewed_dishes_section.dart';
import '../../widgets/view_all_button.dart';
import '../../widgets/with_love_from_maa_footer.dart';
import '../all_kitchens_screen.dart';
import '../../utils/dish_detail_route.dart';
import '../dish_detail_screen.dart';
import '../featured_dishes_screen.dart';
import '../kitchen_detail_screen.dart';
import '../order_detail_screen.dart';
import '../customer_notifications_screen.dart';

class _HeroPalette {
  const _HeroPalette({required this.primary, required this.deep});

  final Color primary;
  final Color deep;

  static const fallback = _HeroPalette(
    primary: AppColors.brandPurple,
    deep: AppColors.brandPurpleDeep,
  );

  factory _HeroPalette.fromColor(Color base) {
    final pair = heroGradientFromColor(base);
    return _HeroPalette(primary: pair.$1, deep: pair.$2);
  }
}

class CustomerDiscoverTab extends StatefulWidget {
  const CustomerDiscoverTab({super.key});

  @override
  State<CustomerDiscoverTab> createState() => _CustomerDiscoverTabState();
}

class _CustomerDiscoverTabState extends State<CustomerDiscoverTab> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _scrollController = ScrollController();
  final _api = Optica2Api();
  var _stickySearch = false;
  String _locationLabel = '';
  List<CustomerDishCategory> _dishCategories = const [];
  var _dishCategoriesLoading = true;
  List<CustomerHomeSlider> _sliders = const [];
  var _slidersLoading = true;
  List<CustomerHomeSlider> _midSliders = const [];
  List<_HeroPalette> _slidePalettes = const [];
  var _slideIndex = 0;
  List<CustomerFeaturedKitchen> _featuredKitchens = const [];
  var _featuredLoading = true;
  List<CustomerCuisine> _cuisines = const [];
  var _cuisinesLoading = true;
  String? _cancellingOrderId;
  var _unreadNotificationCount = 0;

  List<CustomerCuisine> get _displayCuisines =>
      BundledCuisines.displayList(_cuisines);

  _HeroPalette get _activePalette {
    if (_slidePalettes.isEmpty) return _HeroPalette.fallback;
    return _slidePalettes[_slideIndex.clamp(0, _slidePalettes.length - 1)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    if (_locationLabel.isEmpty) {
      _locationLabel = l10n.setYourLocation;
    }
  }

  @override
  void initState() {
    super.initState();
    CustomerShellNavigation.resetExploreHome = _resetToHome;
    _scrollController.addListener(_onScroll);
    _loadLocation();
    _loadSliders();
    _loadDishCategories();
    _loadFeaturedKitchens();
    _loadCuisines();
    _loadUnreadNotificationCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomerOrdersStore.instance.refresh();
    });
    RecentlyViewedDishesStore.instance.load();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold =
        _DiscoverChrome.headerScrollHeight(
          context,
          hasSlider: _slidersLoading || _sliders.isNotEmpty,
        ) -
        4;
    final sticky = _scrollController.offset >= threshold;
    if (sticky != _stickySearch && mounted) {
      setState(() => _stickySearch = sticky);
    }
  }

  Future<void> _cancelOrder(CustomerOrder order) async {
    setState(() => _cancellingOrderId = order.id);
    try {
      await CustomerOrdersStore.instance.cancelOrder(api: _api, order: order);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${order.id} was cancelled.')));
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not cancel order.')));
    } finally {
      if (mounted) setState(() => _cancellingOrderId = null);
    }
  }

  @override
  void dispose() {
    if (CustomerShellNavigation.resetExploreHome == _resetToHome) {
      CustomerShellNavigation.resetExploreHome = null;
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _api.close();
    super.dispose();
  }

  void _resetToHome() {
    final navigator = _navigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    if (_stickySearch && mounted) {
      setState(() => _stickySearch = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _loadLocation(),
      _loadSliders(),
      _loadDishCategories(),
      _loadFeaturedKitchens(),
      _loadCuisines(),
      _loadUnreadNotificationCount(),
      CustomerOrdersStore.instance.refresh(),
      RecentlyViewedDishesStore.instance.load(),
    ]);
  }

  Future<void> _loadLocation() async {
    final saved = await CustomerLocationPrefs.load();
    if (!mounted) return;
    if (saved == null) return;
    setState(() {
      final label = saved.label.trim();
      _locationLabel = label.isNotEmpty
          ? label
          : (saved.address.isNotEmpty ? saved.address : _locationLabel);
    });
  }

  Future<void> _openLocationPicker() async {
    await DeliveryLocationSheet.show(context);
    await _loadLocation();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final session = await CustomerSessionPrefs.load();
      if (session == null || !mounted) return;

      final result = await _api.fetchNotifications(
        customerId: session.id,
        phoneE164: session.phone,
      );
      if (!mounted) return;
      setState(() => _unreadNotificationCount = result.unreadCount);
    } catch (_) {
      // Ignore — badge is optional.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const CustomerNotificationsScreen(),
      ),
    );
    await _loadUnreadNotificationCount();
  }

  Future<void> _loadDishCategories() async {
    try {
      final categories = await _api.fetchDishCategories();
      if (!mounted) return;
      setState(() {
        _dishCategories = categories;
        _dishCategoriesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _dishCategoriesLoading = false);
    }
  }

  Future<void> _loadCuisines() async {
    try {
      final cuisines = await _api.fetchCuisines();
      if (!mounted) return;
      setState(() {
        _cuisines = cuisines;
        _cuisinesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cuisinesLoading = false);
    }
  }

  Future<void> _loadFeaturedKitchens() async {
    try {
      final kitchens = await _api.fetchFeaturedKitchens();
      if (!mounted) return;
      setState(() {
        _featuredKitchens = kitchens;
        _featuredLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _featuredLoading = false);
    }
  }

  Future<void> _loadSliders() async {
    try {
      final payload = await _api.fetchHomeSliders();
      if (!mounted) return;
      setState(() {
        _sliders = payload.hero;
        _midSliders = payload.mid;
        _slidersLoading = false;
        _slideIndex = 0;
        _slidePalettes = List.filled(payload.hero.length, _HeroPalette.fallback);
      });
      _extractSlidePalettes(payload.hero);
    } catch (_) {
      if (!mounted) return;
      setState(() => _slidersLoading = false);
    }
  }

  Future<void> _extractSlidePalettes(List<CustomerHomeSlider> sliders) async {
    final palettes = await Future.wait(
      sliders.map((slide) async {
        final raw = await dominantColorFromImageUrl(
          slide.imageUrl,
          client: _api.clientForImages,
        );
        if (raw == null) return _HeroPalette.fallback;
        return _HeroPalette.fromColor(heroColorFromImage(raw));
      }),
    );
    if (!mounted) return;
    setState(() => _slidePalettes = palettes);
  }

  void _onSliderPage(int index) {
    if (index == _slideIndex) return;
    setState(() => _slideIndex = index);
  }

  void _openKitchen(int kitchenId) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => KitchenDetailScreen(kitchenId: kitchenId),
      ),
    );
  }

  Future<void> _onSliderTap(CustomerHomeSlider slide) async {
    switch (slide.linkType) {
      case CustomerHomeSliderLinkType.kitchen:
        final kitchenId = slide.linkKitchenId;
        if (kitchenId != null) _openKitchen(kitchenId);
      case CustomerHomeSliderLinkType.dish:
        final kitchenId = slide.linkKitchenId;
        final dishId = slide.linkDishId;
        if (kitchenId == null || dishId == null) return;
        await _openDishFromSlider(kitchenId, dishId);
      case CustomerHomeSliderLinkType.url:
        final url = slide.linkUrl?.trim();
        if (url == null || url.isEmpty) return;
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      case CustomerHomeSliderLinkType.none:
        break;
    }
  }

  Future<void> _openDishFromSlider(int kitchenId, int dishId) async {
    try {
      final detail = await _api.fetchKitchenDetail(kitchenId);
      if (!mounted) return;
      final index = detail.dishes.indexWhere((d) => d.id == dishId);
      if (index < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This dish is no longer available.')),
          );
        }
        return;
      }
      final entries = [
        for (var i = 0; i < detail.dishes.length; i++)
          DishDetailEntry.fromCustomerDish(
            dish: detail.dishes[i],
            kitchenId: detail.kitchen.id,
            kitchenName: detail.kitchen.name,
            kitchenLogoUrl: detail.kitchen.logoUrl,
            chefName: detail.kitchen.chefName,
            kitchenInstantDeliveryEnabled: detail.kitchen.instantDeliveryEnabled,
            index: i,
          ),
      ];
      // Root navigator so the add-to-cart dock isn't covered by home bottom nav.
      Navigator.of(context, rootNavigator: true).push(
        DishDetailRoute.push(
          DishDetailScreen(
            entries: entries,
            initialIndex: index,
          ),
        ),
      );
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  void _openRecentlyViewedDishes(List<DishDetailEntry> entries, int initialIndex) {
    // Root navigator so the add-to-cart dock isn't covered by home bottom nav.
    Navigator.of(context, rootNavigator: true).push(
      DishDetailRoute.push(
        DishDetailScreen(
          entries: entries,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openAllKitchens() {
    _navigatorKey.currentState?.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 460),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (_, _, _) => const AllKitchensScreen(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInQuart,
          );
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(curved);
          final stretch = Tween<double>(begin: 1.06, end: 1).animate(curved);

          return SlideTransition(
            position: slide,
            child: Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.diagonal3Values(stretch.value, 1, 1),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Route<void> _discoverHomeRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => _buildDiscoverHome(),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: const Duration(milliseconds: 360),
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        final curvedSecondary = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.18, 0),
          ).animate(curvedSecondary),
          child: Transform.scale(
            alignment: Alignment.centerRight,
            scale: 1 - (0.02 * curvedSecondary.value),
            child: child,
          ),
        );
      },
    );
  }

  void _openCategory(CustomerDishCategory category) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => FeaturedDishesScreen(
          initialDishCategoryId: category.id,
          dishCategoryName: category.name,
          dishSubcategories: category.subcategories,
        ),
      ),
    );
  }

  void _openSearch(String query) {
    final trimmed = query.trim();
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => FeaturedDishesScreen(
          initialSearchQuery: trimmed.isEmpty ? null : trimmed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (_) => _discoverHomeRoute(),
    );
  }

  Widget _buildDiscoverHome() {
    final l10n = AppLocalizations.of(context)!;

    final palette = _activePalette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: ColoredBox(
        color: AppColors.cream,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FloatingFoodIcons(
                opacity: 0.10,
                count: 34,
              ),
            ),
            RefreshIndicator(
              color: AppColors.brandPurple,
              onRefresh: _refresh,
              edgeOffset: AppSystemUi.topInset(context, 8),
              child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _DiscoverHeader(
                  location: _locationLabel,
                  primary: palette.primary,
                  deep: palette.deep,
                  searchHint: l10n.searchKitchensDishes,
                  sliders: _sliders,
                  slidersLoading: _slidersLoading,
                  slideIndex: _slideIndex,
                  onLocationTap: _openLocationPicker,
                  onNotificationTap: _openNotifications,
                  onSearchSubmitted: _openSearch,
                  onSliderPageChanged: _onSliderPage,
                  onSliderTap: _onSliderTap,
                  unreadCount: _unreadNotificationCount,
                ),
              ),
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: CustomerOrdersStore.instance,
                  builder: (context, _) {
                    CustomerOrder? activeOrder;
                    for (final order in CustomerOrdersStore.instance.orders) {
                      if (order.isInProgress) {
                        activeOrder = order;
                        break;
                      }
                    }
                    if (activeOrder == null) return const SizedBox.shrink();
                    final order = activeOrder;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: PendingOrderStatusCard(
                        order: order,
                        compact: true,
                        cancelling: _cancellingOrderId == order.id,
                        onCancel: () => _cancelOrder(order),
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  OrderDetailScreen(
                                    order: order,
                                    navIndex: CustomerShellNavigation.tabExplore,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DishCategoriesSection(
                      categories: _dishCategories,
                      isLoading: _dishCategoriesLoading,
                      onCategoryTap: _openCategory,
                    ),
                    ListenableBuilder(
                      listenable: RecentlyViewedDishesStore.instance,
                      builder: (context, _) {
                        return RecentlyViewedDishesSection(
                          entries: RecentlyViewedDishesStore.instance.entries,
                          onDishTap: _openRecentlyViewedDishes,
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    CuisinesSection(
                      cuisines: _displayCuisines,
                      isLoading: _cuisinesLoading,
                    ),
                    if (_slidersLoading || _midSliders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: CustomerHomeSliderCarousel(
                          sliders: _midSliders,
                          isLoading: _slidersLoading,
                          onSlideTap: _onSliderTap,
                          aspectRatio: 16 / 9,
                          peekAdjacentSlides: true,
                          dotColor: AppColors.terracotta,
                        ),
                      ),
                    if (_featuredLoading ||
                        _featuredKitchens.isNotEmpty ||
                        (!_featuredLoading && _featuredKitchens.isEmpty))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                        child: DiscoverSectionHeading(
                          title: l10n.featuredKitchensTitle,
                          accent: AppColors.brandPurple,
                        ),
                      ),
                  ],
                ),
              ),
              if (_featuredLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    ),
                  ),
                )
              else if (_featuredKitchens.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      l10n.featuredKitchensEmpty,
                      style: AppFonts.style(
                        context,
                        fontSize: 14,
                        color: AppColors.deepGreen.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  sliver: SliverList.separated(
                    itemCount: _featuredKitchens.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: KitchenListCard.listSeparatorHeight),
                    itemBuilder: (context, i) => KitchenListCard(
                      kitchen: _featuredKitchens[i],
                      index: i,
                      animate: i < 4,
                      onTap: () => _openKitchen(_featuredKitchens[i].id),
                    ),
                  ),
                ),
              if (!_featuredLoading && _featuredKitchens.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: ViewAllButton(
                      label: l10n.viewAll,
                      onTap: _openAllKitchens,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: WithLoveFromMaaFooter()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
            ),
          if (_stickySearch)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: KitchenBrowseStickyShell(
                topInset: AppSystemUi.topInset(context, 8),
                lightGradient: true,
                child: _DiscoverSearchField(
                  hint: l10n.searchKitchensDishes,
                  primary: AppColors.brandPurple,
                  compact: true,
                  inHero: true,
                  onSubmitted: _openSearch,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _DiscoverChrome {
  /// Inner padding inside the sticky search strip (overlay is flush to top: 0).
  static const stickyInnerTopPadding = 10.0;

  static const compactBottomPadding = 8.0;

  /// Fraction of slider height covered by the hero gradient (below chrome).
  static const sliderInsideColorFraction = 0.42;

  static const _heroGradientOpacity = 0.5;

  /// Height shared by logo, location pill, notification, and search field.
  static const heroBarHeight = 48.0;

  static const heroBarRadius = 14.0;

  static double heroChromeHeight(BuildContext context) {
    final top = AppSystemUi.topInset(context, 8);
    return top + heroBarHeight + 12 + heroBarHeight + 16;
  }

  static double headerScrollHeight(
    BuildContext context, {
    required bool hasSlider,
  }) {
    final chromeH = heroChromeHeight(context);
    if (!hasSlider) return chromeH;
    return chromeH + CustomerHomeSliderCarousel.slideHeight(context) + 18;
  }

  static Color heroPrimary(Color base) =>
      base.withValues(alpha: _heroGradientOpacity);

  static Color heroDeep(Color base) =>
      base.withValues(alpha: _heroGradientOpacity);
}

/// Hero gradient + chrome + slider. Gradient extends downward over the slider top.
class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({
    required this.location,
    required this.primary,
    required this.deep,
    required this.searchHint,
    required this.sliders,
    required this.slidersLoading,
    required this.slideIndex,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onSearchSubmitted,
    required this.onSliderPageChanged,
    this.onSliderTap,
    this.unreadCount = 0,
  });

  final String location;
  final Color primary;
  final Color deep;
  final String searchHint;
  final List<CustomerHomeSlider> sliders;
  final bool slidersLoading;
  final int slideIndex;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<int> onSliderPageChanged;
  final ValueChanged<CustomerHomeSlider>? onSliderTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final chromeH = _DiscoverChrome.heroChromeHeight(context);
    final showSlider = slidersLoading || sliders.isNotEmpty;

    if (!showSlider) {
      return _DiscoverHeroGradient(
        primary: primary,
        deep: deep,
        child: _DiscoverHeroChrome(
          location: location,
          primary: primary,
          searchHint: searchHint,
          onLocationTap: onLocationTap,
          onNotificationTap: onNotificationTap,
          onSearchSubmitted: onSearchSubmitted,
          unreadCount: unreadCount,
        ),
      );
    }

    final slideH = CustomerHomeSliderCarousel.slideHeight(context);
    final colorBottom =
        chromeH + slideH * _DiscoverChrome.sliderInsideColorFraction;
    const dotsHeight = 18.0;
    final totalH = chromeH + slideH + dotsHeight;

    return SizedBox(
      height: totalH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: colorBottom,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _DiscoverChrome.heroPrimary(primary),
                    _DiscoverChrome.heroDeep(deep),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _DiscoverHeroChrome(
              location: location,
              primary: primary,
              searchHint: searchHint,
              onLocationTap: onLocationTap,
              onNotificationTap: onNotificationTap,
              onSearchSubmitted: onSearchSubmitted,
              unreadCount: unreadCount,
            ),
          ),
          Positioned(
            top: chromeH,
            left: 20,
            right: 20,
            height: slideH,
            child: CustomerHomeSliderCarousel(
              sliders: sliders,
              isLoading: slidersLoading,
              embedded: true,
              onPageChanged: onSliderPageChanged,
              onSlideTap: onSliderTap,
              dotColor: primary,
            ),
          ),
          if (!slidersLoading && sliders.length >= 2)
            Positioned(
              top: chromeH + slideH,
              left: 0,
              right: 0,
              child: CustomerHomeSliderCarousel.pageDots(
                count: sliders.length,
                activeIndex: slideIndex,
                dotColor: primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _DiscoverHeroGradient extends StatelessWidget {
  const _DiscoverHeroGradient({
    required this.primary,
    required this.deep,
    required this.child,
  });

  final Color primary;
  final Color deep;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _DiscoverChrome.heroPrimary(primary),
            _DiscoverChrome.heroDeep(deep),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class _DiscoverHeroChrome extends StatelessWidget {
  const _DiscoverHeroChrome({
    required this.location,
    required this.primary,
    required this.searchHint,
    required this.onLocationTap,
    required this.onNotificationTap,
    required this.onSearchSubmitted,
    this.unreadCount = 0,
  });

  final String location;
  final Color primary;
  final String searchHint;
  final VoidCallback onLocationTap;
  final VoidCallback onNotificationTap;
  final ValueChanged<String> onSearchSubmitted;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final top = AppSystemUi.topInset(context, 8);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: _DiscoverChrome.heroBarHeight,
                child: Center(
                  child: Image.asset(
                    'assets/images/made_by_maa_logo.png',
                    height: 42,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: _DiscoverChrome.heroBarHeight,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(
                      _DiscoverChrome.heroBarRadius,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onLocationTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.style(
                                  context,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: _DiscoverChrome.heroBarHeight,
                height: _DiscoverChrome.heroBarHeight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onNotificationTap,
                    borderRadius: BorderRadius.circular(
                      _DiscoverChrome.heroBarRadius,
                    ),
                    splashColor: Colors.white.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.06),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                textAlign: TextAlign.center,
                                style: AppFonts.style(
                                  context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _DiscoverSearchField(
              hint: searchHint,
              primary: primary,
              compact: false,
              inHero: true,
              onSubmitted: onSearchSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search inside the hero gradient, or compact bar in the top overlay when scrolled.
class _DiscoverSearchField extends StatelessWidget {
  const _DiscoverSearchField({
    required this.hint,
    required this.primary,
    required this.compact,
    this.inHero = false,
    this.onSubmitted,
  });

  final String hint;
  final Color primary;
  final bool compact;
  final bool inHero;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final top = inHero
        ? 0.0
        : (compact ? _DiscoverChrome.stickyInnerTopPadding : 4.0);
    final bottom = inHero
        ? 0.0
        : (compact ? _DiscoverChrome.compactBottomPadding : 12.0);
    final fieldVPad = compact ? 8.0 : (inHero ? 12.0 : 14.0);
    final radius = compact ? 12.0 : _DiscoverChrome.heroBarRadius;

    final field = TextField(
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      style: AppFonts.style(
        context,
        fontSize: compact ? 14 : 15,
        color: AppColors.deepGreen,
      ),
      decoration: InputDecoration(
        isDense: compact || inHero,
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: AppFonts.style(
          context,
          fontSize: compact ? 14 : 15,
          color: AppColors.deepGreen.withValues(alpha: 0.45),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: primary,
          size: compact ? 20 : 22,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: inHero
                ? Colors.transparent
                : primary.withValues(alpha: 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: fieldVPad),
        constraints: inHero
            ? const BoxConstraints(minHeight: _DiscoverChrome.heroBarHeight)
            : null,
      ),
    );

    if (inHero) {
      return SizedBox(height: _DiscoverChrome.heroBarHeight, child: field);
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.cream),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
        child: field,
      ),
    );
  }
}
