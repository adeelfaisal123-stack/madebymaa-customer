import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;
}

class PlaceLocation {
  const PlaceLocation({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
}

/// Google Places Autocomplete + Details (legacy REST API).
class PlacesAutocompleteService {
  PlacesAutocompleteService({required this.apiKey});

  final String apiKey;

  Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    final query = input.trim();
    if (query.length < 2 || apiKey.isEmpty) return [];

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': query,
      'key': apiKey,
      'types': 'geocode',
      'components': 'country:in',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return [];
    if (decoded['status'] != 'OK' && decoded['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final predictions = decoded['predictions'];
    if (predictions is! List) return [];

    return [
      for (final item in predictions)
        if (item is Map<String, dynamic>)
          PlaceSuggestion(
            placeId: item['place_id'] as String? ?? '',
            description: item['description'] as String? ?? '',
          ),
    ].where((s) => s.placeId.isNotEmpty && s.description.isNotEmpty).toList();
  }

  Future<PlaceLocation?> fetchPlaceDetails(String placeId) async {
    if (placeId.isEmpty || apiKey.isEmpty) return null;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'geometry,formatted_address',
      'key': apiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['status'] != 'OK') {
      return null;
    }

    final result = decoded['result'];
    if (result is! Map<String, dynamic>) return null;

    final geometry = result['geometry'];
    if (geometry is! Map<String, dynamic>) return null;
    final location = geometry['location'];
    if (location is! Map<String, dynamic>) return null;

    final lat = _toDouble(location['lat']);
    final lng = _toDouble(location['lng']);
    if (lat == null || lng == null) return null;

    return PlaceLocation(
      latitude: lat,
      longitude: lng,
      formattedAddress: result['formatted_address'] as String? ?? '',
    );
  }
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
