import 'customer_delivery_quote.dart';

class CustomerGstConfig {
  const CustomerGstConfig({
    required this.enabled,
    required this.type,
    required this.value,
    required this.label,
  });

  final bool enabled;
  final String type;
  final double value;
  final String label;

  bool get isPercent => type == 'percent';

  bool get isFixed => type == 'fixed';

  double amountForSubtotal(double subtotal) {
    if (!enabled || value <= 0) return 0;
    if (isFixed) return value;
    return (subtotal * value / 100).clamp(0, double.infinity);
  }

  String labelForCheckout() {
    if (!enabled || value <= 0) return 'GST';
    if (isFixed) return 'GST';
    return 'GST ($label)';
  }

  factory CustomerGstConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CustomerGstConfig.empty;

    return CustomerGstConfig(
      enabled: CustomerPaymentConfig._readBool(json['enabled'], fallback: false),
      type: json['type'] as String? ?? 'percent',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      label: json['label'] as String? ?? '',
    );
  }

  static const empty = CustomerGstConfig(
    enabled: false,
    type: 'percent',
    value: 0,
    label: '',
  );
}

class CustomerAdvancePaymentConfig {
  const CustomerAdvancePaymentConfig({
    required this.enabled,
    required this.percent,
  });

  final bool enabled;
  final double percent;

  bool get isActive => enabled && percent >= 1 && percent <= 99;

  double amountForTotal(double total) {
    if (!isActive || total <= 0) return 0;
    return double.parse((total * percent / 100).toStringAsFixed(2));
  }

  double codBalanceForTotal(double total) {
    final rounded = double.parse(total.toStringAsFixed(2));
    final advance = amountForTotal(rounded);
    return double.parse((rounded - advance).clamp(0, double.infinity).toStringAsFixed(2));
  }

  String percentLabel() {
    if (percent % 1 == 0) return percent.toStringAsFixed(0);
    return percent.toStringAsFixed(1);
  }

  factory CustomerAdvancePaymentConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CustomerAdvancePaymentConfig.off;

    return CustomerAdvancePaymentConfig(
      enabled: CustomerPaymentConfig._readBool(json['enabled'], fallback: false),
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }

  static const off = CustomerAdvancePaymentConfig(
    enabled: false,
    percent: 0,
  );
}

class CustomerPaymentConfig {
  const CustomerPaymentConfig({
    required this.codEnabled,
    required this.walletEnabled,
    required this.walletTopupEnabled,
    required this.advance,
    required this.gst,
    required this.delivery,
    required this.razorpayEnabled,
    required this.razorpayKeyId,
    required this.razorpayConfigured,
    required this.stripeEnabled,
    required this.stripePublishableKey,
    required this.stripeConfigured,
    required this.cashfreeEnabled,
    required this.cashfreeConfigured,
    required this.cashfreeEnvironment,
  });

  final bool codEnabled;
  final bool walletEnabled;
  final bool walletTopupEnabled;
  final CustomerAdvancePaymentConfig advance;
  final CustomerGstConfig gst;
  final CustomerDeliveryConfig delivery;
  final bool razorpayEnabled;
  final String? razorpayKeyId;
  final bool razorpayConfigured;
  final bool stripeEnabled;
  final String? stripePublishableKey;
  final bool stripeConfigured;
  final bool cashfreeEnabled;
  final bool cashfreeConfigured;
  final String cashfreeEnvironment;

  bool get razorpayReady => razorpayEnabled && razorpayConfigured;

  bool get stripeReady => stripeEnabled && stripeConfigured;

  bool get cashfreeReady => cashfreeEnabled && cashfreeConfigured;

  bool get hasOnlinePayment =>
      razorpayReady || stripeReady || cashfreeReady;

  /// Partial pay applies when prepaid methods exist (online gateways or wallet).
  bool get advanceActive =>
      advance.isActive && (hasOnlinePayment || walletEnabled);

