import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'customer_dish.dart';
import 'customer_featured_dish.dart';

/// One dish plus its kitchen context for the detail screen pager.
class DishDetailEntry {
  const DishDetailEntry({
    required this.dish,
    required this.kitchenId,
    required this.kitchenName,
    this.kitchenLogoUrl,
    this.chefName,
    this.kitchenInstantDeliveryEnabled,
    this.accentColor,
  });

  final CustomerDish dish;
  final int kitchenId;
  final String kitchenName;
  final String? kitchenLogoUrl;
  final String? chefName;
  final bool? kitchenInstantDeliveryEnabled;
  final Color? accentColor;

  static Color accentForIndex(int index) => switch (index % 3) {
        0 => AppColors.brandPurple,
        1 => AppColors.deepGreen,
        _ => AppColors.sage,
      };

  factory DishDetailEntry.fromCustomerDish({
    required CustomerDish dish,
    required int kitchenId,
    required String kitchenName,
    String? kitchenLogoUrl,
    String? chefName,
    bool? kitchenInstantDeliveryEnabled,
    required int index,
  }) {
    return DishDetailEntry(
      dish: dish,
      kitchenId: kitchenId,
      kitchenName: kitchenName,
      kitchenLogoUrl: kitchenLogoUrl,
      chefName: chefName,
      kitchenInstantDeliveryEnabled: kitchenInstantDeliveryEnabled,
      accentColor: accentForIndex(index),
    );
  }

  factory DishDetailEntry.fromFeaturedDish(
    CustomerFeaturedDish dish,
    int index,
  ) {
    return DishDetailEntry(
      dish: dish.toCustomerDish(),
      kitchenId: dish.restaurantId,
      kitchenName: dish.restaurantName,
      kitchenLogoUrl: dish.restaurantLogoUrl,
      chefName: dish.chefName,
      accentColor: accentForIndex(index),
    );
  }
}
