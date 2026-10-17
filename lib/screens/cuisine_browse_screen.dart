import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_featured_dish.dart';
import '../models/customer_featured_kitchen.dart';
import '../models/dish_detail_entry.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_system_ui.dart';
import '../utils/customer_search.dart';
import '../utils/dish_detail_route.dart';
import '../widgets/customer_dish_card.dart';
import '../widgets/discover_section_heading.dart';
import '../widgets/kitchen_browse_chrome.dart';
import '../widgets/kitchen_list_card.dart';
import '../widgets/no_dishes_empty_state.dart';
import '../widgets/no_nearby_kitchens_empty_state.dart';
import 'dish_detail_screen.dart';
import 'kitchen_detail_screen.dart';

/// Cuisine tap destination — kitchens and dishes for one cuisine.
class CuisineBrowseScreen extends StatefulWidget {
  const CuisineBrowseScreen({
    super.key,
    required this.cuisineName,
    this.cuisineId,
  });

  final String cuisineName;
  final int? cuisineId;

  @override
  State<CuisineBrowseScreen> createState() => _CuisineBrowseScreenState();
}

class _CuisineBrowseScreenState extends State<CuisineBrowseScreen> {
  final _api = Optica2Api();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<CustomerFeaturedKitchen> _kitchens = const [];
  List<CustomerFeaturedDish> _dishes = const [];
  var _loading = true;
  var _stickySearch = false;
  String? _error;
  double _heroHeight = 0;

  int? get _cuisineId =>
      widget.cuisineId != null && widget.cuisineId! > 0
          ? widget.cuisineId
          : null;

  String get _cuisineName => widget.cuisineName.trim();

  List<CustomerFeaturedKitchen> get _filteredKitchens {
    final q = _searchController.text;
    return _kitchens
        .where((k) => kitchenMatchesCuisineName(k, _cuisineName))
        .where((k) => kitchenMatchesQuery(k, q))
        .toList();
  }

