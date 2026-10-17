import 'customer_dish.dart';
import 'dish_main_category.dart';

/// A dish line in the customer cart, tied to a kitchen.
class CartLineItem {
  const CartLineItem({
    required this.dishId,
    required this.dishName,
    required this.kitchenId,
    required this.kitchenName,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.isVeg = true,
    this.mainCategoryId,
    this.mainCategoryName,
    this.mainCategoryTimeRange,
  });

  final int dishId;
  final String dishName;
  final int kitchenId;
  final String kitchenName;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final bool isVeg;
  final int? mainCategoryId;
  final String? mainCategoryName;
  final String? mainCategoryTimeRange;

  DishMainCategory? get mainCategory {
    final id = mainCategoryId;
    final name = mainCategoryName?.trim() ?? '';
    if (id == null || id <= 0 || name.isEmpty) return null;
    return DishMainCategory(
      id: id,
      name: name,
      timeRange: mainCategoryTimeRange?.trim() ?? '',
    );
  }

  String get key => '$kitchenId:$dishId';

  double get lineTotal => unitPrice * quantity;

  String get lineTotalLabel => '₹${lineTotal.toStringAsFixed(0)}';

  CartLineItem copyWith({int? quantity}) {
    return CartLineItem(
      dishId: dishId,
      dishName: dishName,
      kitchenId: kitchenId,
      kitchenName: kitchenName,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl,
      isVeg: isVeg,
      mainCategoryId: mainCategoryId,
      mainCategoryName: mainCategoryName,
      mainCategoryTimeRange: mainCategoryTimeRange,
    );
  }

  factory CartLineItem.fromDish({
    required CustomerDish dish,
    required int kitchenId,
    required String kitchenName,
    int quantity = 1,
  }) {
    return CartLineItem(
      dishId: dish.id,
      dishName: dish.name,
      kitchenId: kitchenId,
      kitchenName: kitchenName,
      unitPrice: dish.effectivePrice,
      quantity: quantity,
      imageUrl: dish.imageUrl,
      isVeg: dish.isVeg,
      mainCategoryId: dish.mainCategory?.id,
      mainCategoryName: dish.mainCategory?.name,
      mainCategoryTimeRange: dish.mainCategory?.timeRange,
    );
  }
}
