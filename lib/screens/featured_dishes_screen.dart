import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_dish_category.dart';
import '../models/customer_featured_dish.dart';
import '../models/dish_detail_entry.dart';
import '../models/customer_super_category.dart';
import '../models/customer_dish_subcategory.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_system_ui.dart';
import '../utils/customer_search.dart';
import '../widgets/customer_dish_card.dart';
import '../widgets/dish_subcategories_row.dart';
import '../widgets/dish_veg_filter_toggle.dart';
import '../widgets/kitchen_browse_chrome.dart';
import '../widgets/no_dishes_empty_state.dart';
import '../widgets/super_categories_row.dart';
import '../utils/dish_detail_route.dart';
import 'dish_detail_screen.dart';

/// Browse all dishes from every kitchen, filterable by super category.
class FeaturedDishesScreen extends StatefulWidget {
  const FeaturedDishesScreen({
    super.key,
    this.initialSuperCategoryId,
    this.initialSearchQuery,
    this.initialCuisineId,
    this.cuisineName,
    this.initialDishCategoryId,
    this.dishCategoryName,
    this.dishSubcategories,
  });

  final int? initialSuperCategoryId;
  final String? initialSearchQuery;

  /// When set, only dishes from kitchens with this cuisine are shown.
  final int? initialCuisineId;
  final String? cuisineName;

  /// When set, only dishes in this menu category (Biryani, etc.) are shown.
  final int? initialDishCategoryId;
  final String? dishCategoryName;
  final List<CustomerDishSubcategory>? dishSubcategories;

  @override
  State<FeaturedDishesScreen> createState() => _FeaturedDishesScreenState();
}

class _FeaturedDishesScreenState extends State<FeaturedDishesScreen> {
  final _api = Optica2Api();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<CustomerSuperCategory> _superCategories = const [];
  List<CustomerDishSubcategory> _subcategories = const [];
  List<CustomerFeaturedDish> _allDishesToday = const [];
  var _categoriesLoading = true;
  var _subcategoriesLoading = false;
  var _dishesLoading = true;
  var _stickySearch = false;
  String? _error;
  int? _selectedSuperCategoryId;
  int? _selectedSubcategoryId;
  DishVegFilter _vegFilter = DishVegFilter.all;
  double _heroHeight = 0;

  List<CustomerSuperCategory> get _visibleSuperCategories {
    if (_allDishesToday.isEmpty) return _superCategories;
    final ids = _allDishesToday.expand((d) => d.superCategoryIds).toSet();
    return _superCategories.where((c) => ids.contains(c.id)).toList();
  }

  List<CustomerDishSubcategory> get _visibleSubcategories {
    if (_subcategories.isEmpty) return const [];
    if (_allDishesToday.isEmpty) return _subcategories;
    final ids = _allDishesToday
        .map((d) => d.dishSubcategoryId)
        .whereType<int>()
        .toSet();
    if (ids.isEmpty) return _subcategories;
    return _subcategories.where((s) => ids.contains(s.id)).toList();
  }

  int? get _cuisineId =>
      widget.initialCuisineId != null && widget.initialCuisineId! > 0
      ? widget.initialCuisineId
      : null;

  String? get _cuisineName {
    final name = widget.cuisineName?.trim();
    return name != null && name.isNotEmpty ? name : null;
  }

  bool get _isCuisineBrowse => _cuisineId != null || _cuisineName != null;

  int? get _dishCategoryId =>
      widget.initialDishCategoryId != null && widget.initialDishCategoryId! > 0
      ? widget.initialDishCategoryId
      : null;

  String? get _dishCategoryName {
    final name = widget.dishCategoryName?.trim();
    return name != null && name.isNotEmpty ? name : null;
  }

  bool get _isDishCategoryBrowse => _dishCategoryId != null;

  /// Meal chip applies when not searching; search scans all of today's dishes.
  int? get _effectiveCategoryId =>
      _isSearching ? null : _selectedSuperCategoryId;

  int? get _effectiveSubcategoryId =>
      _isSearching ? null : _selectedSubcategoryId;

