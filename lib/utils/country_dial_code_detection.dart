import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../customer_location_prefs.dart';
import '../data/country_dial_codes.dart';

/// Picks the best matching [CountryDialCode] for where the user is.
abstract final class CountryDialCodeDetection {
  static Future<CountryDialCode> detect() async {
    final fromSaved = await _fromSavedLocation();
    if (fromSaved != null) return fromSaved;

    final fromGps = await _fromDeviceLocation();
    if (fromGps != null) return fromGps;

    return _fromDeviceLocale();
  }

  static Future<CountryDialCode?> _fromSavedLocation() async {
    try {
      final saved = await CustomerLocationPrefs.load();
      if (saved == null) return null;

      final marks = await placemarkFromCoordinates(
        saved.latitude,
        saved.longitude,
      );
      return _countryFromPlacemarks(marks);
    } catch (_) {
      return null;
    }
  }

  static Future<CountryDialCode?> _fromDeviceLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      final marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      return _countryFromPlacemarks(marks);
    } catch (_) {
      return null;
    }
  }

  static CountryDialCode? _countryFromPlacemarks(List<Placemark> marks) {
    if (marks.isEmpty) return null;
    final iso = marks.first.isoCountryCode;
    if (iso == null || iso.isEmpty) return null;
    return CountryDialCodes.byIso(iso);
  }

  static CountryDialCode _fromDeviceLocale() {
    final iso = PlatformDispatcher.instance.locale.countryCode;
    if (iso == null || iso.isEmpty) return CountryDialCodes.india;
    return CountryDialCodes.byIso(iso);
  }
}
