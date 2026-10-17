import 'dart:io' show HttpClient, Platform;

import 'package:flutter/foundation.dart';

import '../optica2_api_prefs.dart';
import 'optica2_host.g.dart';

/// Optica2 backend connection.
abstract final class Optica2Config {
  static const _port = 8000;
  static const _envUrl = String.fromEnvironment('OPTICA2_API_URL');
  static const _useEmulatorHost = bool.fromEnvironment(
    'OPTICA2_USE_EMULATOR_HOST',
    defaultValue: false,
  );

  static String? _resolvedBaseUrl;

  /// Call once at startup (see [main.dart]).
  static Future<void> initialize() async {
    await refresh();
  }

  /// Re-probe the API host before sign-in or after connectivity changes.
  static Future<void> refresh() async {
    final url = await _resolveReachableBaseUrl();
    final reachable = await _probe(url);
    _resolvedBaseUrl = url;

    if (reachable) {
      final changed = await Optica2ApiPrefs.saveBaseUrlIfChanged(url);
      if (kDebugMode) {
        debugPrint('Optica2 API → $url');
        if (changed) {
          debugPrint('Optica2 API URL changed.');
        }
      }
      return;
    }

    await Optica2ApiPrefs.clearSavedBaseUrl();
    if (kDebugMode) {
      debugPrint(
        'Optica2 API not reachable at $url. '
        'See unreachableMessage() hints.',
      );
    }
  }

  /// On connection failure, re-probe dev hosts (LAN IP vs adb reverse).
  static Future<bool> tryRecoverHost() async {
    final previous = baseUrl;
    final url = await _resolveReachableBaseUrl();
    final reachable = await _probe(url);
    _resolvedBaseUrl = url;

    if (reachable) {
      await Optica2ApiPrefs.saveBaseUrlIfChanged(url);
      if (kDebugMode && url != previous) {
        debugPrint('Optica2 API recovered → $url');
      }
      return true;
    }

    await Optica2ApiPrefs.clearSavedBaseUrl();
    return false;
  }

  static String unreachableMessage() {
    return 'Cannot reach the API at $baseUrl.\n\n'
        '• Backend running: php artisan serve --host=0.0.0.0 --port=$_port\n'
        '• Phone on USB or wireless adb: adb reverse tcp:8000 tcp:8000\n'
        '  then hot restart the app (capital R in flutter run)\n'
        '• Same Wi‑Fi only: dart run tool/sync_optica2_host.dart\n'
        '  (some routers block phone→Mac; use adb reverse instead)';
  }

  static String get baseUrl => _resolvedBaseUrl ?? _computeBaseUrl();

