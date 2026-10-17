import 'customer_dish.dart';
import 'dish_main_category.dart';
import '../utils/dish_availability.dart';

class CustomerFeaturedDish {
  const CustomerFeaturedDish({
    required this.id,
    required this.name,
    required this.restaurantId,
    required this.restaurantName,
    this.description,
    required this.effectivePrice,
    required this.price,
    required this.isVeg,
    this.imageUrl,
    this.restaurantLogoUrl,
    this.restaurantCuisine,
    this.chefName,
    this.ingredients,
    this.tags = const [],
    this.superCategoryIds = const [],
    this.mainCategory,
    this.availability = const {},
    this.dishCategoryId,
    this.dishSubcategoryId,
  });

  final int id;
  final String name;
  final int restaurantId;
  final String restaurantName;
  final String? description;
  final double effectivePrice;
  final double price;
  final bool isVeg;
  final String? imageUrl;
  final String? restaurantLogoUrl;
  final String? restaurantCuisine;
  final String? chefName;
  final String? ingredients;
  final List<String> tags;
  final List<int> superCategoryIds;
  final DishMainCategory? mainCategory;
  final DishAvailabilityMap availability;
  final int? dishCategoryId;
  final int? dishSubcategoryId;

  factory CustomerFeaturedDish.fromJson(Map<String, dynamic> json) {
    return CustomerFeaturedDish(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Dish',
      restaurantId: (json['restaurant_id'] as num).toInt(),
      restaurantName: json['restaurant_name'] as String? ?? 'Kitchen',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      effectivePrice: (json['effective_price'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      isVeg: json['is_veg'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      restaurantLogoUrl: json['restaurant_logo_url'] as String?,
      restaurantCuisine: json['restaurant_cuisine'] as String?,
      chefName: (json['chef_name'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['chef_name'] as String).trim(),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((t) => t.isNotEmpty)
              .toList() ??
          const [],
      superCategoryIds: (json['super_category_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      mainCategory: () {
        final category = DishMainCategory.fromJson(
          json['super_category'] as Map<String, dynamic>?,
        );
        return category.isValid ? category : null;
      }(),
      availability: parseDishAvailability(json['availability']),
      dishCategoryId: (json['dish_category_id'] as num?)?.toInt(),
      dishSubcategoryId: (json['dish_subcategory_id'] as num?)?.toInt(),
    );
  }

  bool matchesSuperCategory(int? superCategoryId) {
    if (superCategoryId == null) return true;
    return superCategoryIds.contains(superCategoryId);
  }

  bool matchesSubcategory(int? subcategoryId) {
    if (subcategoryId == null) return true;
    return dishSubcategoryId == subcategoryId;
  }

  /// Whether this dish is offered today for [filterSuperCategoryId] (or any category when null).
  bool isAvailableToday({
    required Map<int, String> categorySlugById,
    int? filterSuperCategoryId,
    String? dayKey,
  }) {
    return isDishAvailableOnDay(
      availability: availability,
      dayKey: dayKey ?? dishAvailabilityTodayKey(),
      superCategoryIds: superCategoryIds,
      categorySlugById: categorySlugById,
      filterSuperCategoryId: filterSuperCategoryId,
    );
  }

  CustomerDish toCustomerDish() {
    return CustomerDish(
      id: id,
      name: name,
      description: description,
      price: price,
      effectivePrice: effectivePrice,
      isVeg: isVeg,
      imageUrl: imageUrl,
      ingredients: ingredients,
      tags: tags,
      mainCategory: mainCategory,
    );
  }

  String get priceLabel => '₹${effectivePrice.toStringAsFixed(0)}';

  bool get hasDiscount => effectivePrice < price - 0.01;
}
