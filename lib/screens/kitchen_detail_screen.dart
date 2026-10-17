import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_dish.dart';
import '../models/dish_detail_entry.dart';
import '../models/customer_featured_kitchen.dart';
import '../models/customer_super_category.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_system_ui.dart';
import '../utils/optica2_asset_url.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/customer_dish_card.dart';
import '../widgets/customer_reviews_bottom_sheet.dart';
import '../widgets/customer_reviews_section.dart';
import '../widgets/dish_veg_filter_toggle.dart';
import '../widgets/floating_food_icons.dart';
import '../widgets/kitchen_browse_chrome.dart';
import '../widgets/kitchen_announcement_banner.dart';
import '../widgets/kitchen_list_card.dart';
import '../widgets/no_dishes_empty_state.dart';
import '../widgets/with_love_from_maa_footer.dart';
import '../utils/dish_detail_route.dart';
import 'dish_detail_screen.dart';

class KitchenDetailScreen extends StatefulWidget {
  const KitchenDetailScreen({super.key, required this.kitchenId});

  final int kitchenId;

  @override
  State<KitchenDetailScreen> createState() => _KitchenDetailScreenState();
}

class _KitchenDetailScreenState extends State<KitchenDetailScreen> {
  final _api = Optica2Api();
  CustomerFeaturedKitchen? _kitchen;
  List<CustomerDish> _dishes = const [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final detail = await _api.fetchKitchenDetail(widget.kitchenId);
      if (!mounted) return;
      setState(() {
        _kitchen = detail.kitchen;
        _dishes = detail.dishes;
        _loading = false;
      });
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load menu. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _load(showLoading: false);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayOnDark,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brandPurple),
              )
            : _error != null
            ? RefreshIndicator(
                color: AppColors.brandPurple,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
                    _ErrorBody(message: _error!, onRetry: _refresh),
                  ],
                ),
              )
            : _Content(
                kitchen: _kitchen!,
                dishes: _dishes,
                api: _api,
                kitchenLogoUrl: resolveOptica2AssetUrl(_kitchen!.logoUrl),
                onRefresh: _refresh,
              ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.brandPurple.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(fontSize: 15, color: AppColors.deepGreen),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'Try again',
                style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content({
    required this.kitchen,
    required this.dishes,
    required this.api,
    required this.onRefresh,
    this.kitchenLogoUrl,
  });

  final CustomerFeaturedKitchen kitchen;
  final List<CustomerDish> dishes;
  final Optica2Api api;
  final Future<void> Function() onRefresh;
  final String? kitchenLogoUrl;

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  static const _expandedHeight = 252.0;

  final _scrollController = ScrollController();
  var _showCollapsedTitle = false;
  DishVegFilter _vegFilter = DishVegFilter.all;
  int? _selectedCategoryId;
  int? _selectedSuperCategoryId;

  /// Full list of meal-time super categories (Breakfast/Lunch/Dinner/…) from
  /// the API. Used to render the meal-time chip row even when this kitchen's
  /// menu is missing some of them — the user still sees what slots exist.
  List<CustomerSuperCategory> _allSuperCategories = const [];

  /// Closed kitchens hide the menu until the user taps Pre-order.
  var _showPreOrderMenu = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadSuperCategories();
  }

  Future<void> _loadSuperCategories() async {
    try {
      final list = await widget.api.fetchSuperCategories();
      if (!mounted) return;
      setState(() {
        _allSuperCategories = list;
      });
    } catch (_) {
      // Silent — we'll fall back to dish-derived super categories.
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _expandedHeight - kToolbarHeight - 12;
    final show = _scrollController.offset > threshold;
    if (show != _showCollapsedTitle) {
      setState(() => _showCollapsedTitle = show);
    }
  }

  void _openDish(
    BuildContext context,
    List<CustomerDish> filteredDishes,
    int index,
  ) {
    final entries = [
      for (var i = 0; i < filteredDishes.length; i++)
        DishDetailEntry.fromCustomerDish(
          dish: filteredDishes[i],
          kitchenId: widget.kitchen.id,
          kitchenName: widget.kitchen.name,
          kitchenLogoUrl: widget.kitchenLogoUrl,
          chefName: widget.kitchen.chefName,
          kitchenInstantDeliveryEnabled: widget.kitchen.instantDeliveryEnabled,
          index: i,
        ),
    ];
    Navigator.of(context, rootNavigator: true).push(
      DishDetailRoute.push(
        DishDetailScreen(
          entries: entries,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kitchen = widget.kitchen;
    final dishes = widget.dishes;

    // Meal-time super categories: prefer the global list (so the user sees
    // all standard slots — Breakfast / Lunch / Dinner — even if this kitchen's
    // menu doesn't currently cover them). Fall back to dish-derived data if
    // the API call hasn't returned yet.
    final List<_MealTimeFilter> superCategories;
    if (_allSuperCategories.isNotEmpty) {
      superCategories = _allSuperCategories
          .map(
            (c) => _MealTimeFilter(
              id: c.id,
              label: c.name,
              slug: c.slug,
              timeRange: c.timeRange,
            ),
          )
          .toList();
    } else {
      final fallback = <_MealTimeFilter>[];
      final seenSuperCategoryIds = <int>{};
      for (final dish in dishes) {
        final cat = dish.mainCategory;
        if (cat == null || !cat.isValid) continue;
        if (seenSuperCategoryIds.add(cat.id)) {
          fallback.add(
            _MealTimeFilter(
              id: cat.id,
              label: cat.name,
              slug: cat.slug,
              timeRange: cat.timeRange,
            ),
          );
        }
      }
      superCategories = fallback;
    }

    // Which meal-time chips actually have at least one dish in this kitchen
    // (after the veg filter). Empty ones still render but greyed-out.
    final superCategoriesWithDishes = <int>{};
    for (final dish in dishes) {
      if (!_vegFilter.matchesDish(isVeg: dish.isVeg)) continue;
      final id = dish.mainCategory?.id;
      if (id != null && id > 0) superCategoriesWithDishes.add(id);
    }

    // Unique food-type categories present in this kitchen's menu, in order of
    // first appearance. Falls back to subcategory / super category grouping
    // when a dish has no `dish_category` tagged. Used for the top filter row.
    final categories = <_KitchenCategoryFilter>[];
    final seenCategoryIds = <int>{};
    for (final dish in dishes) {
      final id = dish.displayCategoryGroupId;
      if (id == -1) continue; // skip fully untagged dishes from the filter row
      final label = dish.displayCategoryLabel.trim();
      if (label.isEmpty ||
          label.toLowerCase() == 'all' ||
          label.toLowerCase().contains('all meal')) {
        continue;
      }
      if (seenCategoryIds.add(id)) {
        categories.add(
          _KitchenCategoryFilter(id: id, label: label),
        );
      }
    }

    // If a selection is no longer present (e.g. veg filter removed every dish
    // in that group), fall back to "All" for that row without losing the
    // user's other picks.
    final activeCategoryId =
        _selectedCategoryId != null &&
            categories.any((c) => c.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;
    final activeSuperCategoryId =
        _selectedSuperCategoryId != null &&
            superCategories.any((c) => c.id == _selectedSuperCategoryId)
        ? _selectedSuperCategoryId
        : null;

    final filteredDishes = dishes.where((dish) {
      if (!_vegFilter.matchesDish(isVeg: dish.isVeg)) return false;
      if (activeSuperCategoryId != null &&
          dish.mainCategory?.id != activeSuperCategoryId) {
        return false;
      }
      if (activeCategoryId != null &&
          dish.displayCategoryGroupId != activeCategoryId) {
        return false;
      }
      return true;
    }).toList();
    final bottomPad = CustomerBottomNav.contentBottomPadding(context);
    final showMenu = !kitchen.isClosed || _showPreOrderMenu;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        RefreshIndicator(
          color: AppColors.brandPurple,
          onRefresh: () async {
            await widget.onRefresh();
            await _loadSuperCategories();
          },
          edgeOffset: MediaQuery.viewPaddingOf(context).top + 56,
          child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: _expandedHeight,
              pinned: true,
              stretch: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: _showCollapsedTitle
                  ? Colors.transparent
                  : AppColors.brandPurpleDeep,
              foregroundColor: Colors.white,
              leadingWidth: 52,
              leading: _showCollapsedTitle
                  ? const SizedBox(width: 52)
                  : Center(
                      child: _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
              title: null,
              actions: _showCollapsedTitle || !showMenu
                  ? const <Widget>[]
                  : [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Center(
                          child: DishVegFilterToggle(
                            value: _vegFilter,
                            onChanged: (filter) {
                              if (_vegFilter == filter) return;
                              setState(() => _vegFilter = filter);
                            },
                          ),
                        ),
                      ),
                    ],
              flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Stack(
              fit: StackFit.expand,
              children: [
                const _CoverFallback(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(64, 18, 64, 18),
                      child: Center(
                        child: _CoverBottomMeta(
                          kitchen: kitchen,
                          onReviewsTap: () => CustomerReviewsBottomSheet.show(
                            context,
                            title: '${kitchen.name} reviews',
                            loadReviews: () =>
                                widget.api.fetchKitchenReviews(kitchen.id),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (kitchen.isClosed)
          SliverToBoxAdapter(
            child: KitchenClosedProfileBanner(
              onPreOrderTap: showMenu
                  ? null
                  : () => setState(() => _showPreOrderMenu = true),
            ),
          ),
        if (kitchen.announcement != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                kitchen.isClosed ? 12 : 14,
                20,
                0,
              ),
              child: KitchenAnnouncementBanner(
                announcement: kitchen.announcement!,
              ),
            ),
          ),
        if (showMenu && kitchen.tags.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                kitchen.isClosed ||
                        kitchen.announcement != null
                    ? 12
                    : 14,
                20,
                0,
              ),
              child: _KitchenTagsRow(tags: kitchen.tags),
            ),
          ),
        if (showMenu)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                kitchen.tags.isNotEmpty ||
                        kitchen.isClosed ||
                        kitchen.announcement != null
                    ? 18
                    : 20,
                20,
                superCategories.isNotEmpty || categories.isNotEmpty ? 10 : 12,
              ),
              child: _MenuHeader(dishCount: filteredDishes.length),
            ),
          ),
        if (showMenu && superCategories.isNotEmpty)
          SliverToBoxAdapter(
            child: _MealTimeFilterRow(
              items: superCategories,
              selectedId: activeSuperCategoryId,
              availableIds: superCategoriesWithDishes,
              onSelected: (id) {
                if (id == _selectedSuperCategoryId) return;
                setState(() => _selectedSuperCategoryId = id);
              },
            ),
          ),
        if (showMenu && categories.isNotEmpty)
          SliverToBoxAdapter(
            child: _CategoryFilterRow(
              categories: categories,
              selectedId: activeCategoryId,
              icon: Icons.restaurant_menu_rounded,
              onSelected: (id) {
                if (id == _selectedCategoryId) return;
                setState(() => _selectedCategoryId = id);
              },
            ),
          ),
        if (showMenu && dishes.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: NoDishesEmptyState(
                message: 'Menu coming soon',
                subtitle:
                    'This kitchen is updating their dishes. Check back shortly.',
                compact: true,
              ),
            ),
          )
        else if (showMenu && filteredDishes.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: const NoDishesEmptyState(
                message: 'No dishes match this filter',
                subtitle: 'Try a different category or veg / non-veg toggle.',
                compact: true,
              ),
            ),
          )
        else if (showMenu)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: CustomerDishCard.gridAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => CustomerDishCard(
                  dish: CustomerDishCardModel.fromDish(filteredDishes[i]),
                  accent: CustomerDishCard.accentForIndex(i),
                  onTap: () => _openDish(context, filteredDishes, i),
                ),
                childCount: filteredDishes.length,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: WithLoveFromFooter(
            name: kitchen.name,
            fssaiNumber: kitchen.fssaiNumber,
            bottomSpacing: bottomPad,
          ),
        ),
          ],
        ),
        ),
        if (_showCollapsedTitle)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: KitchenBrowseStickyShell(
              topInset: AppSystemUi.topInset(context, 4),
              child: Row(
                children: [
                  KitchenBrowseBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                    light: true,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CollapsedBarTitle(kitchen: kitchen),
                  ),
                  if (showMenu) ...[
                    const SizedBox(width: 8),
                    DishVegFilterToggle(
                      value: _vegFilter,
                      onChanged: (filter) {
                        if (_vegFilter == filter) return;
                        setState(() => _vegFilter = filter);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CollapsedBarTitle extends StatelessWidget {
  const _CollapsedBarTitle({required this.kitchen});

  final CustomerFeaturedKitchen kitchen;

  @override
  Widget build(BuildContext context) {
    return Text(
      kitchen.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _CoverBottomMeta extends StatelessWidget {
  const _CoverBottomMeta({required this.kitchen, this.onReviewsTap});

  final CustomerFeaturedKitchen kitchen;
  final VoidCallback? onReviewsTap;

  @override
  Widget build(BuildContext context) {
    final cuisine = kitchen.cuisine?.trim();
    final delivery = kitchen.deliveryLabel?.trim();
    final chef = kitchen.chefName?.trim();
    final hasCuisine = cuisine != null && cuisine.isNotEmpty;
    final hasDelivery = delivery != null && delivery.isNotEmpty;
    final hasChef = chef != null && chef.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasChef) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ChefIcon(size: 15, color: Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  chef,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                    shadows: const [
                      Shadow(blurRadius: 8, color: Color(0x80000000)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
        Text(
          kitchen.name,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.exo2(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.04,
            shadows: const [Shadow(blurRadius: 10, color: Color(0x99000000))],
          ),
        ),
        if (hasCuisine || hasDelivery) ...[
          const SizedBox(height: 9),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasCuisine)
                _HeaderInfoPill(
                  icon: Icons.restaurant_menu_rounded,
                  label: cuisine,
                ),
              if (hasDelivery)
                _HeaderInfoPill(
                  icon: Icons.delivery_dining_rounded,
                  label: delivery,
                ),
            ],
          ),
        ],
        if (kitchen.rating.hasReviews) ...[
          const SizedBox(height: 9),
          _TappableReviews(
            onTap: onReviewsTap,
            child: RatingSummaryRow(
              average: kitchen.rating.average,
              count: kitchen.rating.count,
              compact: true,
              light: true,
            ),
          ),
        ],
      ],
    );
  }
}

class _TappableReviews extends StatelessWidget {
  const _TappableReviews({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(width: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A chef silhouette (toque hat + head + shoulders) drawn in a single color so
/// it matches the header's monochrome icon styling. Material Icons has no
/// person-with-chef-hat glyph, so this is hand-drawn.
class _ChefIcon extends StatelessWidget {
  const _ChefIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChefIconPainter(color: color)),
    );
  }
}

class _ChefIconPainter extends CustomPainter {
  const _ChefIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // Shoulders / bust: narrow at the neck, widening toward the bottom.
    final body = Path()
      ..moveTo(w * 0.40, h * 0.74)
      ..cubicTo(w * 0.40, h * 0.86, w * 0.24, h * 0.84, w * 0.18, h * 1.02)
      ..lineTo(w * 0.82, h * 1.02)
      ..cubicTo(w * 0.76, h * 0.84, w * 0.60, h * 0.86, w * 0.60, h * 0.74)
      ..close();
    canvas.drawPath(body, paint);

    // Head.
    canvas.drawCircle(Offset(w * 0.5, h * 0.60), w * 0.145, paint);

    // Hat band sitting on the head.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.40, w * 0.40, h * 0.12),
        Radius.circular(w * 0.035),
      ),
      paint,
    );

    // Puffy top of the toque (three overlapping circles).
    canvas.drawCircle(Offset(w * 0.32, h * 0.31), w * 0.155, paint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.31), w * 0.155, paint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.24), w * 0.185, paint);
  }

  @override
  bool shouldRepaint(_ChefIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HeaderInfoPill extends StatelessWidget {
  const _HeaderInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenTagsRow extends StatelessWidget {
  const _KitchenTagsRow({required this.tags});

  final List<String> tags;

  static const _tagColors = [
    AppColors.sage,
    AppColors.brandPurple,
    AppColors.terracotta,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < tags.length; i++)
          _KitchenTag(tags[i], _tagColors[i % _tagColors.length]),
      ],
    );
  }
}

class _KitchenTag extends StatelessWidget {
  const _KitchenTag(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.exo2(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.dishCount});

  final int dishCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.terracotta.withValues(alpha: 0.2),
                AppColors.brandPurple.withValues(alpha: 0.12),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: AppColors.terracotta,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Full menu',
                style: GoogleFonts.exo2(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                ),
              ),
              Text(
                dishCount == 0
                    ? 'Browse what this kitchen offers'
                    : '$dishCount ${dishCount == 1 ? 'dish' : 'dishes'} to explore',
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  color: AppColors.deepGreen.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        if (dishCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$dishCount',
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// A category present in the kitchen's menu, used to render the filter row.
class _KitchenCategoryFilter {
  const _KitchenCategoryFilter({required this.id, required this.label});

  final int id;
  final String label;
}

/// Horizontal scrolling row of selectable category pills shown above the menu
/// grid. Tapping toggles which dishes are visible.
class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    this.icon = Icons.restaurant_menu_rounded,
  });

  final List<_KitchenCategoryFilter> categories;
  final int? selectedId;
  final IconData icon;

  /// `null` means "All".
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final selected = selectedId == cat.id;
          return _CategoryFilterChip(
            label: cat.label,
            icon: icon,
            selected: selected,
            onTap: () => onSelected(selected ? null : cat.id),
          );
        },
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : AppColors.brandPurple.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  color: AppColors.brandPurple.withValues(alpha: 0.28),
                ),
              ]
            : [
                BoxShadow(
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: selected
              ? Colors.white.withValues(alpha: 0.14)
              : AppColors.brandPurple.withValues(alpha: 0.08),
          highlightColor: selected
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.brandPurple.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : AppColors.brandPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.deepGreen,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A meal-time super category (Breakfast / Lunch / Dinner) shown in the
/// dedicated chip row above the menu grid.
class _MealTimeFilter {
  const _MealTimeFilter({
    required this.id,
    required this.label,
    required this.slug,
    required this.timeRange,
  });

  final int id;
  final String label;
  final String slug;
  final String timeRange;
}

/// Horizontal scrolling row of "creative" meal-time pills. Each pill shows a
/// meal-specific icon, the meal name, and its time window. Pills greyed out
/// when no dish in this kitchen matches that meal time.
class _MealTimeFilterRow extends StatelessWidget {
  const _MealTimeFilterRow({
    required this.items,
    required this.selectedId,
    required this.onSelected,
    required this.availableIds,
  });

  final List<_MealTimeFilter> items;
  final int? selectedId;
  final Set<int> availableIds;

  /// `null` means "All".
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final mealItems =
        items.where((item) => !_isAllMealsLabel(item.label)).toList();

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        itemCount: mealItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = mealItems[i];
          final available = availableIds.contains(item.id);
          final selected = selectedId == item.id;
          return _MealTimeChip(
            label: item.label,
            subtitle: item.timeRange.isEmpty ? null : item.timeRange,
            icon: _mealIconFor(item.slug, item.label),
            accent: _mealAccentFor(item.slug, item.label),
            selected: selected,
            available: available,
            onTap: () => onSelected(selected ? null : item.id),
          );
        },
      ),
    );
  }

  static bool _isAllMealsLabel(String label) {
    final normalized = label.trim().toLowerCase();
    return normalized == 'all' ||
        normalized == 'all meals' ||
        normalized == 'all meal';
  }

  static IconData _mealIconFor(String slug, String label) {
    final s = slug.toLowerCase();
    final l = label.toLowerCase();
    if (s.contains('break') || l.contains('break')) {
      return Icons.breakfast_dining_rounded;
    }
    if (s.contains('lunch') || l.contains('lunch')) {
      return Icons.lunch_dining_rounded;
    }
    if (s.contains('dinner') || l.contains('dinner')) {
      return Icons.dinner_dining_rounded;
    }
    if (s.contains('snack') || l.contains('snack')) {
      return Icons.cookie_rounded;
    }
    if (s.contains('brunch') || l.contains('brunch')) {
      return Icons.brunch_dining_rounded;
    }
    if (s.contains('drink') ||
        s.contains('beverage') ||
        l.contains('drink') ||
        l.contains('beverage')) {
      return Icons.local_cafe_rounded;
    }
    return Icons.access_time_rounded;
  }

  static Color _mealAccentFor(String slug, String label) {
    final s = slug.toLowerCase();
    final l = label.toLowerCase();
    if (s.contains('break') || l.contains('break')) return AppColors.amberGlow;
    if (s.contains('lunch') || l.contains('lunch')) return AppColors.terracotta;
    if (s.contains('dinner') || l.contains('dinner')) return AppColors.sage;
    if (s.contains('snack') || l.contains('snack')) {
      return AppColors.brandPurple;
    }
    return AppColors.brandPurple;
  }
}

