import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/bundled_cuisines.dart';
import '../l10n/app_localizations.dart';
import '../models/customer_cuisine.dart';
import '../models/customer_featured_kitchen.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_system_ui.dart';
import '../utils/customer_search.dart';
import '../widgets/kitchen_browse_chrome.dart';
import '../widgets/kitchen_list_card.dart';
import '../widgets/no_nearby_kitchens_empty_state.dart';
import 'kitchen_detail_screen.dart';

/// Full list of all home kitchens on the platform.
class AllKitchensScreen extends StatefulWidget {
  const AllKitchensScreen({super.key, this.initialSearchQuery});

  final String? initialSearchQuery;

  @override
  State<AllKitchensScreen> createState() => _AllKitchensScreenState();
}

class _AllKitchensScreenState extends State<AllKitchensScreen> {
  final _api = Optica2Api();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  List<CustomerFeaturedKitchen> _kitchens = const [];
  List<CustomerCuisine> _cuisines = const [];
  var _loading = true;
  var _stickySearch = false;
  String? _error;
  var _showOpenKitchens = true;
  int? _minStarRating;
  final Set<String> _selectedCuisines = {};
  double _heroHeight = 0;

  List<CustomerCuisine> get _cuisineOptions {
    final merged = BundledCuisines.displayList(_cuisines);
    if (merged.isNotEmpty) return merged;

    final names = _kitchens
        .map((k) => k.cuisine?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [for (final name in names) CustomerCuisine(id: 0, name: name)];
  }

  List<CustomerFeaturedKitchen> get _filteredKitchens {
    var list = _kitchens
        .where((k) => kitchenMatchesQuery(k, _searchController.text))
        .toList();

    list = list
        .where((k) => _showOpenKitchens ? k.isOpen : k.isClosed)
        .toList();

    if (_selectedCuisines.isNotEmpty) {
      list = list.where((k) {
        final cuisine = k.cuisine?.trim().toLowerCase() ?? '';
        if (cuisine.isEmpty) return false;
        return _selectedCuisines.any((target) {
          final t = target.toLowerCase();
          return cuisine == t ||
              cuisine.contains(t) ||
              t.contains(cuisine);
        });
      }).toList();
    }

    if (_minStarRating != null) {
      final min = _minStarRating!;
      list = list
          .where(
            (k) => k.rating.hasReviews && k.rating.average >= min,
          )
          .toList()
        ..sort((a, b) {
          final byRating =
              b.rating.average.compareTo(a.rating.average);
          if (byRating != 0) return byRating;
          return a.name.compareTo(b.name);
        });
    }

    return list;
  }

  bool get _isFiltering =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCuisines.isNotEmpty ||
      _minStarRating != null ||
      !_showOpenKitchens;

  bool get _showFilterRow => _showBrowseFilters;

  /// Show open/closed and cuisine once kitchens are loaded.
  bool get _showBrowseFilters {
    if (_loading || _error != null) return false;
    return _kitchens.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
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
        _api.fetchCuisines(),
      ]);
      if (!mounted) return;
      setState(() {
        _kitchens = results[0] as List<CustomerFeaturedKitchen>;
        _cuisines = results[1] as List<CustomerCuisine>;
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
        _error = 'Could not load kitchens. Check your connection.';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _load(showLoading: false);

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCuisines.clear();
      _minStarRating = null;
      _showOpenKitchens = true;
    });
  }

  void _openKitchen(int kitchenId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitchenDetailScreen(kitchenId: kitchenId),
      ),
    );
  }

  Widget _buildOpenClosedToggle(AppLocalizations l10n, {bool fullWidth = false}) {
    return KitchenOpenClosedToggle(
      showOpen: _showOpenKitchens,
      openLabel: l10n.kitchenOpen,
      closedLabel: l10n.kitchenClosed,
      fullWidth: fullWidth,
      onChanged: (showOpen) => setState(() => _showOpenKitchens = showOpen),
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
                    title: l10n.allKitchensTitle,
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
                if (_showBrowseFilters)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: _buildOpenClosedToggle(l10n, fullWidth: true),
                    ),
                  ),
                if (_showFilterRow)
                  SliverToBoxAdapter(
                    child: KitchenBrowseCuisineDropdown(
                      allLabel: l10n.nearbyFilterAll,
                      cuisineLabel: l10n.nearbyFilterCuisine,
                      cuisines: _cuisineOptions,
                      selected: _selectedCuisines,
                      onChanged: (value) {
                        setState(() {
                          _selectedCuisines
                            ..clear()
                            ..addAll(value);
                        });
                      },
                      trailing: [
                        KitchenBrowseStarRatingDropdown(
                          allLabel: l10n.nearbyFilterAll,
                          ratingLabel: l10n.nearbyFilterTopRated,
                          minStars: _minStarRating,
                          onChanged: (value) {
                            setState(() => _minStarRating = value);
                          },
                        ),
                      ],
                    ),
                  ),
                SliverToBoxAdapter(child: _buildBody(l10n)),
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

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.brandPurple,
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
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
      );
    }

    if (_kitchens.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.featuredKitchensEmpty,
          textAlign: TextAlign.center,
          style: AppFonts.style(
            context,
            fontSize: 15,
            color: AppColors.deepGreen.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    if (_filteredKitchens.isEmpty) {
      if (_isFiltering) {
        return NoNearbyKitchensEmptyState(
          title: l10n.searchNoKitchens,
          clearFiltersLabel: l10n.searchClearFilters,
          onClearFilters: _clearFilters,
        );
      }

      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.featuredKitchensEmpty,
          textAlign: TextAlign.center,
          style: AppFonts.style(
            context,
            fontSize: 15,
            color: AppColors.deepGreen.withValues(alpha: 0.55),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          for (var i = 0; i < _filteredKitchens.length; i++) ...[
            if (i > 0)
              const SizedBox(height: KitchenListCard.listSeparatorHeight),
            KitchenListCard(
              kitchen: _filteredKitchens[i],
              index: i,
              animate: i < 4,
              onTap: () => _openKitchen(_filteredKitchens[i].id),
            ),
          ],
        ],
      ),
    );
  }
}
