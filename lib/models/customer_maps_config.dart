import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomerMapsConfig {
  const CustomerMapsConfig({
    required this.apiKey,
    required this.defaultLat,
    required this.defaultLng,
    this.nearbyRadiusKm = 20,
  });

  final String apiKey;
  final double defaultLat;
  final double defaultLng;
  final double nearbyRadiusKm;

  LatLng get defaultCenter => LatLng(defaultLat, defaultLng);

  factory CustomerMapsConfig.fromJson(Map<String, dynamic> json) {
    return CustomerMapsConfig(
      apiKey: json['api_key'] as String? ?? '',
      defaultLat: _toDouble(json['default_lat']) ?? 20.5937,
      defaultLng: _toDouble(json['default_lng']) ?? 78.9629,
      nearbyRadiusKm: _toDouble(json['nearby_radius_km']) ?? 20,
    );
  }
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
