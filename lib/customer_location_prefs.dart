import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/customer_delivery_location.dart';

/// Saved delivery / browse location for the customer app.
abstract final class CustomerLocationPrefs {
  static const savedKey = 'customer_location_saved';
  static const latKey = 'customer_location_lat';
  static const lngKey = 'customer_location_lng';
  static const addressKey = 'customer_location_address';
  static const labelKey = 'customer_location_label';
  static const activeIdKey = 'customer_location_active_id';

  static String _locationsKey(int customerId) =>
      'customer_${customerId}_delivery_locations';

  static Future<bool> hasSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(savedKey) ?? false) return true;

      final activeId = prefs.getString(activeIdKey);
      if (activeId != null && activeId.isNotEmpty) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Active delivery location (guest legacy or signed-in selection).
  static Future<CustomerSavedLocation?> load() => loadActive();

  static Future<CustomerSavedLocation?> loadActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString(activeIdKey);
      if (activeId != null && activeId.isNotEmpty) {
        final customerId = prefs.getInt('customer_session_id');
        if (customerId != null) {
          final locations = _readLocations(prefs, customerId);
          for (final loc in locations) {
            if (loc.id == activeId) {
              return CustomerSavedLocation.fromDelivery(loc);
            }
          }
        }
      }

      if (!(prefs.getBool(savedKey) ?? false)) return null;
      final lat = prefs.getDouble(latKey);
      final lng = prefs.getDouble(lngKey);
      final address = prefs.getString(addressKey);
      if (lat == null || lng == null) return null;
      return CustomerSavedLocation(
        id: activeId,
        label: prefs.getString(labelKey) ?? '',
        latitude: lat,
        longitude: lng,
        address: address ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves the active location (guest onboarding or quick update).
  static Future<void> save({
    required double latitude,
    required double longitude,
    required String address,
    String label = '',
    String? id,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeLegacyActive(
      prefs,
      latitude: latitude,
      longitude: longitude,
      address: address,
      label: label,
      id: id,
    );
  }

  static Future<List<CustomerDeliveryLocation>> listForCustomer(
    int customerId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _readLocations(prefs, customerId);
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> activeLocationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(activeIdKey);
    } catch (_) {
      return null;
    }
  }

  static Future<CustomerDeliveryLocation> addForCustomer({
    required int customerId,
    required String label,
    required double latitude,
    required double longitude,
    required String address,
    bool setActive = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = _readLocations(prefs, customerId);
    final loc = CustomerDeliveryLocation(
      id: _newId(),
      label: label.trim().isEmpty ? _defaultLabel(locations.length) : label.trim(),
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    locations.add(loc);
    await _writeLocations(prefs, customerId, locations);

    if (setActive) {
      await setActiveForCustomer(customerId, loc.id);
    }

    return loc;
  }

  static Future<CustomerDeliveryLocation?> updateForCustomer({
    required int customerId,
    required String locationId,
    String? label,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = _readLocations(prefs, customerId);
    final index = locations.indexWhere((l) => l.id == locationId);
    if (index < 0) return null;

    final current = locations[index];
    final updated = current.copyWith(
      label: label,
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
    locations[index] = updated;
    await _writeLocations(prefs, customerId, locations);

    final activeId = prefs.getString(activeIdKey);
    if (activeId == locationId) {
      await _writeLegacyActive(
        prefs,
        latitude: updated.latitude,
        longitude: updated.longitude,
        address: updated.address,
        label: updated.label,
        id: updated.id,
      );
    }

    return updated;
  }

  static Future<bool> deleteForCustomer({
    required int customerId,
    required String locationId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = _readLocations(prefs, customerId);
    if (locations.length <= 1) return false;

    final removed = locations.where((l) => l.id == locationId).toList();
    if (removed.isEmpty) return false;

    locations.removeWhere((l) => l.id == locationId);
    await _writeLocations(prefs, customerId, locations);

    final activeId = prefs.getString(activeIdKey);
    if (activeId == locationId) {
      await setActiveForCustomer(customerId, locations.first.id);
    }

    return true;
  }

  static Future<void> setActiveForCustomer(int customerId, String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final locations = _readLocations(prefs, customerId);
    CustomerDeliveryLocation? selected;
    for (final loc in locations) {
      if (loc.id == locationId) {
        selected = loc;
        break;
      }
    }
    if (selected == null) return;

    await prefs.setString(activeIdKey, locationId);
    await _writeLegacyActive(
      prefs,
      latitude: selected.latitude,
      longitude: selected.longitude,
      address: selected.address,
      label: selected.label,
      id: selected.id,
    );
  }

  /// Move guest onboarding location into the signed-in customer's saved list.
  static Future<void> migrateLegacyToCustomer(int customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _readLocations(prefs, customerId);
    if (existing.isNotEmpty) {
      final activeId = prefs.getString(activeIdKey);
      if (activeId == null || activeId.isEmpty) {
        await setActiveForCustomer(customerId, existing.first.id);
      }
      return;
    }

    final legacy = await loadActive();
    if (legacy == null) return;

    await addForCustomer(
      customerId: customerId,
      label: legacy.label.isNotEmpty ? legacy.label : 'Home',
      latitude: legacy.latitude,
      longitude: legacy.longitude,
      address: legacy.address,
      setActive: true,
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(savedKey);
    await prefs.remove(latKey);
    await prefs.remove(lngKey);
    await prefs.remove(addressKey);
    await prefs.remove(labelKey);
    await prefs.remove(activeIdKey);
  }

  static List<CustomerDeliveryLocation> _readLocations(
    SharedPreferences prefs,
    int customerId,
  ) {
    final raw = prefs.getString(_locationsKey(customerId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => CustomerDeliveryLocation.fromJson(Map<String, dynamic>.from(e)))
          .where((l) => l.id.isNotEmpty && l.address.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeLocations(
    SharedPreferences prefs,
    int customerId,
    List<CustomerDeliveryLocation> locations,
  ) async {
    final encoded = jsonEncode(locations.map((l) => l.toJson()).toList());
    await prefs.setString(_locationsKey(customerId), encoded);
  }

  static Future<void> _writeLegacyActive(
    SharedPreferences prefs, {
    required double latitude,
    required double longitude,
    required String address,
    required String label,
    String? id,
  }) async {
    await prefs.setBool(savedKey, true);
    await prefs.setDouble(latKey, latitude);
    await prefs.setDouble(lngKey, longitude);
    await prefs.setString(addressKey, address);
    await prefs.setString(labelKey, label);
    if (id != null && id.isNotEmpty) {
      await prefs.setString(activeIdKey, id);
    }
  }

  static String _newId() => 'loc_${DateTime.now().microsecondsSinceEpoch}';

  static String _defaultLabel(int existingCount) {
    return switch (existingCount) {
      0 => 'Home',
      1 => 'Work',
      _ => 'Address ${existingCount + 1}',
    };
  }
}

class CustomerSavedLocation {
  const CustomerSavedLocation({
    this.id,
    this.label = '',
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final String? id;
  final String label;
  final double latitude;
  final double longitude;
  final String address;

  String get displayLabel =>
      label.trim().isNotEmpty ? label.trim() : 'Delivery address';

  factory CustomerSavedLocation.fromDelivery(CustomerDeliveryLocation loc) {
    return CustomerSavedLocation(
      id: loc.id,
      label: loc.label,
      latitude: loc.latitude,
      longitude: loc.longitude,
      address: loc.address,
    );
  }
}
