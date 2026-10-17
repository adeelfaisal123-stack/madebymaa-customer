import 'dish_main_category.dart';
import 'customer_review.dart';

class CustomerDish {
  const CustomerDish({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.effectivePrice,
    required this.isVeg,
    this.imageUrl,
    this.ingredients,
    this.tags = const [],
    this.mainCategory,
    this.dishCategoryId,
    this.dishCategoryName,
    this.dishSubcategoryId,
    this.dishSubcategoryName,
    this.rating = const CustomerRatingSummary.empty(),
  });

  final int id;
  final String name;
  final String? description;
  final double price;
  final double effectivePrice;
  final bool isVeg;
  final String? imageUrl;
  final String? ingredients;
  final List<String> tags;

  /// Time-of-day super category (Breakfast / Lunch / Dinner).
  final DishMainCategory? mainCategory;

  /// Food-type category (Curries / Snacks / Desserts / …).
  final int? dishCategoryId;
  final String? dishCategoryName;

  /// Narrower food-type subcategory (e.g. South Indian curries).
  final int? dishSubcategoryId;
  final String? dishSubcategoryName;

  final CustomerRatingSummary rating;

  factory CustomerDish.fromJson(Map<String, dynamic> json) {
    final dishCategory = json['dish_category'];
    final dishSubcategory = json['dish_subcategory'];

    return CustomerDish(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Dish',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      effectivePrice: (json['effective_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      isVeg: json['is_veg'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      ingredients: json['ingredients'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          const [],
      mainCategory: () {
        final category = DishMainCategory.fromJson(
          json['super_category'] as Map<String, dynamic>?,
        );
        return category.isValid ? category : null;
      }(),
      dishCategoryId: (json['dish_category_id'] as num?)?.toInt() ??
          (dishCategory is Map<String, dynamic>
              ? (dishCategory['id'] as num?)?.toInt()
              : null),
      dishCategoryName: dishCategory is Map<String, dynamic>
          ? (dishCategory['name'] as String?)?.trim()
          : null,
      dishSubcategoryId: (json['dish_subcategory_id'] as num?)?.toInt() ??
          (dishSubcategory is Map<String, dynamic>
              ? (dishSubcategory['id'] as num?)?.toInt()
              : null),
      dishSubcategoryName: dishSubcategory is Map<String, dynamic>
          ? (dishSubcategory['name'] as String?)?.trim()
          : null,
      rating: CustomerRatingSummary.fromJson(json['rating']),
    );
  }

  bool get hasDiscount => effectivePrice < price - 0.01;

  String get priceLabel => '₹${effectivePrice.toStringAsFixed(0)}';

  String? get originalPriceLabel =>
      hasDiscount ? '₹${price.toStringAsFixed(0)}' : null;

  /// Best label to show for the dish's category, preferring the food-type
  /// category over the time-based super category and finally a veg fallback.
  String get displayCategoryLabel {
    final cat = dishCategoryName?.trim();
    if (cat != null && cat.isNotEmpty) return cat;

    final sub = dishSubcategoryName?.trim();
    if (sub != null && sub.isNotEmpty) return sub;

    final main = mainCategory?.name.trim();
    if (main != null && main.isNotEmpty) return main;

    return isVeg ? 'Veg dish' : 'Non-veg dish';
  }

  /// Stable id for grouping dishes by their food category in the kitchen
  /// detail screen filter row. Falls back to subcategory id, then super
  /// category id, then a synthetic key — so dishes without a tagged food
  /// category still appear in *one* group instead of vanishing.
  int get displayCategoryGroupId {
    if (dishCategoryId != null && dishCategoryId! > 0) {
      return dishCategoryId!;
    }
    if (dishSubcategoryId != null && dishSubcategoryId! > 0) {
      // Negative space avoids collisions with dish_category ids.
      return -1000000 - dishSubcategoryId!;
    }
    if (mainCategory?.id != null && mainCategory!.id > 0) {
      return -2000000 - mainCategory!.id;
    }
    return -1; // ungrouped
  }
}
