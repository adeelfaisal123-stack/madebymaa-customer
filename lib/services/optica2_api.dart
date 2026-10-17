import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;

import '../config/optica2_config.dart';
import '../models/cart_line_item.dart';
import '../models/customer_auth.dart';
import '../models/customer_dish_category.dart';
import '../models/customer_featured_dish.dart';
import '../models/customer_featured_kitchen.dart';
import '../models/customer_home_slider.dart';
import '../models/customer_startup_popup.dart';
import '../models/customer_cuisine.dart';
import '../models/customer_super_category.dart';
import '../models/customer_kitchen_detail.dart';
import '../models/customer_maps_config.dart';
import '../models/customer_notification.dart';
import '../models/customer_order.dart';
import '../models/customer_review.dart';
import '../models/customer_wallet.dart';
import '../models/delivery_slot.dart';
import '../models/customer_payment_config.dart';
import '../models/customer_delivery_quote.dart';
import '../models/otp_config.dart';

class Optica2ApiException implements Exception {
  Optica2ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Minimal Optica2 client for customer app (maps config from admin settings).
class Optica2Api {
  Optica2Api({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Shared client for image downloads (palette extraction, etc.).
  http.Client get clientForImages => _client;

  /// Google Maps API key saved in Optica2 admin (System settings).
  Map<String, String> _jsonHeaders() {
    final headers = <String, String>{'Accept': 'application/json'};
    if (Optica2Config.apiKey.isNotEmpty) {
      headers['X-Seller-Api-Key'] = Optica2Config.apiKey;
    }
    return headers;
  }

  /// Launch popup (title + content) from admin App management.
  Future<CustomerStartupPopup> fetchStartupPopup() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerStartupPopupUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      return const CustomerStartupPopup(
        enabled: false,
        title: '',
        content: '',
      );
    }

    final raw = body['popup'];
    if (raw is! Map<String, dynamic>) {
      return const CustomerStartupPopup(
        enabled: false,
        title: '',
        content: '',
      );
    }

    return CustomerStartupPopup.fromJson(raw);
  }

