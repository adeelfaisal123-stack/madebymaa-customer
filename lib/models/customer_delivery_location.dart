/// A saved delivery address for a signed-in customer.
class CustomerDeliveryLocation {
  const CustomerDeliveryLocation({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String address;

  String get displayLabel =>
      label.trim().isNotEmpty ? label.trim() : 'Delivery address';

  CustomerDeliveryLocation copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return CustomerDeliveryLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  factory CustomerDeliveryLocation.fromJson(Map<String, dynamic> json) {
    return CustomerDeliveryLocation(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
    );
  }
}