  List<CustomerFeaturedDish> get _filteredDishes {
    final q = _searchController.text;
    return _dishes.where((d) => dishMatchesQuery(d, q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_rebuildForSearch);
    _scrollController.addListener(_onScroll);
    _load();
  }

  void _rebuildForSearch() => setState(() {});

  void _onSearchChanged(String _) => _rebuildForSearch();

  void _onScroll() {
    if (_heroHeight <= 0 || !_scrollController.hasClients) return;
    final sticky = _scrollController.offset >= _heroHeight - 4;
    if (sticky != _stickySearch) {
      setState(() => _stickySearch = sticky);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_rebuildForSearch);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
      final results = await Future.wait([
        _api.fetchBrowseKitchens(),
        _api.fetchBrowseDishes(cuisineId: _cuisineId),
      ]);
      if (!mounted) return;

      var dishes = results[1] as List<CustomerFeaturedDish>;
      if (_cuisineId == null || dishes.isEmpty) {
        // Fallback / tighten by cuisine name when API id is missing or broad.
        final byName = dishes
            .where((d) => dishMatchesCuisineName(d, _cuisineName))
            .toList();
        if (byName.isNotEmpty || _cuisineId == null) {
          dishes = byName;
        }
      }

      setState(() {
        _kitchens = results[0] as List<CustomerFeaturedKitchen>;
        _dishes = dishes;
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
        _error = 'Could not load this cuisine. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _load(showLoading: false);

  void _openKitchen(int kitchenId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitchenDetailScreen(kitchenId: kitchenId),
      ),
    );
  }

  void _openDish(int index) {
    final dishes = _filteredDishes;
    final entries = [
      for (var i = 0; i < dishes.length; i++)
        DishDetailEntry.fromFeaturedDish(dishes[i], i),
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
    final l10n = AppLocalizations.of(context)!;
    final kitchens = _filteredKitchens;
    final dishes = _filteredDishes;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            RefreshIndicator(
              color: AppColors.brandPurple,
              onRefresh: _refresh,
              edgeOffset: AppSystemUi.topInset(context, 8) + 80,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: KitchenBrowseHero(
                      title: _cuisineName,
                      searchHint: l10n.searchKitchensDishes,
                      searchController: _searchController,
                      onSearchChanged: _onSearchChanged,
                      showBackButton: true,
                      lightBackground: true,
                      onBack: () => Navigator.of(context).maybePop(),
                      onHeightResolved: (height) {
                        if (_heroHeight != height) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _heroHeight = height);
                          });
                        }
                      },
                    ),
                  ),
                  ..._buildBodySlivers(l10n, kitchens, dishes),
                ],
              ),
            ),
            if (_stickySearch)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: KitchenBrowseStickyBar(
                  topInset: AppSystemUi.topInset(context, 8),
                  showBackButton: true,
                  lightBackground: true,
                  onBack: () => Navigator.of(context).maybePop(),
                  searchController: _searchController,
                  searchHint: l10n.searchKitchensDishes,
                  onSearchChanged: _onSearchChanged,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBodySlivers(
    AppLocalizations l10n,
    List<CustomerFeaturedKitchen> kitchens,
    List<CustomerFeaturedDish> dishes,
  ) {
    if (_loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.brandPurple),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppFonts.style(
                      context,
                      color: AppColors.deepGreen.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _load,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPurple,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    final searching = _searchController.text.trim().isNotEmpty;
    final noResults = kitchens.isEmpty && dishes.isEmpty;

    if (noResults) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: searching
              ? NoNearbyKitchensEmptyState(
                  title: l10n.searchNoKitchens,
                  clearFiltersLabel: l10n.searchClearFilters,
                  onClearFilters: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : NoDishesEmptyState(
                  message: l10n.noDishesInCuisine,
                  subtitle: l10n.noDishesEmptySubtitle,
                ),
        ),
      ];
    }

    final bottomPad = AppSystemUi.bottomInset(context, 32);
    final slivers = <Widget>[];

    // —— Kitchens ——
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: DiscoverSectionHeading(
            title: l10n.allKitchensTitle,
            accent: AppColors.brandPurple,
            trailing: kitchens.isEmpty
                ? null
                : Text(
                    '${kitchens.length}',
                    style: AppFonts.style(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ),
          ),
        ),
      ),
    );

    if (kitchens.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'No kitchens for this cuisine yet.',
              style: AppFonts.style(
                context,
                fontSize: 14,
                color: AppColors.deepGreen.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    } else {
      slivers.add(
        SliverToBoxAdapter(
          child: _CuisineKitchensSlider(
            kitchens: kitchens,
            onKitchenTap: _openKitchen,
          ),
        ),
      );
    }

    // —— Dishes ——
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: DiscoverSectionHeading(
            title: l10n.allDishesTitle,
            accent: AppColors.terracotta,
            trailing: dishes.isEmpty
                ? null
                : Text(
                    '${dishes.length}',
                    style: AppFonts.style(
                      context,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ),
          ),
        ),
      ),
    );

    if (dishes.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
            child: Text(
              l10n.noDishesInCuisine,
              style: AppFonts.style(
                context,
                fontSize: 14,
                color: AppColors.deepGreen.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      );
    } else {
      slivers.add(
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: CustomerDishCard.gridAspectRatio,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => CustomerDishCard(
                dish: CustomerDishCardModel.fromFeatured(dishes[i]),
                accent: CustomerDishCard.accentForIndex(i),
                onTap: () => _openDish(i),
              ),
              childCount: dishes.length,
            ),
          ),
        ),
      );
    }

    return slivers;
  }
}

/// One kitchen per page with a little peek of neighbours left/right.
class _CuisineKitchensSlider extends StatefulWidget {
  const _CuisineKitchensSlider({
    required this.kitchens,
    required this.onKitchenTap,
  });

  final List<CustomerFeaturedKitchen> kitchens;
  final ValueChanged<int> onKitchenTap;

  @override
  State<_CuisineKitchensSlider> createState() => _CuisineKitchensSliderState();
}

class _CuisineKitchensSliderState extends State<_CuisineKitchensSlider> {
  /// Tall enough for KitchenListCard (110) + cover overflow (124).
  static const _sliderHeight = 136.0;
  static const _viewportFraction = 0.88;

  late final PageController _pageController;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: _viewportFraction);
  }

  @override
  void didUpdateWidget(covariant _CuisineKitchensSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kitchens.length != widget.kitchens.length ||
        (oldWidget.kitchens.isNotEmpty &&
            widget.kitchens.isNotEmpty &&
            oldWidget.kitchens.first.id != widget.kitchens.first.id)) {
      _page = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kitchens = widget.kitchens;

    return Column(
      children: [
        SizedBox(
          height: _sliderHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: kitchens.length,
            padEnds: true,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Align(
                  alignment: Alignment.center,
                  child: KitchenListCard(
                    kitchen: kitchens[index],
                    index: index,
                    animate: false,
                    onTap: () => widget.onKitchenTap(kitchens[index].id),
                  ),
                ),
              );
            },
          ),
        ),
        if (kitchens.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(kitchens.length, (i) {
              final active = _page == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.brandPurple
                      : AppColors.brandPurple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