class _MealTimeChip extends StatelessWidget {
  const _MealTimeChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = !available && !selected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, _shade(accent, 0.78)],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? Colors.transparent
              : (disabled
                    ? const Color(0xFFE7E7EC)
                    : accent.withValues(alpha: 0.22)),
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  color: accent.withValues(alpha: 0.36),
                ),
              ]
            : [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ],
      ),
      child: Opacity(
        opacity: disabled ? 0.55 : 1.0,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: selected
                ? Colors.white.withValues(alpha: 0.14)
                : accent.withValues(alpha: 0.08),
            highlightColor: selected
                ? Colors.white.withValues(alpha: 0.06)
                : accent.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected ? Colors.white : accent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.exo2(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : AppColors.deepGreen,
                          height: 1.05,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.exo2(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.86)
                                : AppColors.deepGreen.withValues(alpha: 0.55),
                            height: 1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Slightly darker shade of [base] used for the gradient end stop.
  static Color _shade(Color base, double factor) {
    return Color.from(
      alpha: base.a,
      red: (base.r * factor).clamp(0.0, 1.0),
      green: (base.g * factor).clamp(0.0, 1.0),
      blue: (base.b * factor).clamp(0.0, 1.0),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
            ),
          ),
        ),
        const Positioned.fill(
          child: FloatingFoodIcons(
            opacity: 0.14,
            count: 10,
            seed: 11,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: KitchenBrowseChrome.waveHeight,
          child: const CustomPaint(
            painter: KitchenBrowseHeroWavePainter(),
          ),
        ),
      ],
    );
  }
}