  static bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == '1' || normalized == 'true') return true;
      if (normalized == '0' || normalized == 'false') return false;
    }
    return fallback;
  }

  factory CustomerPaymentConfig.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    if (payment is! Map<String, dynamic>) {
      return CustomerPaymentConfig.fallback;
    }

    final cod = payment['cod'];
    final wallet = payment['wallet'];
    final advance = payment['advance'];
    final gst = payment['gst'];
    final delivery = payment['delivery'];
    final razorpay = payment['razorpay'];
    final stripe = payment['stripe'];
    final cashfree = payment['cashfree'];

    return CustomerPaymentConfig(
      codEnabled: cod is Map
          ? _readBool(cod['enabled'], fallback: true)
          : true,
      walletEnabled: wallet is Map
          ? _readBool(wallet['enabled'], fallback: false)
          : false,
      walletTopupEnabled: wallet is Map
          ? _readBool(wallet['topup_enabled'], fallback: false)
          : false,
      advance: advance is Map
          ? CustomerAdvancePaymentConfig.fromJson(
              Map<String, dynamic>.from(advance),
            )
          : CustomerAdvancePaymentConfig.off,
      gst: gst is Map
          ? CustomerGstConfig.fromJson(Map<String, dynamic>.from(gst))
          : CustomerGstConfig.empty,
      delivery: delivery is Map
          ? CustomerDeliveryConfig.fromJson(Map<String, dynamic>.from(delivery))
          : CustomerDeliveryConfig.empty,
      razorpayEnabled: razorpay is Map
          ? _readBool(razorpay['enabled'], fallback: false)
          : false,
      razorpayKeyId: razorpay is Map
          ? razorpay['key_id'] as String?
          : null,
      razorpayConfigured: razorpay is Map
          ? _readBool(razorpay['configured'], fallback: false)
          : false,
      stripeEnabled: stripe is Map
          ? _readBool(stripe['enabled'], fallback: false)
          : false,
      stripePublishableKey: stripe is Map
          ? stripe['publishable_key'] as String?
          : null,
      stripeConfigured: stripe is Map
          ? _readBool(stripe['configured'], fallback: false)
          : false,
      cashfreeEnabled: cashfree is Map
          ? _readBool(cashfree['enabled'], fallback: false)
          : false,
      cashfreeConfigured: cashfree is Map
          ? _readBool(cashfree['configured'], fallback: false)
          : false,
      cashfreeEnvironment: cashfree is Map
          ? (cashfree['environment'] as String? ?? 'sandbox')
          : 'sandbox',
    );
  }

  static const fallback = CustomerPaymentConfig(
    codEnabled: true,
    walletEnabled: false,
    walletTopupEnabled: false,
    advance: CustomerAdvancePaymentConfig.off,
    gst: CustomerGstConfig.empty,
    delivery: CustomerDeliveryConfig.empty,
    razorpayEnabled: false,
    razorpayKeyId: null,
    razorpayConfigured: false,
    stripeEnabled: false,
    stripePublishableKey: null,
    stripeConfigured: false,
    cashfreeEnabled: false,
    cashfreeConfigured: false,
    cashfreeEnvironment: 'sandbox',
  );
}

class RazorpayCheckoutOrder {
  const RazorpayCheckoutOrder({
    required this.id,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });

  final String id;
  final int amountPaise;
  final String currency;
  final String keyId;

  factory RazorpayCheckoutOrder.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    final orderMap = order is Map<String, dynamic> ? order : json;

    return RazorpayCheckoutOrder(
      id: orderMap['id'] as String? ?? '',
      amountPaise: (orderMap['amount'] as num?)?.toInt() ?? 0,
      currency: orderMap['currency'] as String? ?? 'INR',
      keyId: json['key_id'] as String? ?? '',
    );
  }
}

class StripeCheckoutIntent {
  const StripeCheckoutIntent({
    required this.id,
    required this.clientSecret,
    required this.amountPaise,
    required this.currency,
    required this.publishableKey,
  });

  final String id;
  final String clientSecret;
  final int amountPaise;
  final String currency;
  final String publishableKey;

  factory StripeCheckoutIntent.fromJson(Map<String, dynamic> json) {
    final intent = json['payment_intent'];
    final intentMap = intent is Map<String, dynamic> ? intent : json;

    return StripeCheckoutIntent(
      id: intentMap['id'] as String? ?? '',
      clientSecret: intentMap['client_secret'] as String? ?? '',
      amountPaise: (intentMap['amount'] as num?)?.toInt() ?? 0,
      currency: intentMap['currency'] as String? ?? 'inr',
      publishableKey: json['publishable_key'] as String? ?? '',
    );
  }
}

class CashfreeCheckoutOrder {
  const CashfreeCheckoutOrder({
    required this.orderId,
    required this.paymentSessionId,
    required this.amountRupees,
    required this.currency,
    required this.environment,
  });

  final String orderId;
  final String paymentSessionId;
  final double amountRupees;
  final String currency;
  final String environment;

  factory CashfreeCheckoutOrder.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    final orderMap = order is Map<String, dynamic> ? order : json;

    return CashfreeCheckoutOrder(
      orderId: orderMap['order_id'] as String? ?? '',
      paymentSessionId: orderMap['payment_session_id'] as String? ?? '',
      amountRupees: (orderMap['order_amount'] as num?)?.toDouble() ?? 0,
      currency: orderMap['order_currency'] as String? ?? 'INR',
      environment: orderMap['environment'] as String? ?? 'sandbox',
    );
  }
}
