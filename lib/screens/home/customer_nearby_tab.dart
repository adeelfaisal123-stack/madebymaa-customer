import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/bundled_cuisines.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer_cuisine.dart';
import '../../models/customer_featured_kitchen.dart';
import '../../services/google_maps_config_service.dart';
import '../../services/optica2_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../utils/app_system_ui.dart';
import '../../utils/customer_search.dart';
import '../../widgets/floating_food_icons.dart';
import '../../widgets/kitchen_browse_chrome.dart';
import '../../widgets/kitchen_list_card.dart';
import '../../widgets/no_nearby_kitchens_empty_state.dart';
import '../kitchen_detail_screen.dart';

class _NearbyKitchenEntry {
  const _NearbyKitchenEntry({
    required this.kitchen,
    this.distanceKm,
  });

  final CustomerFeaturedKitchen kitchen;
  final double? distanceKm;
}

/// Nearby tab — kitchens within admin radius, sorted by distance.
class CustomerNearbyTab extends StatefulWidget {
  const CustomerNearbyTab({super.key});

  @override
  State<CustomerNearbyTab> createState() => _CustomerNearbyTabState();
}

class _CustomerNearbyTabState extends State<CustomerNearbyTab>
    with AutomaticKeepAliveClientMixin {
  final _api = Optica2Api();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  List<CustomerFeaturedKitchen> _kitchens = const [];
  List<CustomerCuisine> _cuisines = const [];
  double? _userLat;
  double? _userLng;
  var _loading = true;
  var _locating = false;
  var _stickySearch = false;
  String? _error;
  String? _locationError;
  double _nearbyRadiusKm = 20;
  int? _minStarRating;
  final Set<String> _selectedCuisines = {};
  var _showOpenKitchens = true;
  double _heroHeight = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _api.close();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _onScroll() {
    if (_heroHeight <= 0 || !_scrollController.hasClients) return;
    final sticky = _scrollController.offset >= _heroHeight - 4;
    if (sticky != _stickySearch) {
      setState(() => _stickySearch = sticky);
    }
  }

  String get _radiusLabel =>
      _nearbyRadiusKm.truncateToDouble() == _nearbyRadiusKm
          ? _nearbyRadiusKm.toStringAsFixed(0)
          : _nearbyRadiusKm.toStringAsFixed(1);

  bool get _hasLocation => _userLat != null && _userLng != null;

  List<CustomerCuisine> get _cuisineOptions {
    final merged = BundledCuisines.displayList(_cuisines);
    if (merged.isNotEmpty) return merged;

    final names = _entries
        .map((e) => e.kitchen.cuisine?.trim())
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return [for (final name in names) CustomerCuisine(id: 0, name: name)];
  }

  bool get _showFilterRow => _showBrowseFilters;

  /// Show open/closed and cuisine once location and kitchens are ready.
  bool get _showBrowseFilters {
    if (_loading || _locating || !_hasLocation) return false;
    return _entries.isNotEmpty;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
      _locationError = null;
    });

    try {
      final maps = await GoogleMapsConfigService.ensureLoaded(api: _api);
      _nearbyRadiusKm = maps.nearbyRadiusKm;

      await _useCurrentLocation();
      await _loadKitchens();
      if (!mounted) return;

      setState(() => _loading = false);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load nearby kitchens.';
      });
    }
  }

  Future<void> _loadKitchens() async {
    final results = await Future.wait([
      _api.fetchBrowseKitchens(
        latitude: _userLat,
        longitude: _userLng,
      ),
      _api.fetchCuisines(),
    ]);
    if (!mounted) return;
    setState(() {
      _kitchens = results[0] as List<CustomerFeaturedKitchen>;
      _cuisines = results[1] as List<CustomerCuisine>;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _locationError = null;
    });
    await _useCurrentLocation();
    await _loadKitchens();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Turn on location services to see kitchens near you.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationError =
              'Allow location access to see kitchens near you.';
        });
        return;
      }

      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 12),
            ),
          );

      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _locationError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not get your current location.';
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  List<_NearbyKitchenEntry> get _entries {
    if (!_hasLocation) return const [];

    final entries = _kitchens.map((kitchen) {
      final coords = kitchen.mapCoordinates;
      var distanceKm = kitchen.distanceKm;
      if (distanceKm == null && coords != null) {
        final meters = Geolocator.distanceBetween(
          _userLat!,
          _userLng!,
          coords.latitude,
          coords.longitude,
        );
        distanceKm = meters / 1000;
      }
      return _NearbyKitchenEntry(
        kitchen: kitchen,
        distanceKm: distanceKm,
      );
    }).toList();

    entries.sort((a, b) {
      final da = a.distanceKm;
      final db = b.distanceKm;
      if (da == null && db == null) {
        return a.kitchen.name.compareTo(b.kitchen.name);
      }
      if (da == null) return 1;
      if (db == null) return -1;
      final cmp = da.compareTo(db);
      return cmp != 0 ? cmp : a.kitchen.name.compareTo(b.kitchen.name);
    });
    return entries;
  }

  List<_NearbyKitchenEntry> get _filteredEntries {
    var list = _entries
        .where((e) => kitchenMatchesQuery(e.kitchen, _searchController.text))
        .toList();

    list = list
        .where((e) => _showOpenKitchens ? e.kitchen.isOpen : e.kitchen.isClosed)
        .toList();

    if (_selectedCuisines.isNotEmpty) {
      list = list.where((e) {
        final cuisine = e.kitchen.cuisine?.trim().toLowerCase() ?? '';
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
            (e) =>
                e.kitchen.rating.hasReviews &&
                e.kitchen.rating.average >= min,
          )
          .toList()
        ..sort((a, b) {
          final byRating = b.kitchen.rating.average
              .compareTo(a.kitchen.rating.average);
          if (byRating != 0) return byRating;
          final da = a.distanceKm;
          final db = b.distanceKm;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
    }

    return list;
  }

  bool get _isFiltering =>
      _searchController.text.trim().isNotEmpty ||
      _selectedCuisines.isNotEmpty ||
      _minStarRating != null ||
      !_showOpenKitchens;

  void _openKitchen(int kitchenId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitchenDetailScreen(kitchenId: kitchenId),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCuisines.clear();
      _minStarRating = null;
      _showOpenKitchens = true;
    });
  }

  Widget _buildOpenClosedToggle(AppLocalizations l10n) {
    return KitchenOpenClosedToggle(
      showOpen: _showOpenKitchens,
      openLabel: l10n.kitchenOpen,
      closedLabel: l10n.kitchenClosed,
      fullWidth: true,
      onChanged: (showOpen) => setState(() => _showOpenKitchens = showOpen),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final filtered = _filteredEntries;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: ColoredBox(
        color: AppColors.cream,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: FloatingFoodIcons(
                opacity: 0.10,
                count: 26,
                minSize: 18,
                maxSize: 34,
                seed: 41,
                entrance: false,
              ),
            ),
            RefreshIndicator(
              color: AppColors.brandPurple,
              onRefresh: _refresh,
              edgeOffset: AppSystemUi.topInset(context, 8) + 120,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: KitchenBrowseHero(
                      title: l10n.nearbyTitle,
                      searchHint: l10n.nearbySearchHint,
                      searchController: _searchController,
                      onSearchChanged: (_) => _onSearchChanged(),
                      foodIconSeed: 27,
                      lightBackground: true,
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
                        child: _buildOpenClosedToggle(l10n),
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
                  if (_loading || _locating)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.brandPurple,
                        ),
                      ),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(message: _error!, onRetry: _bootstrap),
                    )
                  else if (!_hasLocation)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _LocationUnavailable(message: _locationError),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyNearby(
                        radiusLabel: _radiusLabel,
                        filtering: _isFiltering,
                        onClearFilters: _clearFilters,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 100),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(
                          height: KitchenListCard.listSeparatorHeight,
                        ),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          return KitchenListCard(
                            kitchen: entry.kitchen,
                            index: index,
                            animate: index < 4,
                            onTap: () => _openKitchen(entry.kitchen.id),
                          );
                        },
                      ),
                    ),
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
                  lightBackground: true,
                  searchController: _searchController,
                  searchHint: l10n.nearbySearchHint,
                  onSearchChanged: (_) => _onSearchChanged(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationUnavailable extends StatelessWidget {
  const _LocationUnavailable({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.brandPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_disabled_rounded,
              size: 42,
              color: AppColors.brandPurple.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message ?? AppLocalizations.of(context)!.nearbyLocationRequired,
            textAlign: TextAlign.center,
            style: AppFonts.style(
              context,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pull down to try again.',
            textAlign: TextAlign.center,
            style: AppFonts.style(
              context,
              fontSize: 14,
              color: AppColors.deepGreen.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNearby extends StatelessWidget {
  const _EmptyNearby({
    required this.radiusLabel,
    required this.filtering,
    required this.onClearFilters,
  });

  final String radiusLabel;
  final bool filtering;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (filtering) {
      return NoNearbyKitchensEmptyState(
        title: l10n.searchNoKitchens,
        clearFiltersLabel: l10n.searchClearFilters,
        onClearFilters: onClearFilters,
      );
    }

    return NoNearbyKitchensEmptyState(
      title: l10n.nearbyMapEmpty(radiusLabel),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.brandPurple.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.style(
                context,
                fontSize: 15,
                height: 1.45,
                color: AppColors.deepGreen,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPurple,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
