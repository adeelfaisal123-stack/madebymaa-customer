import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../customer_location_prefs.dart';
import '../customer_session_prefs.dart';
import '../models/cart_line_item.dart';
import '../models/customer_delivery_quote.dart';
import '../models/customer_payment_config.dart';
import '../models/customer_wallet.dart';
import '../models/delivery_slot.dart';
import '../models/dish_main_category.dart';
import '../services/cashfree_checkout_service.dart';
import '../services/customer_cart_store.dart';
import '../services/customer_orders_store.dart';
import '../services/optica2_api.dart';
import '../services/payment_config_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_system_ui.dart';
import '../utils/optica2_asset_url.dart';
import '../widgets/app_toast.dart';
import '../widgets/delivery_location_sheet.dart';
import '../widgets/delivery_slot_selector.dart';
import '../widgets/floating_food_icons.dart';

/// Checkout with COD, wallet, Razorpay, Stripe, and Cashfree (admin-configured).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesController = TextEditingController();
  final _cart = CustomerCartStore.instance;
  final _api = Optica2Api();

  CustomerSavedLocation? _location;
  CustomerPaymentConfig _paymentConfig = CustomerPaymentConfig.fallback;
  CustomerDeliveryQuote? _deliveryQuote;
  CustomerWalletBalance? _walletBalance;
  Razorpay? _razorpay;
  var _loadingLocation = true;
  var _loadingDeliveryQuote = false;
  var _loadingPaymentConfig = true;
  var _loadingSlotCategories = true;
  var _loadingKitchenStatus = true;
  var _placing = false;
  var _allowDeliverNow = false;
  var _allKitchensOpen = true;
  var _instantDeliveryAvailable = false;
  var _paymentMethod = 'cod';
  DeliverySlotSelection _deliverySlot = const DeliverySlotSelection.now();
  List<DishMainCategory> _slotCategories = const [];

  /// Kitchen id → pre-order discount % by day key (`tomorrow` / `day_after`).
  final Map<int, Map<String, double>> _preorderDiscountsByKitchen = {};

  bool get _razorpayAvailable => _paymentConfig.razorpayReady;

  bool get _stripeAvailable => _paymentConfig.stripeReady;

  bool get _cashfreeAvailable => _paymentConfig.cashfreeReady;

  bool get _walletConfigured => _paymentConfig.walletEnabled;

  /// Prepaid charge (advance % when enabled, else full total).
  double get _prepaidChargeAmount =>
      _advanceActive ? _advanceAmount : _total;

  String get _prepaidChargeLabel =>
      '₹${_prepaidChargeAmount.toStringAsFixed(0)}';

  bool get _walletCanPay {
    if (!_walletConfigured) return false;
    final balance = _walletBalance?.balance ?? 0;
    return balance + 0.001 >= _prepaidChargeAmount;
  }

  String _defaultPaymentMethod(CustomerPaymentConfig config) {
    if (config.codEnabled) return 'cod';
    if (config.walletEnabled) return 'wallet';
    if (config.cashfreeReady) return 'cashfree';
    if (config.stripeReady) return 'stripe';
    if (config.razorpayReady) return 'razorpay';
    return 'cod';
  }

  Future<void> _ensureFreshPaymentConfig() async {
    final selected = _paymentMethod;
    PaymentConfigService.invalidate();
    await _loadPaymentConfig(preserveMethod: selected, forceRefresh: true);
  }

  Future<void> _configureStripe(String publishableKey) async {
    if (publishableKey.isEmpty) {
      throw Optica2ApiException('Stripe is not configured.');
    }

    Stripe.publishableKey = publishableKey;
    Stripe.urlScheme = 'madebymaa';
    await Stripe.instance.applySettings();
  }

  bool get _isOnlinePayment =>
      _paymentMethod == 'razorpay' ||
      _paymentMethod == 'stripe' ||
      _paymentMethod == 'cashfree';

  bool get _isPrepaidPayment =>
      _isOnlinePayment || _paymentMethod == 'wallet';

  @override
  void initState() {
    super.initState();
    _applyCachedKitchenDeliveryMeta();
    _loadLocation();
    _loadPaymentConfig();
    _loadWalletBalance();
    _loadSlotCategories();
    _loadKitchenOpenStatus();
  }

  Future<void> _loadWalletBalance() async {
    if (!_paymentConfig.walletEnabled && !_loadingPaymentConfig) return;
    final session = await CustomerSessionPrefs.load();
    if (session == null || !mounted) {
      if (mounted) setState(() => _walletBalance = null);
      return;
    }
    try {
      final snapshot = await _api.fetchWallet(
        customerId: session.id,
        customerPhone: session.phone,
      );
      if (!mounted) return;
      setState(() => _walletBalance = snapshot.wallet);
    } catch (_) {
      if (mounted) setState(() => _walletBalance = null);
    }
  }

  void _applyCachedKitchenDeliveryMeta() {
    final cachedInstant = _cart.kitchenInstantDeliveryEnabled;
    if (cachedInstant == null) return;
    _instantDeliveryAvailable = cachedInstant;
    _allowDeliverNow = cachedInstant;
    if (!cachedInstant) {
      _deliverySlot = _defaultScheduledSelection();
    }
  }

  void _applyDeliverNowAvailability({
    required bool allOpen,
    required bool instantAvailable,
  }) {
    _allKitchensOpen = allOpen;
    _instantDeliveryAvailable = instantAvailable;
    _allowDeliverNow = allOpen && instantAvailable;
    if (!_allowDeliverNow && _deliverySlot.isNow) {
      _deliverySlot = _defaultScheduledSelection();
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _api.close();
    _notesController.dispose();
    super.dispose();
  }

  void _initRazorpay() {
    _razorpay?.clear();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);
  }

  Future<void> _loadPaymentConfig({
    String? preserveMethod,
    bool forceRefresh = true,
  }) async {
    try {
      final config = await PaymentConfigService.ensureLoaded(
        api: _api,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final resolved = config ?? CustomerPaymentConfig.fallback;
      setState(() {
        _paymentConfig = resolved;
        _loadingPaymentConfig = false;
        _paymentMethod = preserveMethod ?? _defaultPaymentMethod(resolved);
      });
      if (resolved.walletEnabled) {
        unawaited(_loadWalletBalance());
      }
      if (resolved.stripeReady) {
        final key = resolved.stripePublishableKey;
        if (key != null && key.isNotEmpty) {
          unawaited(_configureStripe(key));
        }
      }
      if (resolved.razorpayReady) {
        _initRazorpay();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingPaymentConfig = false);
      }
    }
  }

  Future<void> _verifyStripePaymentWithRetry(String paymentIntentId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await _api.verifyStripePayment(paymentIntentId: paymentIntentId);
        return;
      } on Optica2ApiException catch (e) {
        final retryable = e.statusCode == 422 && attempt < 4;
        if (!retryable) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
  }

  String _stripeErrorMessage(Object error) {
    if (error is StripeException) {
      if (error.error.code == FailureCode.Canceled) {
        return 'Payment cancelled.';
      }
      return error.error.localizedMessage ??
          error.error.message ??
          'Payment failed. Try again or use COD.';
    }
    if (error is PlatformException) {
      return error.message ?? 'Stripe payment failed.';
    }
    if (error is Optica2ApiException) {
      return error.message;
    }
    return 'Could not complete online payment.';
  }

  Future<void> _loadSlotCategories() async {
    final fromCart = <int, DishMainCategory>{};
    for (final line in _cart.lines) {
      final category = line.mainCategory;
      if (category != null) {
        fromCart[category.id] = category;
      }
    }

    if (fromCart.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _slotCategories = fromCart.values.toList();
        _loadingSlotCategories = false;
        if (!_allowDeliverNow && _deliverySlot.isNow) {
          _deliverySlot = _defaultScheduledSelection();
        }
      });
      return;
    }

    try {
      final fetched = await _api.fetchSuperCategories();
      if (!mounted) return;
      setState(() {
        _slotCategories = fetched
            .map(
              (c) => DishMainCategory(
                id: c.id,
                name: c.name,
                timeRange: c.timeRange,
                slug: c.slug,
                startTime: c.startTime,
                endTime: c.endTime,
              ),
            )
            .where((c) => c.isValid)
            .toList();
        _loadingSlotCategories = false;
        if (!_allowDeliverNow && _deliverySlot.isNow) {
          _deliverySlot = _defaultScheduledSelection();
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSlotCategories = false);
    }
  }

  Future<void> _loadKitchenOpenStatus() async {
    final kitchenIds = _cart.lines.map((line) => line.kitchenId).toSet();

    if (kitchenIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingKitchenStatus = false;
        _applyDeliverNowAvailability(allOpen: true, instantAvailable: false);
      });
      return;
    }

    try {
      final details = await Future.wait(
        kitchenIds.map(_api.fetchKitchenDetail),
      );
      if (!mounted) return;

      final allOpen = details.every((detail) => detail.kitchen.isOpen);
      final allInstant = details.every(
        (detail) => detail.kitchen.instantDeliveryEnabled,
      );
      _preorderDiscountsByKitchen
        ..clear()
        ..addEntries(
          details.map((detail) {
            final kitchen = detail.kitchen;
            return MapEntry(kitchen.id, {
              for (final day in kitchen.upcomingDays)
                if (day.open &&
                    (day.slot == 'tomorrow' || day.slot == 'day_after') &&
                    day.preorderDiscountPercent > 0)
                  day.slot: day.preorderDiscountPercent,
            });
          }),
        );
      if (details.length == 1) {
        _cart.setKitchenInstantDeliveryEnabled(
          details.first.kitchen.instantDeliveryEnabled,
        );
      }
      setState(() {
        _loadingKitchenStatus = false;
        _applyDeliverNowAvailability(
          allOpen: allOpen,
          instantAvailable: allInstant,
        );
      });
    } catch (_) {
      if (!mounted) return;
      final cachedInstant = _cart.kitchenInstantDeliveryEnabled ?? false;
      setState(() {
        _loadingKitchenStatus = false;
        _applyDeliverNowAvailability(
          allOpen: _allKitchensOpen,
          instantAvailable: cachedInstant,
        );
      });
    }
  }

  DeliverySlotSelection _defaultScheduledSelection() {
    final dayKey = firstAvailableDeliveryDayKey(categories: _slotCategories) ??
        deliverySlotDayDefs.first.$1;
    return DeliverySlotSelection(
      isNow: false,
      dayKey: dayKey,
      displayLabel: deliveryDayLabel(dayKey),
    );
  }

  String? get _deliverNowNotice {
    if (_allowDeliverNow) return null;
    if (!_instantDeliveryAvailable && !_allKitchensOpen) {
      return 'Instant delivery isn\'t available and a kitchen in your cart is closed — schedule delivery for later.';
    }
    if (!_instantDeliveryAvailable) {
      return 'A kitchen in your cart only offers scheduled delivery — pick a day and time slot.';
    }
    return 'A kitchen in your cart is closed right now — schedule delivery for later.';
  }

  Future<void> _loadLocation() async {
    final saved = await CustomerLocationPrefs.load();
    if (!mounted) return;
    setState(() {
      _location = saved;
      _loadingLocation = false;
    });
    await _loadDeliveryQuote();
  }

  Future<void> _loadDeliveryQuote() async {
    final location = _location;
    if (location == null || _cart.lines.isEmpty) {
      if (!mounted) return;
      setState(() {
        _deliveryQuote = null;
        _loadingDeliveryQuote = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _loadingDeliveryQuote = true);
    }

    try {
      final quote = await _api.fetchDeliveryQuote(
        lines: _cart.lines,
        deliveryLatitude: location.latitude,
        deliveryLongitude: location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _deliveryQuote = quote;
        _loadingDeliveryQuote = false;
      });
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _deliveryQuote = null;
        _loadingDeliveryQuote = false;
      });
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _deliveryQuote = null;
        _loadingDeliveryQuote = false;
      });
    }
  }

  double get _subtotal => _cart.subtotal;

  /// Pre-order discount % for the selected tomorrow / day-after slot.
  double get _preorderDiscountPercent {
    if (_deliverySlot.isNow) return 0;
    final dayKey = _deliverySlot.dayKey;
    if (dayKey != 'tomorrow' && dayKey != 'day_after') return 0;
    final kitchenId = _cart.kitchenId;
    if (kitchenId == null) return 0;
    return _preorderDiscountsByKitchen[kitchenId]?[dayKey] ?? 0;
  }

  double get _preorderDiscountAmount {
    final percent = _preorderDiscountPercent;
    if (percent <= 0) return 0;
    return double.parse((_subtotal * percent / 100).toStringAsFixed(2));
  }

  double get _foodSubtotal =>
      double.parse((_subtotal - _preorderDiscountAmount).toStringAsFixed(2));

  double get _deliveryFee => _deliveryQuote?.deliveryFee ?? 0;

  String get _deliveryLabel =>
      _deliveryQuote?.checkoutLabel ?? 'Delivery';

  double get _gstAmount => _paymentConfig.gst.amountForSubtotal(_foodSubtotal);

  double get _total => _foodSubtotal + _deliveryFee + _gstAmount;

  String get _gstLabel => _paymentConfig.gst.labelForCheckout();

  String get _totalLabel => '₹${_total.toStringAsFixed(0)}';

  bool get _advanceActive => _paymentConfig.advanceActive;

  double get _advanceAmount =>
      _advanceActive ? _paymentConfig.advance.amountForTotal(_total) : 0;

  double get _codBalance =>
      _advanceActive ? _paymentConfig.advance.codBalanceForTotal(_total) : 0;

  /// Amount charged now (advance % when enabled) for prepaid methods.
  double get _chargeNow =>
      _isPrepaidPayment && _advanceActive ? _advanceAmount : _total;

  String get _chargeNowLabel => '₹${_chargeNow.toStringAsFixed(0)}';

  String get _advancePercentLabel => _paymentConfig.advance.percentLabel();

  String get _placeOrderLabel {
    if (_paymentMethod == 'wallet') {
      if (_advanceActive) {
        return 'Pay $_chargeNowLabel from wallet · place order';
      }
      return 'Pay with wallet · $_totalLabel';
    }
    if (!_isOnlinePayment) return 'Place order · $_totalLabel';
    if (_advanceActive) {
      return 'Pay $_chargeNowLabel now · place order';
    }
    return 'Pay & place order · $_totalLabel';
  }

  void _showError(String message) {
    AppToast.error(context, message);
  }

  bool _validateCheckout() {
    if (_location == null || _location!.address.trim().isEmpty) {
      _showError('Set your delivery location first.');
      return false;
    }

    if (_deliveryQuote == null) {
      _showError('Delivery fee is still loading. Try again in a moment.');
      return false;
    }

    if (_cart.lines.isEmpty) {
      Navigator.of(context).pop();
      return false;
    }

    if (!_deliverySlot.isNow && !_deliverySlot.isScheduledComplete) {
      _showError('Choose a day and 30-minute time slot.');
      return false;
    }

    if (!_allowDeliverNow && _deliverySlot.isNow) {
      _showError('Choose a scheduled delivery slot.');
      return false;
    }

    return true;
  }

  Future<void> _completeOrder({
    required String paymentMethod,
    String? paymentReference,
  }) async {
    try {
      final order = await CustomerOrdersStore.instance.placeOrder(
        api: _api,
        lines: _cart.lines,
        deliveryAddress: _location!.address,
        deliveryLatitude: _location!.latitude,
        deliveryLongitude: _location!.longitude,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        notes: _notesController.text,
        deliverySlot: _deliverySlot,
      );
      _cart.clear();

      if (!mounted) return;
      setState(() => _placing = false);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _OrderPlacedSheet(
          orderId: order.id,
          totalLabel: order.totalLabel,
          paymentMethod: paymentMethod,
          advanceAmount: order.advanceAmount,
          codBalance: order.codBalance,
          isPartialPayment: order.isPartialPayment,
          onDone: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      );
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError('Could not place order. Try again.');
    }
  }

  Future<void> _payWithRazorpay() async {
    setState(() => _placing = true);
    HapticFeedback.mediumImpact();

    try {
      await _ensureFreshPaymentConfig();
      if (!_razorpayAvailable) {
        throw Optica2ApiException('Razorpay is not available. Choose another method.');
      }

      final session = await CustomerSessionPrefs.load();
      final checkoutOrder = await _api.createRazorpayOrder(
        amountRupees: _chargeNow,
        receipt: 'MMA-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      final keyId = checkoutOrder.keyId.isNotEmpty
          ? checkoutOrder.keyId
          : (_paymentConfig.razorpayKeyId ?? '');

      if (checkoutOrder.id.isEmpty || keyId.isEmpty) {
        throw Optica2ApiException('Could not start online payment.');
      }

      _razorpay ??= Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onRazorpayExternalWallet);

      final options = <String, dynamic>{
        'key': keyId,
        'amount': checkoutOrder.amountPaise,
        'name': 'Made by Maa',
        'order_id': checkoutOrder.id,
        'description': 'Food order',
        'currency': checkoutOrder.currency,
        'theme': {'color': '#6221B3'},
      };

      if (session != null) {
        options['prefill'] = {
          'contact': session.phone,
          'name': session.name,
        };
      }

      _razorpay!.open(options);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError('Could not start online payment.');
    }
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    final orderId = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError('Payment response was incomplete.');
      return;
    }

    try {
      await _api.verifyRazorpayPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      if (!mounted) return;
      await _completeOrder(
        paymentMethod: 'razorpay',
        paymentReference: paymentId,
      );
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError('Payment verification failed.');
    }
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _placing = false);
    _showError(response.message ?? 'Payment failed. Try again or use COD.');
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _placing = false);
    _showError('External wallet: ${response.walletName ?? 'selected'}');
  }

  Future<void> _payWithStripe() async {
    setState(() => _placing = true);
    HapticFeedback.mediumImpact();

    try {
      await _ensureFreshPaymentConfig();
      if (!_stripeAvailable) {
        throw Optica2ApiException('Stripe is not available. Choose another method.');
      }

      final configKey = _paymentConfig.stripePublishableKey ?? '';
      if (configKey.isEmpty) {
        throw Optica2ApiException('Stripe is not configured.');
      }

      await _configureStripe(configKey);

      final intent = await _api.createStripePaymentIntent(amountRupees: _chargeNow);
      if (!mounted) return;

      if (intent.clientSecret.isEmpty || intent.id.isEmpty) {
        throw Optica2ApiException('Could not start online payment.');
      }

      final publishableKey = intent.publishableKey.isNotEmpty
          ? intent.publishableKey
          : configKey;
      if (publishableKey != Stripe.publishableKey) {
        await _configureStripe(publishableKey);
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          merchantDisplayName: 'Made by Maa',
          primaryButtonLabel: 'Pay $_chargeNowLabel',
          style: ThemeMode.system,
        ),
      );

      if (mounted) setState(() => _placing = false);
      await Stripe.instance.presentPaymentSheet();
      if (!mounted) return;

      setState(() => _placing = true);
      await _verifyStripePaymentWithRetry(intent.id);
      if (!mounted) return;

      await _completeOrder(
        paymentMethod: 'stripe',
        paymentReference: intent.id,
      );
    } catch (e, st) {
      debugPrint('Stripe checkout error: $e\n$st');
      if (!mounted) return;
      setState(() => _placing = false);
      _showError(_stripeErrorMessage(e));
    }
  }

  Future<void> _verifyCashfreePaymentWithRetry(String orderId) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await _api.verifyCashfreePayment(orderId: orderId);
        return;
      } on Optica2ApiException catch (e) {
        final retryable = e.statusCode == 422 && attempt < 4;
        if (!retryable) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
  }

  Future<void> _payWithCashfree() async {
    setState(() => _placing = true);
    HapticFeedback.mediumImpact();

    try {
      await _ensureFreshPaymentConfig();
      if (!_cashfreeAvailable) {
        throw Optica2ApiException('Cashfree is not available. Choose another method.');
      }

      final session = await CustomerSessionPrefs.load();
      final checkoutOrder = await _api.createCashfreeOrder(
        amountRupees: _chargeNow,
        orderId: 'MMA_cf_${DateTime.now().millisecondsSinceEpoch}',
        customerPhone: session?.phone,
      );

      if (!mounted) return;

      if (checkoutOrder.orderId.isEmpty ||
          checkoutOrder.paymentSessionId.isEmpty) {
        throw Optica2ApiException('Could not start online payment.');
      }

      final environment = _paymentConfig.cashfreeEnvironment.isNotEmpty
          ? _paymentConfig.cashfreeEnvironment
          : checkoutOrder.environment;

      final paidOrderId = await CashfreeCheckoutService.instance.startCheckout(
        CashfreeCheckoutOrder(
          orderId: checkoutOrder.orderId,
          paymentSessionId: checkoutOrder.paymentSessionId,
          amountRupees: checkoutOrder.amountRupees,
          currency: checkoutOrder.currency,
          environment: environment,
        ),
      );

      if (!mounted) return;

      await _verifyCashfreePaymentWithRetry(paidOrderId);
      if (!mounted) return;

      await _completeOrder(
        paymentMethod: 'cashfree',
        paymentReference: paidOrderId,
      );
    } on CashfreeCheckoutException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError(e.message);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placing = false);
      _showError('Could not complete online payment.');
    }
  }

  Future<void> _placeOrder() async {
    if (!_validateCheckout()) return;

    if (_paymentMethod == 'razorpay') {
      await _payWithRazorpay();
      return;
    }

    if (_paymentMethod == 'stripe') {
      await _payWithStripe();
      return;
    }

    if (_paymentMethod == 'cashfree') {
      await _payWithCashfree();
      return;
    }

    if (_paymentMethod == 'wallet') {
      if (!_walletCanPay) {
        _showError(
          _walletBalance == null
              ? 'Sign in and add funds to use wallet.'
              : 'Insufficient wallet balance. Need $_prepaidChargeLabel.',
        );
        return;
      }
      setState(() => _placing = true);
      HapticFeedback.mediumImpact();
      await _completeOrder(paymentMethod: 'wallet');
      return;
    }

    setState(() => _placing = true);
    HapticFeedback.mediumImpact();
    await _completeOrder(paymentMethod: 'cod');
  }

  @override
  Widget build(BuildContext context) {
    final lines = _cart.lines;
    final grouped = _groupByKitchen(lines);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.deepGreen),
          ),
          title: Text(
            'Checkout',
            style: GoogleFonts.exo2(
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: FloatingFoodIcons(
                opacity: 0.10,
                count: 26,
                minSize: 18,
                maxSize: 32,
                seed: 71,
                entrance: false,
              ),
            ),
            lines.isEmpty
                ? _EmptyCheckout(onBack: () => Navigator.of(context).pop())
                : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      children: [
                        _SectionTitle(
                          icon: Icons.location_on_rounded,
                          label: 'Deliver to',
                        ),
                        const SizedBox(height: 10),
                        _AddressCard(
                          loading: _loadingLocation,
                          title: _location != null &&
                                  _location!.label.trim().isNotEmpty
                              ? _location!.displayLabel
                              : null,
                          address: _location?.address,
                          onChangeLocation: () async {
                            await DeliveryLocationSheet.show(context);
                            await _loadLocation();
                          },
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          icon: Icons.schedule_rounded,
                          label: 'Delivery slot',
                        ),
                        const SizedBox(height: 10),
                        if (_loadingSlotCategories || _loadingKitchenStatus)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandPurple,
                              ),
                            ),
                          )
                        else ...[
                          if (_deliverNowNotice != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.brandPurple
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.brandPurple
                                        .withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 18,
                                        color: AppColors.brandPurple
                                            .withValues(alpha: 0.85),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _deliverNowNotice!,
                                          style: GoogleFonts.exo2(
                                            fontSize: 13,
                                            height: 1.4,
                                            color: AppColors.deepGreen
                                                .withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          DeliverySlotSelector(
                            categories: _slotCategories,
                            selected: _deliverySlot,
                            allowDeliverNow: _allowDeliverNow,
                            onSelected: (slot) =>
                                setState(() => _deliverySlot = slot),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _SectionTitle(
                          icon: Icons.receipt_long_rounded,
                          label: 'Order summary',
                        ),
                        const SizedBox(height: 10),
                        for (final entry in grouped.entries) ...[
                          _KitchenGroup(
                            kitchenName: entry.key,
                            lines: entry.value,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _PriceRow(
                          label: 'Subtotal',
                          value: _cart.subtotalLabel,
                        ),
                        if (_preorderDiscountAmount > 0) ...[
                          const SizedBox(height: 8),
                          _PriceRow(
                            label:
                                'Pre-order discount (${_preorderDiscountPercent.toStringAsFixed(_preorderDiscountPercent % 1 == 0 ? 0 : 1)}%)',
                            value:
                                '−₹${_preorderDiscountAmount.toStringAsFixed(0)}',
                            emphasize: true,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _PriceRow(
                          label: _deliveryLabel,
                          value: _loadingDeliveryQuote
                              ? 'Calculating…'
                              : '₹${_deliveryFee.toStringAsFixed(0)}',
                        ),
                        if (_gstAmount > 0) ...[
                          const SizedBox(height: 8),
                          _PriceRow(
                            label: _gstLabel,
                            value: '₹${_gstAmount.toStringAsFixed(0)}',
                          ),
                        ],
                        if (_isPrepaidPayment && _advanceActive) ...[
                          const SizedBox(height: 8),
                          _PriceRow(
                            label: 'Pay now ($_advancePercentLabel%)',
                            value: _chargeNowLabel,
                            emphasize: true,
                          ),
                          const SizedBox(height: 8),
                          _PriceRow(
                            label: 'Pay on delivery (COD)',
                            value: '₹${_codBalance.toStringAsFixed(0)}',
                          ),
                        ],
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.brandPurple.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.exo2(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepGreen,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _totalLabel,
                                style: GoogleFonts.exo2(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle(
                          icon: Icons.payments_rounded,
                          label: 'Payment',
                        ),
                        const SizedBox(height: 10),
                        if (_loadingPaymentConfig)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandPurple,
                              ),
                            ),
                          )
                        else ...[
                          if (_paymentConfig.advance.isActive &&
                              !_paymentConfig.hasOnlinePayment)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Partial payment is on in admin, but no online payment method is available. Enable Razorpay, Stripe, or Cashfree.',
                                style: GoogleFonts.exo2(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: AppColors.deepGreen.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          if (_paymentConfig.codEnabled)
                            _PaymentMethodTile(
                              selected: _paymentMethod == 'cod',
                              onTap: () => setState(() => _paymentMethod = 'cod'),
                              icon: Icons.payments_rounded,
                              iconColor: AppColors.sage,
                              title: 'Cash on delivery',
                              subtitle: 'Pay full amount when your order arrives',
                            ),
                          if (_walletConfigured) ...[
                            if (_paymentConfig.codEnabled) const SizedBox(height: 10),
                            _PaymentMethodTile(
                              selected: _paymentMethod == 'wallet',
                              onTap: _walletCanPay
                                  ? () => setState(() => _paymentMethod = 'wallet')
                                  : () => _showError(
                                        _walletBalance == null
                                            ? 'Sign in to pay with wallet.'
                                            : 'Need $_prepaidChargeLabel in wallet. Add funds from Profile → Wallet.',
                                      ),
                              icon: Icons.account_balance_wallet_rounded,
                              iconColor: AppColors.brandPurple,
                              title: _advanceActive
                                  ? 'Pay $_advancePercentLabel% with wallet'
                                  : 'Pay with wallet',
                              subtitle: _walletCanPay
                                  ? (_advanceActive
                                      ? '$_prepaidChargeLabel from balance · rest COD'
                                      : 'Balance ${_walletBalance?.balanceLabel ?? '₹0'}')
                                  : (_walletBalance == null
                                      ? 'Sign in to use wallet'
                                      : 'Low balance · need $_prepaidChargeLabel'),
                            ),
                          ],
                          if (_razorpayAvailable) ...[
                            if (_paymentConfig.codEnabled || _walletConfigured)
                              const SizedBox(height: 10),
                            _PaymentMethodTile(
                              selected: _paymentMethod == 'razorpay',
                              onTap: () =>
                                  setState(() => _paymentMethod = 'razorpay'),
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.brandPurple,
                              title: _advanceActive
                                  ? 'Pay $_advancePercentLabel% with Razorpay'
                                  : 'Pay with Razorpay',
                              subtitle: _advanceActive
                                  ? '$_prepaidChargeLabel now · rest COD on delivery'
                                  : 'UPI, cards & wallets via Razorpay',
                            ),
                          ],
                          if (_stripeAvailable) ...[
                            if (_paymentConfig.codEnabled ||
                                _walletConfigured ||
                                _razorpayAvailable ||
                                _cashfreeAvailable)
                              const SizedBox(height: 10),
                            _PaymentMethodTile(
                              selected: _paymentMethod == 'stripe',
                              onTap: () =>
                                  setState(() => _paymentMethod = 'stripe'),
                              icon: Icons.credit_card_rounded,
                              iconColor: const Color(0xFF635BFF),
                              title: _advanceActive
                                  ? 'Pay $_advancePercentLabel% with Stripe'
                                  : 'Pay with Stripe',
                              subtitle: _advanceActive
                                  ? '$_prepaidChargeLabel now · rest COD on delivery'
                                  : 'Cards and wallets via Stripe',
                            ),
                          ],
                          if (_cashfreeAvailable) ...[
                            if (_paymentConfig.codEnabled ||
                                _walletConfigured ||
                                _razorpayAvailable ||
                                _stripeAvailable)
                              const SizedBox(height: 10),
                            _PaymentMethodTile(
                              selected: _paymentMethod == 'cashfree',
                              onTap: () =>
                                  setState(() => _paymentMethod = 'cashfree'),
                              icon: Icons.account_balance_outlined,
                              iconColor: AppColors.brandPurple,
                              title: _advanceActive
                                  ? 'Pay $_advancePercentLabel% with Cashfree'
                                  : 'Pay with Cashfree',
                              subtitle: _advanceActive
                                  ? '$_prepaidChargeLabel now · rest COD on delivery'
                                  : 'UPI, cards & wallets via Cashfree',
                            ),
                          ],
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Order notes (optional)',
                          style: GoogleFonts.exo2(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepGreen.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: GoogleFonts.exo2(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Gate code, landmark, allergies…',
                            hintStyle: GoogleFonts.exo2(
                              color: AppColors.deepGreen.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.brandPurple.withValues(alpha: 0.15),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.brandPurple.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PlaceOrderBar(
                    actionLabel: _placeOrderLabel,
                    placing: _placing,
                    onPlace: _placeOrder,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Map<String, List<CartLineItem>> _groupByKitchen(List<CartLineItem> lines) {
    final map = <String, List<CartLineItem>>{};
    for (final line in lines) {
      map.putIfAbsent(line.kitchenName, () => []).add(line);
    }
    return map;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brandPurple),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.deepGreen,
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.loading,
    this.title,
    required this.address,
    required this.onChangeLocation,
  });

  final bool loading;
  final String? title;
  final String? address;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            color: AppColors.brandPurple.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: loading
          ? const SizedBox(
              height: 40,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandPurple,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.sage.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: AppColors.sage,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null && title!.trim().isNotEmpty)
                            Text(
                              title!,
                              style: GoogleFonts.exo2(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepGreen,
                              ),
                            ),
                          if (title != null && title!.trim().isNotEmpty)
                            const SizedBox(height: 4),
                          Text(
                            address != null && address!.trim().isNotEmpty
                                ? address!
                                : 'No delivery address saved',
                            style: GoogleFonts.exo2(
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepGreen.withValues(
                                alpha: title != null && title!.trim().isNotEmpty
                                    ? 0.75
                                    : 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onChangeLocation,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    'Change address',
                    style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandPurple,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
    );
  }
}

class _KitchenGroup extends StatelessWidget {
  const _KitchenGroup({required this.kitchenName, required this.lines});

  final String kitchenName;
  final List<CartLineItem> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: AppColors.sage),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  kitchenName,
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in lines) ...[
            _SummaryLine(line: line),
            if (line != lines.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.line});

  final CartLineItem line;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveOptica2AssetUrl(line.imageUrl);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : ColoredBox(
                    color: AppColors.brandPurple.withValues(alpha: 0.08),
                    child: const Icon(Icons.restaurant_rounded, size: 20),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.dishName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepGreen,
                ),
              ),
              Text(
                '×${line.quantity}',
                style: GoogleFonts.exo2(
                  fontSize: 12,
                  color: AppColors.deepGreen.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Text(
          line.lineTotalLabel,
          style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.brandPurple,
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? AppColors.terracotta : AppColors.deepGreen;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 14,
              color: color.withValues(alpha: emphasize ? 0.9 : 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.exo2(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected
                  ? AppColors.brandPurple
                  : AppColors.brandPurple.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.exo2(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.exo2(
                        fontSize: 12,
                        color: AppColors.deepGreen.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? AppColors.brandPurple
                    : AppColors.deepGreen.withValues(alpha: 0.25),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.actionLabel,
    required this.placing,
    required this.onPlace,
  });

  final String actionLabel;
  final bool placing;
  final VoidCallback onPlace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, -4),
            color: AppColors.brandPurple.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: placing ? null : onPlace,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              disabledBackgroundColor:
                  AppColors.brandPurple.withValues(alpha: 0.72),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 68),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: const RoundedRectangleBorder(),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (placing) ...[
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    placing ? 'Processing payment…' : actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderPlacedSheet extends StatelessWidget {
  const _OrderPlacedSheet({
    required this.orderId,
    required this.totalLabel,
    required this.paymentMethod,
    this.advanceAmount,
    this.codBalance,
    this.isPartialPayment = false,
    required this.onDone,
  });

  final String orderId;
  final String totalLabel;
  final String paymentMethod;
  final double? advanceAmount;
  final double? codBalance;
  final bool isPartialPayment;
  final VoidCallback onDone;

  String get _successMessage {
    if (paymentMethod == 'cod') {
      return 'Pay $totalLabel in cash when your food arrives.';
    }
    if (isPartialPayment) {
      final paid = '₹${(advanceAmount ?? 0).toStringAsFixed(0)}';
      final due = '₹${(codBalance ?? 0).toStringAsFixed(0)}';
      final via = paymentMethod == 'wallet' ? 'from wallet' : 'online';
      return '$paid paid $via. Pay $due COD when your food arrives.';
    }
    if (paymentMethod == 'wallet') {
      return 'Paid $totalLabel from your wallet.';
    }
    if (paymentMethod == 'stripe') {
      return 'Payment of $totalLabel received via Stripe.';
    }
    if (paymentMethod == 'cashfree') {
      return 'Payment of $totalLabel received via Cashfree.';
    }
    return 'Payment of $totalLabel received via Razorpay.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.sage.withValues(alpha: 0.25),
                      AppColors.brandPurple.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: AppColors.sage,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Order placed!',
                style: GoogleFonts.exo2(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _successMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.deepGreen.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order $orderId',
                style: GoogleFonts.exo2(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPurple,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.exo2(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Your cart is empty',
            style: GoogleFonts.exo2(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onBack, child: const Text('Go back')),
        ],
      ),
    );
  }
}
