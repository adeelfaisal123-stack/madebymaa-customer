import '../models/customer_featured_dish.dart';
import '../models/customer_featured_kitchen.dart';

String _normalizeQuery(String query) => query.trim().toLowerCase();

bool _contains(String? value, String normalized) {
  if (value == null || value.isEmpty) return false;
  return value.toLowerCase().contains(normalized);
}

/// Whether [kitchen] matches a case-insensitive [query] on name, cuisine, address, or tags.
bool kitchenMatchesQuery(CustomerFeaturedKitchen kitchen, String query) {
  final q = _normalizeQuery(query);
  if (q.isEmpty) return true;
  if (kitchen.name.toLowerCase().contains(q)) return true;
  if (_contains(kitchen.cuisine, q)) return true;
  if (_contains(kitchen.address, q)) return true;
  if (_contains(kitchen.deliveryLabel, q)) return true;
  for (final tag in kitchen.tags) {
    if (tag.toLowerCase().contains(q)) return true;
  }
  return false;
}

/// Whether [dish] matches a case-insensitive [query] on name, kitchen, description, tags, or cuisine.
bool dishMatchesQuery(CustomerFeaturedDish dish, String query) {
  final q = _normalizeQuery(query);
  if (q.isEmpty) return true;
  if (dish.name.toLowerCase().contains(q)) return true;
  if (dish.restaurantName.toLowerCase().contains(q)) return true;
  if (_contains(dish.description, q)) return true;
  if (_contains(dish.restaurantCuisine, q)) return true;
  for (final tag in dish.tags) {
    if (tag.toLowerCase().contains(q)) return true;
  }
  return false;
}

/// Whether [dish] belongs to a kitchen tagged with [cuisineName].
bool dishMatchesCuisineName(CustomerFeaturedDish dish, String cuisineName) {
  final target = cuisineName.trim().toLowerCase();
  if (target.isEmpty) return true;
  return dish.restaurantCuisine?.trim().toLowerCase() == target;
}

/// Whether [kitchen] is tagged with [cuisineName] (exact or soft contains).
bool kitchenMatchesCuisineName(
  CustomerFeaturedKitchen kitchen,
  String cuisineName,
) {
  final target = cuisineName.trim().toLowerCase();
  if (target.isEmpty) return true;
  final cuisine = kitchen.cuisine?.trim().toLowerCase() ?? '';
  if (cuisine.isEmpty) return false;
  return cuisine == target ||
      cuisine.contains(target) ||
      target.contains(cuisine);
}
