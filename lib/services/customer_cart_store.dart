import 'package:flutter/foundation.dart';

import '../models/cart_line_item.dart';
import '../models/customer_dish.dart';

/// In-memory cart for the customer app (single-kitchen lines grouped by key).
class CustomerCartStore extends ChangeNotifier {
  CustomerCartStore._();

  static final CustomerCartStore instance = CustomerCartStore._();

  final Map<String, CartLineItem> _lines = {};

  List<CartLineItem> get lines =>
      _lines.values.toList()..sort((a, b) => a.dishName.compareTo(b.dishName));

  /// Re-broadcast current cart state (pull-to-refresh).
  void refresh() => notifyListeners();

  int get itemCount => _lines.values.fold(0, (sum, l) => sum + l.quantity);

  double get subtotal =>
      _lines.values.fold(0, (sum, l) => sum + l.lineTotal);

  String get subtotalLabel => '₹${subtotal.toStringAsFixed(0)}';

  /// Kitchen id for items currently in the cart, if any.
  int? get kitchenId =>
      _lines.isEmpty ? null : _lines.values.first.kitchenId;

  /// Cached from kitchen profile when items were added; used at checkout.
  bool? get kitchenInstantDeliveryEnabled => _kitchenInstantDeliveryEnabled;

  bool? _kitchenInstantDeliveryEnabled;

  void setKitchenInstantDeliveryEnabled(bool enabled) {
    _kitchenInstantDeliveryEnabled = enabled;
  }

  /// Kitchen name for items currently in the cart, if any.
  String? get kitchenName =>
      _lines.isEmpty ? null : _lines.values.first.kitchenName;

  int quantityFor(int kitchenId, int dishId) =>
      _lines['$kitchenId:$dishId']?.quantity ?? 0;

  bool canAddFromKitchen(int kitchenId) =>
      kitchenId == this.kitchenId || _lines.isEmpty;

  /// User-facing message when [kitchenId] conflicts with the locked cart kitchen.
  String? kitchenConflictMessage(int kitchenId) {
    final lockedId = this.kitchenId;
    if (lockedId == null || lockedId == kitchenId) return null;
    final name = kitchenName?.trim();
    final label = (name != null && name.isNotEmpty) ? name : 'another kitchen';
    return 'Your cart has items from $label. '
        'Clear the cart or checkout before ordering from a different kitchen.';
  }

  /// Returns false when adding from a different kitchen than the cart lock.
  bool addDish({
    required CustomerDish dish,
    required int kitchenId,
    required String kitchenName,
    int quantity = 1,
    bool? kitchenInstantDeliveryEnabled,
  }) {
    final key = '$kitchenId:${dish.id}';
    final existing = _lines[key];
    if (existing == null && !canAddFromKitchen(kitchenId)) {
      return false;
    }
    if (kitchenInstantDeliveryEnabled != null) {
      _kitchenInstantDeliveryEnabled = kitchenInstantDeliveryEnabled;
    }
    if (existing != null) {
      _lines[key] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      _lines[key] = CartLineItem.fromDish(
        dish: dish,
        kitchenId: kitchenId,
        kitchenName: kitchenName,
        quantity: quantity,
      );
    }
    notifyListeners();
    return true;
  }

  /// Sets exact quantity for a dish (adds line if missing).
  /// Returns false when adding a new line from a different kitchen.
  bool setDishQuantity({
    required CustomerDish dish,
    required int kitchenId,
    required String kitchenName,
    required int quantity,
    bool? kitchenInstantDeliveryEnabled,
  }) {
    if (quantity <= 0) {
      removeLine(kitchenId, dish.id);
      return true;
    }
    final key = '$kitchenId:${dish.id}';
    if (_lines[key] == null && !canAddFromKitchen(kitchenId)) {
      return false;
    }
    if (kitchenInstantDeliveryEnabled != null) {
      _kitchenInstantDeliveryEnabled = kitchenInstantDeliveryEnabled;
    }
    _lines[key] = CartLineItem.fromDish(
      dish: dish,
      kitchenId: kitchenId,
      kitchenName: kitchenName,
      quantity: quantity,
    );
    notifyListeners();
    return true;
  }

  void setQuantity(int kitchenId, int dishId, int quantity) {
    final key = '$kitchenId:$dishId';
    final existing = _lines[key];
    if (existing == null) return;
    if (quantity < 1) return;

    _lines[key] = existing.copyWith(quantity: quantity);
    notifyListeners();
  }

  void removeLine(int kitchenId, int dishId) {
    _lines.remove('$kitchenId:$dishId');
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _kitchenInstantDeliveryEnabled = null;
    notifyListeners();
  }
}
