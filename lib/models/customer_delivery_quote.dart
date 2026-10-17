class CustomerDeliveryQuote {
  const CustomerDeliveryQuote({
    required this.deliveryFee,
    required this.distanceKm,
    required this.perKm,
    required this.breakdownLabel,
  });

  final double deliveryFee;
  final double distanceKm;
  final double perKm;
  final String breakdownLabel;

  String get checkoutLabel =>
      breakdownLabel.isNotEmpty ? 'Delivery ($breakdownLabel)' : 'Delivery';

  factory CustomerDeliveryQuote.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CustomerDeliveryQuote.empty;
    }

    return CustomerDeliveryQuote(
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
      perKm: (json['per_km'] as num?)?.toDouble() ?? 0,
      breakdownLabel: json['breakdown_label'] as String? ?? '',
    );
  }

  static const empty = CustomerDeliveryQuote(
    deliveryFee: 0,
    distanceKm: 0,
    perKm: 0,
    breakdownLabel: '',
  );
}

class CustomerDeliveryConfig {
  const CustomerDeliveryConfig({
    required this.perKm,
    required this.baseKm,
    required this.baseFee,
  });

  final double perKm;
  final double baseKm;
  final double baseFee;

  factory CustomerDeliveryConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CustomerDeliveryConfig.empty;

    return CustomerDeliveryConfig(
      perKm: (json['per_km'] as num?)?.toDouble() ?? 0,
      baseKm: (json['base_km'] as num?)?.toDouble() ?? 0,
      baseFee: (json['base_fee'] as num?)?.toDouble() ?? 0,
    );
  }

  static const empty = CustomerDeliveryConfig(
    perKm: 0,
    baseKm: 0,
    baseFee: 0,
  );
}