  static Future<String> _resolveReachableBaseUrl() async {
    final candidates = <String>[];
    void add(String url) {
      final normalized = _normalizeBaseUrl(url);
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    if (_envUrl.isNotEmpty) add(_envUrl);

    // Physical Android over USB / wireless adb: `adb reverse` maps device
    // localhost → Mac :8000. Try this before LAN IP (often blocked by router AP isolation).
    if (kDebugMode && !kIsWeb && Platform.isAndroid) {
      add('http://127.0.0.1:$_port');
      if (_useEmulatorHost) add('http://10.0.2.2:$_port');
    }

    final computed = _normalizeBaseUrl(_computeBaseUrl());
    add(computed);

    final saved = await Optica2ApiPrefs.lastBaseUrl();
    if (saved != null &&
        saved.isNotEmpty &&
        saved != computed &&
        _isLocalDevUrl(saved)) {
      add(saved);
    }

    for (final url in candidates) {
      if (await _probe(url)) return url;
    }

    return computed;
  }

  static bool _isLocalDevUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host == '127.0.0.1') return true;
    if (host.startsWith('192.168.')) return true;
    if (host == '10.0.2.2') return true;
    return false;
  }

  static Duration get _probeTimeout {
    if (kDebugMode && !kIsWeb && Platform.isAndroid) {
      return const Duration(seconds: 8);
    }
    return const Duration(seconds: 4);
  }

  static Future<bool> _probe(String baseUrl) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = _probeTimeout;
      final uri = Uri.parse('$baseUrl/api/customer/home-sliders');
      final request = await client.getUrl(uri);
      final response = await request.close();
      await response.drain();
      client.close();
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _computeBaseUrl() {
    if (_envUrl.isNotEmpty) return _normalizeBaseUrl(_envUrl);

    if (kIsWeb) {
      return 'http://localhost:$_port';
    }

    if (!kIsWeb && Platform.isAndroid && _useEmulatorHost) {
      return 'http://10.0.2.2:$_port';
    }

    final configured = _normalizeBaseUrl(Optica2Host.apiUrl);
    if (configured.isNotEmpty) return configured;

    return 'http://localhost:$_port';
  }

  static String _normalizeBaseUrl(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// Optional — must match Optica2 `SELLER_API_KEY` when set.
  static const apiKey = String.fromEnvironment(
    'OPTICA2_API_KEY',
    defaultValue: '',
  );

  static Uri otpConfigUri() => Uri.parse('$baseUrl/api/otp/config');

  static Uri otpSendUri() => Uri.parse('$baseUrl/api/otp/send');

  static Uri otpVerifyUri() => Uri.parse('$baseUrl/api/otp/verify');

  static Uri sellerMapsConfigUri() =>
      Uri.parse('$baseUrl/api/seller/maps-config');

  static Uri customerStartupPopupUri() =>
      Uri.parse('$baseUrl/api/customer/startup-popup');

  static Uri customerHomeSlidersUri() =>
      Uri.parse('$baseUrl/api/customer/home-sliders');

  static Uri customerSuperCategoriesUri() =>
      Uri.parse('$baseUrl/api/customer/super-categories');

  static Uri customerCuisinesUri() =>
      Uri.parse('$baseUrl/api/customer/cuisines');

  static Uri customerDishCategoriesUri() =>
      Uri.parse('$baseUrl/api/customer/dish-categories');

  static Uri customerFeaturedKitchensUri() =>
      Uri.parse('$baseUrl/api/customer/featured-kitchens');

  static Uri customerFeaturedDishesUri() =>
      Uri.parse('$baseUrl/api/customer/featured-dishes');

  static Uri customerBrowseDishesUri({
    int? superCategoryId,
    int? cuisineId,
    int? dishCategoryId,
  }) {
    final params = <String, String>{};
    if (superCategoryId != null) {
      params['super_category_id'] = '$superCategoryId';
    }
    if (cuisineId != null && cuisineId > 0) {
      params['cuisine_id'] = '$cuisineId';
    }
    if (dishCategoryId != null && dishCategoryId > 0) {
      params['dish_category_id'] = '$dishCategoryId';
    }
    final base = Uri.parse('$baseUrl/api/customer/dishes');
    if (params.isEmpty) return base;
    return base.replace(queryParameters: params);
  }

  static Uri customerBrowseKitchensUri({
    double? latitude,
    double? longitude,
  }) {
    final base = Uri.parse('$baseUrl/api/customer/kitchens');
    if (latitude != null && longitude != null) {
      return base.replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
        },
      );
    }
    return base;
  }

  static Uri customerKitchenUri(int kitchenId) =>
      Uri.parse('$baseUrl/api/customer/kitchens/$kitchenId');

  static Uri customerAuthCheckPhoneUri() =>
      Uri.parse('$baseUrl/api/customer/auth/check-phone');

  static Uri customerAuthVerifyLoginUri() =>
      Uri.parse('$baseUrl/api/customer/auth/verify-and-login');

  static Uri customerAuthCompleteSessionUri() =>
      Uri.parse('$baseUrl/api/customer/auth/complete-session');

  static Uri customerPaymentConfigUri() =>
      Uri.parse('$baseUrl/api/customer/payment-config');

  static Uri customerRazorpayOrderUri() =>
      Uri.parse('$baseUrl/api/customer/payments/razorpay/order');

  static Uri customerRazorpayVerifyUri() =>
      Uri.parse('$baseUrl/api/customer/payments/razorpay/verify');

  static Uri customerStripeIntentUri() =>
      Uri.parse('$baseUrl/api/customer/payments/stripe/intent');

  static Uri customerStripeVerifyUri() =>
      Uri.parse('$baseUrl/api/customer/payments/stripe/verify');

  static Uri customerCashfreeOrderUri() =>
      Uri.parse('$baseUrl/api/customer/payments/cashfree/order');

  static Uri customerCashfreeVerifyUri() =>
      Uri.parse('$baseUrl/api/customer/payments/cashfree/verify');

  static Uri customerOrdersUri() => Uri.parse('$baseUrl/api/customer/orders');

  static Uri customerDeliveryQuoteUri() =>
      Uri.parse('$baseUrl/api/customer/orders/delivery-quote');

  static Uri customerOrderUri(int orderId) =>
      Uri.parse('$baseUrl/api/customer/orders/$orderId');

  static Uri customerOrderCancelUri(int orderId) =>
      Uri.parse('$baseUrl/api/customer/orders/$orderId/cancel');

  static Uri customerOrderReviewUri(int orderId) =>
      Uri.parse('$baseUrl/api/customer/orders/$orderId/review');

  static Uri customerOrderRefundRequestUri(int orderId) =>
      Uri.parse('$baseUrl/api/customer/orders/$orderId/refund-request');

  static Uri customerKitchenReviewsUri(int kitchenId) =>
      Uri.parse('$baseUrl/api/customer/kitchens/$kitchenId/reviews');

  static Uri customerDishReviewsUri(int dishId) =>
      Uri.parse('$baseUrl/api/customer/dishes/$dishId/reviews');

  static Uri customerDeviceTokenUri() =>
      Uri.parse('$baseUrl/api/customer/device-token');

  static Uri customerNotificationsUri() =>
      Uri.parse('$baseUrl/api/customer/notifications');

  static Uri customerNotificationsReadUri() =>
      Uri.parse('$baseUrl/api/customer/notifications/read');

  static Uri customerProfileUri() => Uri.parse('$baseUrl/api/customer/profile');

  static Uri customerWalletUri() => Uri.parse('$baseUrl/api/customer/wallet');

  static Uri customerWalletTopupUri() =>
      Uri.parse('$baseUrl/api/customer/wallet/topup');
}