  List<CustomerFeaturedDish> get _filteredDishes => _allDishesToday
      .where((d) => d.matchesSuperCategory(_effectiveCategoryId))
      .where((d) => d.matchesSubcategory(_effectiveSubcategoryId))
      .where((d) => _vegFilter.matchesDish(isVeg: d.isVeg))
      .where((d) => dishMatchesQuery(d, _searchController.text))
      .toList();

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedSuperCategoryId = widget.initialSuperCategoryId;
    final initial = widget.initialSearchQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _searchController.text = initial;
    }
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

  Future<void> _refresh() => _load(showLoading: false);

  Future<void> _load({bool showLoading = true}) async {
    final needsSubcategories =
        _isDishCategoryBrowse &&
        (widget.dishSubcategories == null || widget.dishSubcategories!.isEmpty);

    setState(() {
      if (showLoading) {
        _categoriesLoading = true;
        _subcategoriesLoading = needsSubcategories;
        _dishesLoading = true;
      }
      _error = null;
    });
    try {
      final results = await Future.wait([
        if (!_isDishCategoryBrowse)
          _api.fetchSuperCategories()
        else
          Future.value(const []),
        _api.fetchBrowseDishes(
          cuisineId: _cuisineId,
          dishCategoryId: _dishCategoryId,
        ),
        if (needsSubcategories)
          _api.fetchDishCategories()
        else
          Future.value(const []),
      ]);
      if (!mounted) return;
      var dishes = results[1] as List<CustomerFeaturedDish>;
      if (_cuisineId == null && _cuisineName != null) {
        dishes = dishes
            .where((d) => dishMatchesCuisineName(d, _cuisineName!))
            .toList();
      }

      List<CustomerDishSubcategory> subcategories =
          widget.dishSubcategories ?? const [];
      if (_isDishCategoryBrowse && subcategories.isEmpty) {
        final categories = results[2] as List<CustomerDishCategory>;
        for (final category in categories) {
          if (category.id == _dishCategoryId) {
            subcategories = category.subcategories;
            break;
          }
        }
      }

      setState(() {
        _superCategories = _isDishCategoryBrowse
            ? const []
            : results[0] as List<CustomerSuperCategory>;
        _subcategories = subcategories;
        _allDishesToday = dishes;
        _categoriesLoading = false;
        _subcategoriesLoading = false;
        _dishesLoading = false;
        _pruneSelectedCategory();
        _pruneSelectedSubcategory();
      });
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _categoriesLoading = false;
        _subcategoriesLoading = false;
        _dishesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load dishes. Check your connection.';
        _categoriesLoading = false;
        _subcategoriesLoading = false;
        _dishesLoading = false;
      });
    }
  }

  void _pruneSelectedCategory() {
    final selected = _selectedSuperCategoryId;
    if (selected == null) return;
    final stillVisible = _visibleSuperCategories.any((c) => c.id == selected);
    if (!stillVisible) {
      _selectedSuperCategoryId = null;
    }
  }

  void _pruneSelectedSubcategory() {
    final selected = _selectedSubcategoryId;
    if (selected == null) return;
    final stillVisible = _visibleSubcategories.any((s) => s.id == selected);
    if (!stillVisible) {
      _selectedSubcategoryId = null;
    }
  }

  void _onSuperCategorySelected(int? id) {
    if (_selectedSuperCategoryId == id) return;
    setState(() => _selectedSuperCategoryId = id);
  }

  void _onSubcategorySelected(int? id) {
    if (_selectedSubcategoryId == id) return;
    setState(() => _selectedSubcategoryId = id);
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

  String get _screenTitle {
    final l10n = AppLocalizations.of(context)!;
    return _dishCategoryName ?? _cuisineName ?? l10n.allDishesTitle;
  }

  bool get _showVegFilter => !_dishesLoading && _error == null;

  Widget _buildVegFilter() {
    return DishVegFilterToggle(
      value: _vegFilter,
      onChanged: (filter) {
        if (_vegFilter == filter) return;
        setState(() => _vegFilter = filter);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    title: _screenTitle,
                    searchHint: l10n.searchKitchensDishes,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    showBackButton: true,
                    lightBackground: true,
                    onBack: () => Navigator.of(context).maybePop(),
                    trailing: _showVegFilter ? _buildVegFilter() : null,
                    onHeightResolved: (height) {
                      if (_heroHeight != height) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _heroHeight = height);
                        });
                      }
                    },
                  ),
                ),
                if (!_isDishCategoryBrowse)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SuperCategoriesRow(
                        categories: _visibleSuperCategories,
                        allLabel: l10n.categoryAll,
                        selectedId: _selectedSuperCategoryId,
                        isLoading: _categoriesLoading,
                        onSelected: _onSuperCategorySelected,
                      ),
                    ),
                  ),
                if (_isDishCategoryBrowse &&
                    (_subcategoriesLoading || _visibleSubcategories.isNotEmpty))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DishSubcategoriesRow(
                        subcategories: _visibleSubcategories,
                        allLabel: l10n.categoryAll,
                        selectedId: _selectedSubcategoryId,
                        isLoading: _subcategoriesLoading,
                        onSelected: _onSubcategorySelected,
                      ),
                    ),
                  ),
                ..._buildBodySlivers(l10n),
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

  List<Widget> _buildBodySlivers(AppLocalizations l10n) {
    if (_dishesLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandPurple,
            ),
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

    if (_allDishesToday.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: NoDishesEmptyState(
            message: _isCuisineBrowse
                ? l10n.noDishesInCuisine
                : l10n.noDishesToday,
            subtitle: l10n.noDishesEmptySubtitle,
          ),
        ),
      ];
    }

    if (_filteredDishes.isEmpty) {
      final hasActiveFilters =
          _isSearching ||
          _selectedSuperCategoryId != null ||
          _selectedSubcategoryId != null ||
          _vegFilter != DishVegFilter.all;

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: NoDishesEmptyState(
            message: _isSearching
                ? l10n.searchNoDishes
                : hasActiveFilters
                    ? l10n.noDishesInCategory
                    : l10n.noDishesToday,
            subtitle: _isSearching ? null : l10n.noDishesEmptySubtitle,
            forSearch: _isSearching,
          ),
        ),
      ];
    }

    final bottomPadding = AppSystemUi.bottomInset(context, 96);

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: CustomerDishCard.gridAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final dish = _filteredDishes[index];
              return CustomerDishCard(
                dish: CustomerDishCardModel.fromFeatured(dish),
                accent: CustomerDishCard.accentForIndex(index),
                onTap: () => _openDish(index),
              );
            },
            childCount: _filteredDishes.length,
          ),
        ),
      ),
    ];
  }
}
