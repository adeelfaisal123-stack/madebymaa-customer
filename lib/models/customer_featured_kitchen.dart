import 'customer_kitchen_announcement.dart';
import 'customer_review.dart';
import 'kitchen_upcoming_day.dart';

class CustomerFeaturedKitchen {
  const CustomerFeaturedKitchen({
    required this.id,
    required this.name,
    this.chefName,
    this.address,
    this.latitude,
    this.longitude,
    this.cuisine,
    this.logoUrl,
    this.coverUrl,
    this.deliveryLabel,
    this.tags = const [],
    this.isOpen = true,
    this.instantDeliveryEnabled = true,
    this.isLive = false,
    this.isVerified = false,
    this.rating = const CustomerRatingSummary.empty(),
    this.distanceKm,
    this.announcement,
    this.fssaiNumber,
    this.upcomingDays = const [],
  });

  final int id;
  final String name;

  /// Full name of the chef / kitchen owner (the seller's user name).
  final String? chefName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? cuisine;
  final String? logoUrl;
  final String? coverUrl;
  final String? deliveryLabel;
  final List<String> tags;
  final bool isOpen;

  /// When false, checkout only offers scheduled delivery slots.
  final bool instantDeliveryEnabled;

  /// Seller registration approved — kitchen is live on the platform.
  final bool isLive;

  /// Registration approved and document KYC approved.
  final bool isVerified;
  final CustomerRatingSummary rating;
  final double? distanceKm;
  final CustomerKitchenAnnouncement? announcement;
  final String? fssaiNumber;

  /// Tomorrow / day-after plans including seller pre-order discount %.
  final List<KitchenUpcomingDay> upcomingDays;

  /// Pre-order discount % for a checkout day key (`tomorrow` / `day_after`).
  double preorderDiscountPercentForDay(String? dayKey) {
    if (dayKey != 'tomorrow' && dayKey != 'day_after') return 0;
    for (final day in upcomingDays) {
      if (day.slot == dayKey && day.open) {
        return day.preorderDiscountPercent;
      }
    }
    return 0;
  }

  factory CustomerFeaturedKitchen.fromJson(Map<String, dynamic> json) {
    return CustomerFeaturedKitchen(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Kitchen',
      chefName: _parseChefName(json),
      address: json['address'] as String?,
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
      cuisine: json['cuisine'] as String?,
      logoUrl: json['logo_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      deliveryLabel: json['delivery_label'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          const [],
      isOpen: _parseBool(json['is_open'], fallback: true),
      instantDeliveryEnabled:
          _parseBool(json['instant_delivery_enabled'], fallback: true),
      isLive: json['is_live'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      rating: CustomerRatingSummary.fromJson(json['rating']),
      distanceKm: _parseCoordinate(json['distance_km']),
      announcement: _parseAnnouncement(json['announcement']),
      fssaiNumber: _parseOptionalString(json['fssai_number']),
      upcomingDays: _parseUpcomingDays(json['upcoming_kitchen_days']),
    );
  }

  bool get isClosed => !isOpen;

  bool get isCustomerVisible => isLive && isVerified;

  String get subtitle {
    final parts = <String>[];
    if (cuisine != null && cuisine!.isNotEmpty) {
      parts.add(cuisine!);
    }
    if (deliveryLabel != null && deliveryLabel!.isNotEmpty) {
      parts.add(deliveryLabel!);
    }
    return parts.isEmpty ? 'Home-style kitchen' : parts.join(' • ');
  }

  /// Valid latitude/longitude pair from the kitchen profile.
  ({double latitude, double longitude})? get mapCoordinates {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    if (lat == 0 && lng == 0) return null;
    return (latitude: lat, longitude: lng);
  }

  bool get hasMapLocation {
    if (mapCoordinates != null) return true;
    final addr = address?.trim();
    return addr != null && addr.isNotEmpty;
  }
}

/// The chef/owner name may arrive under a few different keys depending on the
/// backend payload. Pick the first non-empty match.
String? _parseChefName(Map<String, dynamic> json) {
  const keys = [
    'chef_name',
    'owner_name',
    'user_name',
    'seller_name',
    'chef',
    'owner',
  ];
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

double? _parseCoordinate(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

CustomerKitchenAnnouncement? _parseAnnouncement(Object? value) {
  if (value is! Map<String, dynamic>) return null;
  final announcement = CustomerKitchenAnnouncement.fromJson(value);
  return announcement.hasContent ? announcement : null;
}

List<KitchenUpcomingDay> _parseUpcomingDays(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(KitchenUpcomingDay.fromJson)
      .where((day) => day.slot.isNotEmpty)
      .toList();
}

String? _parseOptionalString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _parseBool(Object? value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}
