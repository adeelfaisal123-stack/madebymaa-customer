import '../models/customer_maps_config.dart';
import 'optica2_api.dart';

/// Google Maps key and defaults from Optica2 admin (System settings).
abstract final class GoogleMapsConfigService {
  static CustomerMapsConfig? _cached;

  static CustomerMapsConfig get maps =>
      _cached ??
      const CustomerMapsConfig(
        apiKey: '',
        defaultLat: 20.5937,
        defaultLng: 78.9629,
        nearbyRadiusKm: 20,
      );

  static bool get isConfigured => maps.apiKey.isNotEmpty;

  /// Loads `/api/seller/maps-config` (admin panel key). Safe to call multiple times.
  static Future<CustomerMapsConfig> ensureLoaded({Optica2Api? api}) async {
    if (_cached != null && _cached!.apiKey.isNotEmpty) {
      return _cached!;
    }

    final client = api ?? Optica2Api();
    try {
      final config = await client.fetchMapsConfig();
      if (config.apiKey.isNotEmpty) {
        _cached = config;
      } else {
        _cached ??= config;
      }
      return _cached!;
    } catch (_) {
      return _cached ?? maps;
    }
  }
}
