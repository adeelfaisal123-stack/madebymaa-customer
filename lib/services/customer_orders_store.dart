import 'package:flutter/foundation.dart';

import '../models/cart_line_item.dart';
import '../models/customer_order.dart';
import '../models/delivery_slot.dart';
import '../customer_session_prefs.dart';
import 'optica2_api.dart';

/// Customer order history backed by the Optica2 API.
class CustomerOrdersStore extends ChangeNotifier {
  CustomerOrdersStore._();

  static final CustomerOrdersStore instance = CustomerOrdersStore._();

  final List<CustomerOrder> _orders = [];
  var _loading = false;
  var _loadedOnce = false;
  String? _error;

  List<CustomerOrder> get orders => List.unmodifiable(_orders);

  bool get loading => _loading;

  bool get loadedOnce => _loadedOnce;

  String? get error => _error;

  Future<CustomerOrder> placeOrder({
    required Optica2Api api,
    required List<CartLineItem> lines,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String paymentMethod,
    String? notes,
    String? paymentReference,
    DeliverySlotSelection? deliverySlot,
  }) async {
    final session = await CustomerSessionPrefs.load();
    final order = await api.createOrder(
      lines: lines,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      notes: notes,
      deliverySlot: deliverySlot ?? const DeliverySlotSelection.now(),
      customerId: session?.id,
      customerPhone: session?.phone,
    );

    _orders.removeWhere((existing) => existing.id == order.id);
    _orders.insert(0, order);
    _loadedOnce = true;
    _error = null;
    notifyListeners();
    return order;
  }

  Future<CustomerOrder> cancelOrder({
    Optica2Api? api,
    required CustomerOrder order,
  }) async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) {
      throw Optica2ApiException('Sign in to cancel orders.');
    }

    final dbId = order.dbId;
    if (dbId == null) {
      throw Optica2ApiException('Could not cancel order.');
    }

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      final updated = await client.cancelOrder(
        orderId: dbId,
        customerId: session.id,
        customerPhone: session.phone,
      );

      final index = _orders.indexWhere((existing) => existing.id == updated.id);
      if (index >= 0) {
        _orders[index] = updated;
      } else {
        _orders.insert(0, updated);
      }
      _error = null;
      notifyListeners();
      return updated;
    } finally {
      if (ownsClient) client.close();
    }
  }

  Future<CustomerOrder> submitReview({
    Optica2Api? api,
    required CustomerOrder order,
    required List<Map<String, dynamic>> kitchenRatings,
    required List<Map<String, dynamic>> dishRatings,
  }) async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) {
      throw Optica2ApiException('Sign in to submit a review.');
    }

    final dbId = order.dbId;
    if (dbId == null) {
      throw Optica2ApiException('Could not submit review.');
    }

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      final updated = await client.submitOrderReview(
        orderId: dbId,
        customerId: session.id,
        customerPhone: session.phone,
        kitchenRatings: kitchenRatings,
        dishRatings: dishRatings,
      );

      final index = _orders.indexWhere((existing) => existing.id == updated.id);
      if (index >= 0) {
        _orders[index] = updated;
      } else {
        _orders.insert(0, updated);
      }
      _error = null;
      notifyListeners();
      return updated;
    } finally {
      if (ownsClient) client.close();
    }
  }

  Future<CustomerOrder> requestRefund({
    Optica2Api? api,
    required CustomerOrder order,
    required String description,
    String? imagePath,
  }) async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) {
      throw Optica2ApiException('Sign in to request a refund.');
    }

    final dbId = order.dbId;
    if (dbId == null) {
      throw Optica2ApiException('Could not submit refund request.');
    }

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      final updated = await client.submitRefundRequest(
        orderId: dbId,
        customerId: session.id,
        customerPhone: session.phone,
        description: description,
        imagePath: imagePath,
      );

      final index = _orders.indexWhere((existing) => existing.id == updated.id);
      if (index >= 0) {
        _orders[index] = updated;
      } else {
        _orders.insert(0, updated);
      }
      _error = null;
      notifyListeners();
      return updated;
    } finally {
      if (ownsClient) client.close();
    }
  }

  Future<void> refresh({Optica2Api? api}) async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) {
      _orders.clear();
      _loadedOnce = true;
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      final fetched = await client.fetchOrders(
        customerId: session.id,
        customerPhone: session.phone,
      );
      _orders
        ..clear()
        ..addAll(fetched);
      _loadedOnce = true;
    } on Optica2ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load orders.';
    } finally {
      _loading = false;
      if (ownsClient) client.close();
      notifyListeners();
    }
  }
}
