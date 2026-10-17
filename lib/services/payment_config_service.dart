import '../models/customer_payment_config.dart';
import 'optica2_api.dart';

/// Cached payment gateway config from admin (COD / Razorpay / Stripe keys).
abstract final class PaymentConfigService {
  static CustomerPaymentConfig? _cached;

  static void invalidate() => _cached = null;

  static CustomerPaymentConfig? get cached => _cached;

  /// Loads `/api/customer/payment-config`. Returns null when the API cannot be reached.
  static Future<CustomerPaymentConfig?> ensureLoaded({
    Optica2Api? api,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null) return _cached;

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      final loaded = await client.fetchPaymentConfig();
      _cached = loaded;
      return loaded;
    } catch (_) {
      return _cached;
    } finally {
      if (ownsClient) client.close();
    }
  }
}
