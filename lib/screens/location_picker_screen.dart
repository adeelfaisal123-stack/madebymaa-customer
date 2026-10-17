import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/optica2_config.dart';
import '../customer_location_prefs.dart';
import '../models/customer_delivery_location.dart';
import '../models/customer_maps_config.dart';
import '../services/google_maps_config_service.dart';
import '../services/optica2_api.dart';
import '../services/places_autocomplete_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_navigation.dart';
import '../utils/app_system_ui.dart';
import '../widgets/app_toast.dart';
import '../widgets/customer_location_map_webview.dart';

/// Full-screen map: search address, use GPS, confirm and save location.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.customerId,
    this.editLocation,
    this.popOnSave = false,
  });

  /// When set, saves into the signed-in customer's address list.
  final int? customerId;

  /// Edit an existing saved address.
  final CustomerDeliveryLocation? editLocation;

  /// Pop with `true` instead of navigating to home (manage-address flow).
  final bool popOnSave;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _searchController = TextEditingController();
  final _labelController = TextEditingController();
  final _searchFocus = FocusNode();
  final _mapController = CustomerLocationMapController();

  CustomerMapsConfig _maps = GoogleMapsConfigService.maps;
  PlacesAutocompleteService? _places;

  LatLng? _selected;
  String _addressLabel = '';
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  String? _error;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _bootstrap() async {
    final api = Optica2Api();
    try {
      _maps = await GoogleMapsConfigService.ensureLoaded(api: api);
      if (_maps.apiKey.isNotEmpty) {
        _places = PlacesAutocompleteService(apiKey: _maps.apiKey);
      } else {
        _error = 'Maps API key is empty. Set it in Optica2 admin System settings.';
      }

      final edit = widget.editLocation;
      if (edit != null) {
        _selected = LatLng(edit.latitude, edit.longitude);
        _addressLabel = edit.address;
        _searchController.text = edit.address;
        _labelController.text = edit.label;
      } else {
        final saved = await CustomerLocationPrefs.load();
        if (saved != null) {
          _selected = LatLng(saved.latitude, saved.longitude);
          _addressLabel = saved.address;
          _searchController.text = saved.address;
          if (saved.label.isNotEmpty) {
            _labelController.text = saved.label;
          }
        } else {
          await _useCurrentLocation(silent: true);
          _selected ??= _maps.defaultCenter;
        }
      }
    } on Optica2ApiException catch (e) {
      _error = e.message;
      _selected = _maps.defaultCenter;
    } catch (e) {
      _error = 'Could not load map settings.';
      _selected = _maps.defaultCenter;
    } finally {
      api.close();
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      final query = _searchController.text;
      if (_places == null || query.trim().length < 2) {
        if (mounted) setState(() => _suggestions = []);
        return;
      }
      try {
        final list = await _places!.fetchSuggestions(query);
        if (mounted) setState(() => _suggestions = list);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      }
    });
  }

  Future<void> _moveTo(LatLng target, {String? address, bool animate = true}) async {
    setState(() {
      _selected = target;
      if (address != null && address.isNotEmpty) {
        _addressLabel = address;
        if (_searchController.text != address) {
          _searchController.text = address;
        }
      }
      _suggestions = [];
    });
    _searchFocus.unfocus();
    await _mapController.moveTo(target, animate: animate);
  }

  void _onMapCenterChanged(LatLng point) {
    setState(() => _selected = point);
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 450), () {
      _reverseGeocode(point);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final marks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (marks.isEmpty) return;
      final p = marks.first;
      final parts = [
        if (p.street != null && p.street!.isNotEmpty) p.street,
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea,
      ].whereType<String>().toList();
      final label = parts.isEmpty
          ? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'
          : parts.join(', ');
      if (mounted) {
        setState(() {
          _addressLabel = label;
          _searchController.text = label;
        });
      }
    } catch (_) {
      final fallback =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      if (mounted) {
        setState(() {
          _addressLabel = fallback;
          _searchController.text = fallback;
        });
      }
    }
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    if (_places == null) return;
    setState(() => _loading = true);
    try {
      final details = await _places!.fetchPlaceDetails(suggestion.placeId);
      if (details != null) {
        await _moveTo(
          LatLng(details.latitude, details.longitude),
          address: details.formattedAddress,
        );
      } else {
        _searchController.text = suggestion.description;
        setState(() => _addressLabel = suggestion.description);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _useCurrentLocation({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _locating = true;
        _error = null;
      });
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!silent && mounted) {
          const msg = 'Turn on location services to use GPS.';
          setState(() => _error = msg);
          AppToast.warning(context, msg);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          const msg = 'Location permission is required.';
          setState(() => _error = msg);
          AppToast.warning(context, msg);
        }
        return;
      }

      var position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final target = LatLng(position.latitude, position.longitude);
      await _moveTo(target, animate: !silent);
      await _reverseGeocode(target);
    } catch (e) {
      if (!silent && mounted) {
        const msg = 'Could not get current location.';
        setState(() => _error = msg);
        AppToast.error(context, msg);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _confirm() async {
    final point = _selected;
    if (point == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      var address = _addressLabel.trim();
      if (address.isEmpty) {
        address = _searchController.text.trim();
      }
      if (address.isEmpty) {
        await _reverseGeocode(point);
        address = _addressLabel;
      }

      if (address.isEmpty) {
        address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      }
      final label = _labelController.text.trim();
      final customerId = widget.customerId;
      final edit = widget.editLocation;

      if (customerId != null) {
        if (edit != null) {
          await CustomerLocationPrefs.updateForCustomer(
            customerId: customerId,
            locationId: edit.id,
            label: label.isNotEmpty ? label : edit.label,
            latitude: point.latitude,
            longitude: point.longitude,
            address: address,
          );
        } else {
          await CustomerLocationPrefs.addForCustomer(
            customerId: customerId,
            label: label,
            latitude: point.latitude,
            longitude: point.longitude,
            address: address,
          );
        }
      } else {
        await CustomerLocationPrefs.save(
          latitude: point.latitude,
          longitude: point.longitude,
          address: address,
          label: label,
        );
      }

      if (!mounted) return;
      if (widget.popOnSave) {
        AppToast.success(
          context,
          edit != null ? 'Address updated' : 'Delivery address saved',
        );
        Navigator.of(context).pop(true);
        return;
      }
      await AppNavigation.afterLocationSaved(context);
    } catch (_) {
      if (mounted) {
        const msg = 'Could not save location. Try again.';
        setState(() => _error = msg);
        AppToast.error(context, msg);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _geocodeDebounce?.cancel();
    _searchController.dispose();
    _labelController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = AppSystemUi.topInset(context, 12);
    final bottom = AppSystemUi.bottomInset(context, 16);
    final mapsReady = _maps.apiKey.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        body: Stack(
          children: [
            if (_loading)
              const ColoredBox(
                color: AppColors.cream,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!mapsReady)
              ColoredBox(
                color: AppColors.cream,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error ??
                          'Google Maps is not configured.\n'
                          '${Optica2Config.unreachableMessage()}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.exo2(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.deepGreen,
                      ),
                    ),
                  ),
                ),
              )
            else
              CustomerLocationMapWebView(
                apiKey: _maps.apiKey,
                initialCenter: _selected ?? _maps.defaultCenter,
                controller: _mapController,
                onCenterChanged: _onMapCenterChanged,
              ),
            Positioned(
              top: top,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.popOnSave)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppColors.deepGreen,
                          ),
                        ),
                      ),
                    ),
                  if (widget.customerId != null) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 20,
                            color: Colors.black.withValues(alpha: 0.12),
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _labelController,
                        style: GoogleFonts.exo2(fontWeight: FontWeight.w500),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Label (Home, Work, …)',
                          hintStyle: GoogleFonts.exo2(
                            color: AppColors.deepGreen.withValues(alpha: 0.45),
                          ),
                          prefixIcon: const Icon(Icons.label_outline_rounded),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: GoogleFonts.exo2(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search area, street, landmark…',
                        hintStyle: GoogleFonts.exo2(
                          color: AppColors.deepGreen.withValues(alpha: 0.45),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _suggestions = []);
                                },
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.place_outlined,
                              color: AppColors.brandPurple.withValues(alpha: 0.8),
                            ),
                            title: Text(
                              s.description,
                              style: GoogleFonts.exo2(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _onSuggestionTap(s),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (!_loading && mapsReady)
              Positioned(
                right: 16,
                bottom: bottom + 100,
                child: FloatingActionButton.extended(
                  heroTag: 'gps',
                  onPressed: _locating ? null : () => _useCurrentLocation(),
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brandPurple,
                  icon: _locating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                    'Current location',
                    style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.exo2(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: _saving || _selected == null || !mapsReady
                        ? null
                        : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.editLocation != null
                                ? 'Save address'
                                : widget.popOnSave
                                    ? 'Add address'
                                    : 'Confirm location',
                            style: GoogleFonts.exo2(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
