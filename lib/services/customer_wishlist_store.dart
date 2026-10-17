import 'package:flutter/foundation.dart';

import '../models/customer_dish.dart';

/// Saved dishes (wishlist) keyed by kitchen + dish id.
class CustomerWishlistStore extends ChangeNotifier {
  CustomerWishlistStore._();

  static final CustomerWishlistStore instance = CustomerWishlistStore._();

  final Map<String, WishlistEntry> _entries = {};

  List<WishlistEntry> get entries => _entries.values.toList()
    ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  int get count => _entries.length;

  /// Re-broadcast current wishlist state (pull-to-refresh).
  void refresh() => notifyListeners();

  static String keyFor(int kitchenId, int dishId) => '$kitchenId:$dishId';

  bool isSaved(int kitchenId, int dishId) =>
      _entries.containsKey(keyFor(kitchenId, dishId));

  void toggle({
    required CustomerDish dish,
    required int kitchenId,
    required String kitchenName,
    String? kitchenLogoUrl,
  }) {
    final key = keyFor(kitchenId, dish.id);
    if (_entries.containsKey(key)) {
      _entries.remove(key);
    } else {
      _entries[key] = WishlistEntry(
        dish: dish,
        kitchenId: kitchenId,
        kitchenName: kitchenName,
        kitchenLogoUrl: kitchenLogoUrl,
        savedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  void remove(int kitchenId, int dishId) {
    if (_entries.remove(keyFor(kitchenId, dishId)) != null) {
      notifyListeners();
    }
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}

class WishlistEntry {
  const WishlistEntry({
    required this.dish,
    required this.kitchenId,
    required this.kitchenName,
    required this.savedAt,
    this.kitchenLogoUrl,
  });

  final CustomerDish dish;
  final int kitchenId;
  final String kitchenName;
  final String? kitchenLogoUrl;
  final DateTime savedAt;
}
