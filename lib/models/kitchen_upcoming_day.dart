/// Seller-planned kitchen day for tomorrow / day after (customer checkout).
class KitchenUpcomingDay {
  const KitchenUpcomingDay({
    required this.slot,
    required this.date,
    required this.open,
    this.preorderDiscountPercent = 0,
    this.label,
    this.meals = const [],
  });

  /// `tomorrow` or `day_after`.
  final String slot;
  final String date;
  final String? label;
  final bool open;
  final List<String> meals;
  final double preorderDiscountPercent;

  factory KitchenUpcomingDay.fromJson(Map<String, dynamic> json) {
    return KitchenUpcomingDay(
      slot: json['slot'] as String? ?? '',
      date: json['date'] as String? ?? '',
      label: json['label'] as String?,
      open: json['open'] == true,
      meals: (json['meals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((m) => m.isNotEmpty)
              .toList() ??
          const [],
      preorderDiscountPercent: _parseDiscount(json['preorder_discount_percent']),
    );
  }

  static double _parseDiscount(Object? raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble().clamp(0.0, 100.0).toDouble();
    final parsed = double.tryParse(raw.toString());
    if (parsed == null) return 0;
    return parsed.clamp(0.0, 100.0).toDouble();
  }
}