  /// Home carousel slides for the Explore tab.
  Future<CustomerHomeSlidersPayload> fetchHomeSliders() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerHomeSlidersUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load home banners.',
        statusCode: response.statusCode,
      );
    }

    return CustomerHomeSlidersPayload(
      hero: _parseHomeSliders(body['sliders']),
      mid: _parseHomeSliders(body['mid_sliders']),
    );
  }

  List<CustomerHomeSlider> _parseHomeSliders(Object? raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerHomeSlider.fromJson)
        .where((s) => s.imageUrl.isNotEmpty)
        .toList();
  }

  /// Regional cuisines for the home Explore grid.
  Future<List<CustomerCuisine>> fetchCuisines() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerCuisinesUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      return const [];
    }

    final raw = body['cuisines'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerCuisine.fromJson)
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  /// Meal-time super categories for the home "Craving something?" row.
  Future<List<CustomerSuperCategory>> fetchSuperCategories() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerSuperCategoriesUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      return const [];
    }

    final raw = body['super_categories'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerSuperCategory.fromJson)
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  /// Active menu categories (Biryani, Rice, etc.) for the home screen.
  Future<List<CustomerDishCategory>> fetchDishCategories() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerDishCategoriesUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load categories.',
        statusCode: response.statusCode,
      );
    }

    final raw = body['dish_categories'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerDishCategory.fromJson)
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  /// All available dishes across kitchens (browse / view all).
  Future<List<CustomerFeaturedDish>> fetchBrowseDishes({
    int? superCategoryId,
    int? cuisineId,
    int? dishCategoryId,
  }) async {
    http.Response response;
    try {
      response = await _client
          .get(
            Optica2Config.customerBrowseDishesUri(
              superCategoryId: superCategoryId,
              cuisineId: cuisineId,
              dishCategoryId: dishCategoryId,
            ),
            headers: _jsonHeaders(),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load dishes.',
        statusCode: response.statusCode,
      );
    }

    final raw = body['dishes'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerFeaturedDish.fromJson)
        .where((d) => d.name.isNotEmpty)
        .toList();
  }

  /// Featured kitchens for the Explore tab.
  Future<CustomerKitchenDetail> fetchKitchenDetail(int kitchenId) async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerKitchenUri(kitchenId), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 404) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Kitchen not found.',
        statusCode: 404,
      );
    }

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load kitchen menu.',
        statusCode: response.statusCode,
      );
    }

    return CustomerKitchenDetail.fromJson(body);
  }

  Future<List<CustomerFeaturedDish>> fetchFeaturedDishes({int? superCategoryId}) async {
    http.Response response;
    try {
      var uri = Optica2Config.customerFeaturedDishesUri();
      if (superCategoryId != null) {
        uri = uri.replace(
          queryParameters: {'super_category_id': '$superCategoryId'},
        );
      }
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load featured dishes.',
        statusCode: response.statusCode,
      );
    }

    final raw = body['dishes'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerFeaturedDish.fromJson)
        .toList();
  }

  /// All active kitchens (browse / view all).
  /// Pass [latitude] and [longitude] to filter by admin nearby radius.
  Future<List<CustomerFeaturedKitchen>> fetchBrowseKitchens({
    double? latitude,
    double? longitude,
  }) async {
    http.Response response;
    try {
      response = await _client
          .get(
            Optica2Config.customerBrowseKitchensUri(
              latitude: latitude,
              longitude: longitude,
            ),
            headers: _jsonHeaders(),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load kitchens.',
        statusCode: response.statusCode,
      );
    }

    final raw = body['kitchens'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerFeaturedKitchen.fromJson)
        .where((k) => k.name.isNotEmpty)
        .toList();
  }

  Future<List<CustomerFeaturedKitchen>> fetchFeaturedKitchens() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerFeaturedKitchensUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load featured kitchens.',
        statusCode: response.statusCode,
      );
    }

    final raw = body['kitchens'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerFeaturedKitchen.fromJson)
        .toList();
  }

  Future<CustomerMapsConfig> fetchMapsConfig() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.sellerMapsConfigUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load maps settings.',
        statusCode: response.statusCode,
      );
    }

    final mapsRaw = body['maps'];
    if (mapsRaw is Map<String, dynamic>) {
      return CustomerMapsConfig.fromJson(mapsRaw);
    }

    return const CustomerMapsConfig(
      apiKey: '',
      defaultLat: 20.5937,
      defaultLng: 78.9629,
      nearbyRadiusKm: 20,
    );
  }

  Future<OtpConfig> fetchOtpConfig() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.otpConfigUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not load OTP settings.',
        statusCode: response.statusCode,
      );
    }

    return OtpConfig.fromJson(body);
  }

  /// Sends OTP via MSG91 when that provider is selected in admin.
  Future<void> sendOtp(String phoneE164) async {
    if (kDebugMode) {
      debugPrint('MSG91 sendOtp → $phoneE164 via ${Optica2Config.otpSendUri()}');
    }
    await _postOtp(
      Optica2Config.otpSendUri(),
      {'phone': phoneE164},
      errorFallback: 'Could not send OTP.',
    );
  }

  Future<void> verifyOtp(String phoneE164, String otp) async {
    await _postOtp(
      Optica2Config.otpVerifyUri(),
      {'phone': phoneE164, 'otp': otp},
      errorFallback: 'Invalid or expired code.',
    );
  }

  Future<CustomerPhoneCheckResult> checkCustomerPhone(String phoneE164) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Optica2Config.customerAuthCheckPhoneUri(),
            headers: {
              ..._jsonHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'phone': phoneE164}),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? body;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) body = raw;
    } catch (_) {}

    if (response.statusCode >= 500) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not verify phone number.',
        statusCode: response.statusCode,
      );
    }

    if (body == null) {
      throw Optica2ApiException(
        'Could not verify phone number.',
        statusCode: response.statusCode,
      );
    }

    return CustomerPhoneCheckResult.fromJson(body);
  }

  Future<CustomerLoginResult> verifyCustomerLogin({
    required String phoneE164,
    required String otp,
    String? name,
  }) async {
    final payload = <String, String>{
      'phone': phoneE164,
      'otp': otp,
    };
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }

    final body = await _postJson(
      Optica2Config.customerAuthVerifyLoginUri(),
      payload,
      errorFallback: 'Could not sign in.',
    );
    return CustomerLoginResult.fromJson(body);
  }

  /// After client-side Firebase Phone Auth — register or log in without MSG91 OTP.
  Future<CustomerLoginResult> completeCustomerSession({
    required String phoneE164,
    String? name,
  }) async {
    final payload = <String, String>{'phone': phoneE164};
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }

    final body = await _postJson(
      Optica2Config.customerAuthCompleteSessionUri(),
      payload,
      errorFallback: 'Could not sign in.',
    );
    return CustomerLoginResult.fromJson(body);
  }

  Future<CustomerAuth> fetchCustomerProfile({
    required int customerId,
    required String customerPhone,
  }) async {
    final uri = Optica2Config.customerProfileUri().replace(
      queryParameters: {
        'customer_id': '$customerId',
        'customer_phone': customerPhone,
      },
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? 'Could not load profile.',
        statusCode: response.statusCode,
      );
    }

    final customerJson = decoded['customer'];
    if (customerJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not load profile.');
    }

    return CustomerAuth.fromJson(customerJson);
  }

  Future<CustomerWalletSnapshot> fetchWallet({
    required int customerId,
    required String customerPhone,
  }) async {
    final uri = Optica2Config.customerWalletUri().replace(
      queryParameters: {
        'customer_id': '$customerId',
        'customer_phone': customerPhone,
      },
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? 'Could not load wallet.',
        statusCode: response.statusCode,
      );
    }

    return CustomerWalletSnapshot.fromJson(decoded);
  }

  Future<CustomerWalletSnapshot> topupWallet({
    required int customerId,
    required String customerPhone,
    required double amountRupees,
    required String paymentMethod,
    required String paymentReference,
  }) async {
    final body = await _postJson(
      Optica2Config.customerWalletTopupUri(),
      {
        'customer_id': '$customerId',
        'customer_phone': customerPhone,
        'amount': amountRupees.toStringAsFixed(2),
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
      },
      errorFallback: 'Could not add funds to wallet.',
    );

    return CustomerWalletSnapshot.fromJson({
      'wallet': body['wallet'],
      'transactions': body['transactions'] ?? const [],
    });
  }

  Future<CustomerAuth> updateCustomerProfile({
    required int customerId,
    required String customerPhone,
    required String name,
    String? email,
  }) async {
    final payload = <String, dynamic>{
      'customer_id': customerId,
      'customer_phone': customerPhone,
      'name': name.trim(),
      'email': email?.trim() ?? '',
    };

    final body = await _putJsonDynamic(
      Optica2Config.customerProfileUri(),
      payload,
      errorFallback: 'Could not update profile.',
    );

    final customerJson = body['customer'];
    if (customerJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not update profile.');
    }

    return CustomerAuth.fromJson(customerJson);
  }

  /// Payment options for checkout (COD + Razorpay + Stripe + Cashfree when enabled in admin).
  Future<CustomerPaymentConfig> fetchPaymentConfig() async {
    http.Response response;
    try {
      response = await _client
          .get(Optica2Config.customerPaymentConfigUri(), headers: _jsonHeaders())
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      if (await Optica2Config.tryRecoverHost()) {
        response = await _client
            .get(Optica2Config.customerPaymentConfigUri(), headers: _jsonHeaders())
            .timeout(const Duration(seconds: 12));
      } else {
        await _failUnreachable(e);
      }
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        'Could not load payment options from admin.',
        statusCode: response.statusCode,
      );
    }

    return CustomerPaymentConfig.fromJson(body);
  }

  Future<RazorpayCheckoutOrder> createRazorpayOrder({
    required double amountRupees,
    String? receipt,
  }) async {
    final payload = <String, String>{
      'amount': amountRupees.toStringAsFixed(2),
    };
    if (receipt != null && receipt.isNotEmpty) {
      payload['receipt'] = receipt;
    }

    final body = await _postJson(
      Optica2Config.customerRazorpayOrderUri(),
      payload,
      errorFallback: 'Could not start online payment.',
    );

    return RazorpayCheckoutOrder.fromJson(body);
  }

  Future<void> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await _postJson(
      Optica2Config.customerRazorpayVerifyUri(),
      {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
      errorFallback: 'Payment verification failed.',
    );
  }

  Future<StripeCheckoutIntent> createStripePaymentIntent({
    required double amountRupees,
  }) async {
    final body = await _postJson(
      Optica2Config.customerStripeIntentUri(),
      {'amount': amountRupees.toStringAsFixed(2)},
      errorFallback: 'Could not start online payment.',
    );

    return StripeCheckoutIntent.fromJson(body);
  }

  Future<void> verifyStripePayment({
    required String paymentIntentId,
  }) async {
    await _postJson(
      Optica2Config.customerStripeVerifyUri(),
      {'payment_intent_id': paymentIntentId},
      errorFallback: 'Payment verification failed.',
    );
  }

  Future<CashfreeCheckoutOrder> createCashfreeOrder({
    required double amountRupees,
    String? orderId,
    String? customerPhone,
  }) async {
    final payload = <String, String>{
      'amount': amountRupees.toStringAsFixed(2),
    };
    if (orderId != null && orderId.isNotEmpty) {
      payload['order_id'] = orderId;
    }
    if (customerPhone != null && customerPhone.isNotEmpty) {
      payload['customer_phone'] = customerPhone;
    }

    final body = await _postJson(
      Optica2Config.customerCashfreeOrderUri(),
      payload,
      errorFallback: 'Could not start online payment.',
    );

    return CashfreeCheckoutOrder.fromJson(body);
  }

  Future<void> verifyCashfreePayment({
    required String orderId,
  }) async {
    await _postJson(
      Optica2Config.customerCashfreeVerifyUri(),
      {'order_id': orderId},
      errorFallback: 'Payment verification failed.',
    );
  }

  Future<CustomerDeliveryQuote> fetchDeliveryQuote({
    required List<CartLineItem> lines,
    required double deliveryLatitude,
    required double deliveryLongitude,
  }) async {
    final payload = <String, dynamic>{
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'items': lines
          .map(
            (line) => {
              'dish_id': line.dishId,
              'restaurant_id': line.kitchenId,
              'quantity': line.quantity,
            },
          )
          .toList(),
    };

    final body = await _postJsonDynamic(
      Optica2Config.customerDeliveryQuoteUri(),
      payload,
      errorFallback: 'Could not calculate delivery fee.',
    );

    final quoteJson = body['quote'];
    if (quoteJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not calculate delivery fee.');
    }

    return CustomerDeliveryQuote.fromJson(quoteJson);
  }

  Future<CustomerOrder> createOrder({
    required List<CartLineItem> lines,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String paymentMethod,
    String? paymentReference,
    String? notes,
    DeliverySlotSelection? deliverySlot,
    int? customerId,
    String? customerPhone,
  }) async {
    final payload = <String, dynamic>{
      'delivery_address': deliveryAddress,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'payment_method': paymentMethod,
      'delivery_slot': (deliverySlot ?? const DeliverySlotSelection.now())
          .toApiPayload(),
      'items': lines
          .map(
            (line) => {
              'dish_id': line.dishId,
              'restaurant_id': line.kitchenId,
              'quantity': line.quantity,
            },
          )
          .toList(),
    };

    if (customerId != null) {
      payload['customer_id'] = customerId;
    }
    if (customerPhone != null && customerPhone.isNotEmpty) {
      payload['customer_phone'] = customerPhone;
    }
    if (paymentReference != null && paymentReference.isNotEmpty) {
      payload['payment_reference'] = paymentReference;
    }
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final body = await _postJsonDynamic(
      Optica2Config.customerOrdersUri(),
      payload,
      errorFallback: 'Could not place order.',
    );

    final orderJson = body['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not place order.');
    }

    return CustomerOrder.fromJson(orderJson);
  }

  Future<List<CustomerOrder>> fetchOrders({
    required int customerId,
    required String customerPhone,
  }) async {
    final uri = Optica2Config.customerOrdersUri().replace(
      queryParameters: {
        'customer_id': '$customerId',
        'customer_phone': customerPhone,
      },
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? 'Could not load orders.',
        statusCode: response.statusCode,
      );
    }

    final orders = decoded['orders'];
    if (orders is! List) return const [];

    return orders
        .whereType<Map<String, dynamic>>()
        .map(CustomerOrder.fromJson)
        .toList();
  }

  Future<CustomerOrder> fetchOrder({
    required int orderId,
    required int customerId,
    required String customerPhone,
  }) async {
    final uri = Optica2Config.customerOrderUri(orderId).replace(
      queryParameters: {
        'customer_id': '$customerId',
        'customer_phone': customerPhone,
      },
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? 'Could not load order.',
        statusCode: response.statusCode,
      );
    }

    final orderJson = decoded['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not load order.');
    }

    return CustomerOrder.fromJson(orderJson);
  }

  Future<CustomerOrder> cancelOrder({
    required int orderId,
    required int customerId,
    required String customerPhone,
  }) async {
    final uri = Optica2Config.customerOrderCancelUri(orderId).replace(
      queryParameters: {
        'customer_id': '$customerId',
        'customer_phone': customerPhone,
      },
    );

    final body = await _postJsonDynamic(
      uri,
      const {},
      errorFallback: 'Could not cancel order.',
    );

    final orderJson = body['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not cancel order.');
    }

    return CustomerOrder.fromJson(orderJson);
  }

  Future<CustomerOrder> submitOrderReview({
    required int orderId,
    required int customerId,
    required String customerPhone,
    required List<Map<String, dynamic>> kitchenRatings,
    required List<Map<String, dynamic>> dishRatings,
  }) async {
    final body = await _postJsonDynamic(
      Optica2Config.customerOrderReviewUri(orderId),
      {
        'customer_id': customerId,
        'customer_phone': customerPhone,
        'kitchens': kitchenRatings,
        'dishes': dishRatings,
      },
      errorFallback: 'Could not submit review.',
    );

    final orderJson = body['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not submit review.');
    }

    return CustomerOrder.fromJson(orderJson);
  }

  Future<CustomerOrder> submitRefundRequest({
    required int orderId,
    required int customerId,
    required String customerPhone,
    required String description,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Optica2Config.customerOrderRefundRequestUri(orderId),
    )
      ..fields['customer_id'] = '$customerId'
      ..fields['customer_phone'] = customerPhone
      ..fields['description'] = description;

    if (imagePath != null && imagePath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 45));
    } catch (e) {
      await _failUnreachable(e);
    }

    final response = await http.Response.fromStream(streamed);
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (response.statusCode != 200 || body == null) {
      throw Optica2ApiException(
        body?['message'] as String? ?? 'Could not submit refund request.',
        statusCode: response.statusCode,
      );
    }

    final orderJson = body['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw Optica2ApiException('Could not submit refund request.');
    }

    return CustomerOrder.fromJson(orderJson);
  }

  Future<CustomerReviewsPayload> fetchDishReviews(
    int dishId, {
    int limit = 50,
  }) async {
    final uri = Optica2Config.customerDishReviewsUri(dishId).replace(
      queryParameters: {'limit': '$limit'},
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? 'Could not load reviews.',
        statusCode: response.statusCode,
      );
    }

    return CustomerReviewsPayload.fromJson(decoded);
  }

  Future<CustomerReviewsPayload> fetchKitchenReviews(
    int kitchenId, {
    int limit = 50,
  }) async {
    final uri = Optica2Config.customerKitchenReviewsUri(kitchenId).replace(
      queryParameters: {'limit': '$limit'},
    );

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _jsonHeaders())
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? 'Could not load reviews.',
        statusCode: response.statusCode,
      );
    }

    return CustomerReviewsPayload.fromJson(decoded);
  }

  Future<Map<String, dynamic>> _postJsonDynamic(
    Uri uri,
    Map<String, dynamic> body, {
    required String errorFallback,
  }) async {
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              ..._jsonHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded?['message'] as String?;
      throw Optica2ApiException(
        message ?? errorFallback,
        statusCode: response.statusCode,
      );
    }

    return decoded ?? const {};
  }

  Future<Map<String, dynamic>> _putJsonDynamic(
    Uri uri,
    Map<String, dynamic> body, {
    required String errorFallback,
  }) async {
    http.Response response;
    try {
      response = await _client
          .put(
            uri,
            headers: {
              ..._jsonHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded?['message'] as String?;
      throw Optica2ApiException(
        message ?? errorFallback,
        statusCode: response.statusCode,
      );
    }

    return decoded ?? const {};
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, String> body, {
    required String errorFallback,
  }) async {
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              ..._jsonHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded?['message'] as String?;
      final errors = decoded?['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final list = entry.value;
          if (list is List && list.isNotEmpty) {
            throw Optica2ApiException(
              list.first.toString(),
              statusCode: response.statusCode,
            );
          }
        }
      }
      throw Optica2ApiException(
        message ?? errorFallback,
        statusCode: response.statusCode,
      );
    }

    return decoded ?? const {};
  }

  Future<void> _postOtp(
    Uri uri,
    Map<String, String> body, {
    required String errorFallback,
  }) async {
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              ..._jsonHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      await _failUnreachable(e);
    }

    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) decoded = raw;
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Optica2ApiException(
        decoded?['message'] as String? ?? errorFallback,
        statusCode: response.statusCode,
      );
    }
  }

  Future<Never> _failUnreachable([Object? _]) async {
    await Optica2Config.tryRecoverHost();
    throw Optica2ApiException(Optica2Config.unreachableMessage());
  }

  Future<CustomerNotificationsResult> fetchNotifications({
    required int customerId,
    required String phoneE164,
  }) async {
    final decoded = await _postJsonDynamic(
      Optica2Config.customerNotificationsUri(),
      {
        'customer_id': customerId,
        'phone': phoneE164,
      },
      errorFallback: 'Could not load notifications.',
    );

    return CustomerNotificationsResult.fromJson(decoded);
  }

  Future<void> markNotificationRead({
    required int customerId,
    required String phoneE164,
    required int notificationId,
  }) async {
    await _postJsonDynamic(
      Optica2Config.customerNotificationsReadUri(),
      {
        'customer_id': customerId,
        'phone': phoneE164,
        'notification_id': notificationId,
      },
      errorFallback: 'Could not update notification.',
    );
  }

  /// Registers this device for order status push notifications.
  Future<bool> registerDeviceToken({
    required int customerId,
    required String phoneE164,
    required String fcmToken,
  }) async {
    try {
      final response = await _client
          .post(
            Optica2Config.customerDeviceTokenUri(),
            headers: {
              ..._jsonHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'customer_id': customerId,
              'phone': phoneE164,
              'fcm_token': fcmToken,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void close() => _client.close();
}
