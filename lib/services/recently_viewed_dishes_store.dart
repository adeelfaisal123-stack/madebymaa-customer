import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_dish.dart';
import '../models/customer_featured_dish.dart';
import '../models/dish_detail_entry.dart';

/// Locally persisted recently viewed dishes (newest first).
class RecentlyViewedDishesStore extends ChangeNotifier {
  RecentlyViewedDishesStore._();

  static final RecentlyViewedDishesStore instance = RecentlyViewedDishesStore._();

  static const _prefsKey = 'customer_recently_viewed_dishes_v1';
  static const _maxEntries = 8;

  final List<RecentlyViewedDishEntry> _entries = [];
  var _loaded = false;

  List<RecentlyViewedDishEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final entry = RecentlyViewedDishEntry.fromJson(item);
              if (entry != null) _entries.add(entry);
            }
          }
        }
      }
    } catch (_) {
      _entries.clear();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> recordView(DishDetailEntry entry) async {
    await load();
    final key = RecentlyViewedDishEntry.keyFor(entry.kitchenId, entry.dish.id);
    _entries.removeWhere((e) => e.key == key);
    _entries.insert(
      0,
      RecentlyViewedDishEntry.fromEntry(entry, viewedAt: DateTime.now()),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_entries.map((e) => e.toJson()).toList());
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }
}

class RecentlyViewedDishEntry {
  const RecentlyViewedDishEntry({
    required this.dish,
    required this.kitchenId,
    required this.kitchenName,
    required this.viewedAt,
    this.kitchenLogoUrl,
    this.chefName,
    this.kitchenInstantDeliveryEnabled,
  });

  final CustomerDish dish;
  final int kitchenId;
  final String kitchenName;
  final String? kitchenLogoUrl;
  final String? chefName;
  final bool? kitchenInstantDeliveryEnabled;
  final DateTime viewedAt;

  String get key => keyFor(kitchenId, dish.id);

  static String keyFor(int kitchenId, int dishId) => '$kitchenId:$dishId';

  factory RecentlyViewedDishEntry.fromEntry(
    DishDetailEntry entry, {
    required DateTime viewedAt,
  }) {
    return RecentlyViewedDishEntry(
      dish: entry.dish,
      kitchenId: entry.kitchenId,
      kitchenName: entry.kitchenName,
      kitchenLogoUrl: entry.kitchenLogoUrl,
      chefName: entry.chefName,
      kitchenInstantDeliveryEnabled: entry.kitchenInstantDeliveryEnabled,
      viewedAt: viewedAt,
    );
  }

  static RecentlyViewedDishEntry? fromJson(Map<String, dynamic> json) {
    try {
      final dishRaw = json['dish'];
      if (dishRaw is! Map<String, dynamic>) return null;
      final kitchenId = (json['kitchen_id'] as num?)?.toInt();
      final kitchenName = json['kitchen_name'] as String?;
      if (kitchenId == null || kitchenName == null || kitchenName.isEmpty) {
        return null;
      }
      return RecentlyViewedDishEntry(
        dish: CustomerDish.fromJson(dishRaw),
        kitchenId: kitchenId,
        kitchenName: kitchenName,
        kitchenLogoUrl: json['kitchen_logo_url'] as String?,
        chefName: json['chef_name'] as String?,
        kitchenInstantDeliveryEnabled: json['kitchen_instant_delivery_enabled'] as bool?,
        viewedAt: DateTime.tryParse(json['viewed_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'dish': {
          'id': dish.id,
          'name': dish.name,
          'description': dish.description,
          'price': dish.price,
          'effective_price': dish.effectivePrice,
          'is_veg': dish.isVeg,
          'image_url': dish.imageUrl,
          'ingredients': dish.ingredients,
          'tags': dish.tags,
          if (dish.mainCategory != null)
            'super_category': {
              'id': dish.mainCategory!.id,
              'name': dish.mainCategory!.name,
              'slug': dish.mainCategory!.slug,
            },
          'dish_category_id': dish.dishCategoryId,
          'dish_category_name': dish.dishCategoryName,
          'dish_subcategory_id': dish.dishSubcategoryId,
          'dish_subcategory_name': dish.dishSubcategoryName,
          'rating': {
            'average': dish.rating.average,
            'count': dish.rating.count,
          },
        },
        'kitchen_id': kitchenId,
        'kitchen_name': kitchenName,
        'kitchen_logo_url': kitchenLogoUrl,
        'chef_name': chefName,
        'kitchen_instant_delivery_enabled': kitchenInstantDeliveryEnabled,
        'viewed_at': viewedAt.toIso8601String(),
      };

  DishDetailEntry toDetailEntry(int index) {
    return DishDetailEntry(
      dish: dish,
      kitchenId: kitchenId,
      kitchenName: kitchenName,
      kitchenLogoUrl: kitchenLogoUrl,
      chefName: chefName,
      kitchenInstantDeliveryEnabled: kitchenInstantDeliveryEnabled,
      accentColor: DishDetailEntry.accentForIndex(index),
    );
  }

  CustomerFeaturedDish toFeaturedDish() {
    return CustomerFeaturedDish(
      id: dish.id,
      name: dish.name,
      restaurantId: kitchenId,
      restaurantName: kitchenName,
      description: dish.description,
      effectivePrice: dish.effectivePrice,
      price: dish.price,
      isVeg: dish.isVeg,
      imageUrl: dish.imageUrl,
      restaurantLogoUrl: kitchenLogoUrl,
      chefName: chefName,
      ingredients: dish.ingredients,
      tags: dish.tags,
      mainCategory: dish.mainCategory,
      dishCategoryId: dish.dishCategoryId,
      dishSubcategoryId: dish.dishSubcategoryId,
    );
  }
}
