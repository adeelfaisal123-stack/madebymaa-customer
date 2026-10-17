import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../customer_session_prefs.dart';
import '../models/customer_payment_config.dart';
import '../services/cashfree_checkout_service.dart';
import '../services/optica2_api.dart';
import '../services/payment_config_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_system_ui.dart';
import '../widgets/app_toast.dart';
import '../widgets/profile_info_scaffold.dart';

/// Add funds to customer wallet via admin-enabled online gateways.
class WalletTopupScreen extends StatefulWidget {
  const WalletTopupScreen({super.key});

  @override
  State<WalletTopupScreen> createState() => _WalletTopupScreenState();
}

class _WalletTopupScreenState extends State<WalletTopupScreen> {
  static const _presets = [100.0, 200.0, 500.0, 1000.0];

  final _api = Optica2Api();
  final _amountController = TextEditingController(text: '200');
  CustomerPaymentConfig _paymentConfig = CustomerPaymentConfig.fallback;
  Razorpay? _razorpay;
  var _loading = true;
  var _paying = false;
  var _paymentMethod = 'razorpay';
  double? _pendingAmount;

  bool get _razorpayAvailable => _paymentConfig.razorpayReady;
  bool get _stripeAvailable => _paymentConfig.stripeReady;
  bool get _cashfreeAvailable => _paymentConfig.cashfreeReady;
  bool get _canTopup =>
      _paymentConfig.walletTopupEnabled &&
      (_razorpayAvailable || _stripeAvailable || _cashfreeAvailable);

  double get _amount {
    final parsed = double.tryParse(_amountController.text.trim());
    return parsed ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _amountController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await PaymentConfigService.ensureLoaded(
        api: _api,
        forceRefresh: true,
      );
      if (!mounted) return;
      final resolved = config ?? CustomerPaymentConfig.fallback;
      setState(() {
        _paymentConfig = resolved;
        _loading = false;
        _paymentMethod = _defaultMethod(resolved);
      });
      if (resolved.razorpayReady) _initRazorpay();
      if (resolved.stripeReady) {
        final key = resolved.stripePublishableKey;
        if (key != null && key.isNotEmpty) {
          Stripe.publishableKey = key;
          Stripe.urlScheme = 'madebymaa';
          unawaited(Stripe.instance.applySettings());
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _defaultMethod(CustomerPaymentConfig config) {
    if (config.razorpayReady) return 'razorpay';
    if (config.cashfreeReady) return 'cashfree';
    if (config.stripeReady) return 'stripe';
    return 'razorpay';
  }

  void _initRazorpay() {
    _razorpay?.clear();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
  }

  void _showError(String message) => AppToast.error(context, message);

  Future<void> _startTopup() async {
    if (!_canTopup) {
      _showError('Wallet top-up is not available right now.');
      return;
    }
    if (_amount < 1) {
      _showError('Enter at least ₹1.');
      return;
    }

    setState(() {
      _paying = true;
      _pendingAmount = _amount;
    });
    HapticFeedback.mediumImpact();

    try {
      if (_paymentMethod == 'razorpay') {
        await _payRazorpay(_amount);
      } else if (_paymentMethod == 'stripe') {
        await _payStripe(_amount);
      } else if (_paymentMethod == 'cashfree') {
        await _payCashfree(_amount);
      }
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError('Could not start payment.');
    }
  }

  Future<void> _payRazorpay(double amount) async {
    final checkoutOrder = await _api.createRazorpayOrder(amountRupees: amount);
    final keyId = checkoutOrder.keyId.isNotEmpty
        ? checkoutOrder.keyId
        : (_paymentConfig.razorpayKeyId ?? '');
    if (keyId.isEmpty || checkoutOrder.id.isEmpty) {
      throw Optica2ApiException('Could not start online payment.');
    }
    _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
    _razorpay!.open({
      'key': keyId,
      'amount': checkoutOrder.amountPaise,
      'currency': checkoutOrder.currency,
      'name': 'Made by Maa',
      'description': 'Wallet top-up',
      'order_id': checkoutOrder.id,
      'prefill': <String, String>{},
    });
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    final orderId = response.orderId ?? '';
    final signature = response.signature ?? '';
    if (orderId.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError('Payment incomplete. Try again.');
      return;
    }
    try {
      await _api.verifyRazorpayPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      await _finishTopup(
        paymentMethod: 'razorpay',
        paymentReference: paymentId,
      );
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError(e.message);
    }
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _paying = false);
    _showError(response.message ?? 'Payment failed.');
  }

  Future<void> _payStripe(double amount) async {
    final key = _paymentConfig.stripePublishableKey ?? '';
    if (key.isEmpty) throw Optica2ApiException('Stripe is not configured.');
    Stripe.publishableKey = key;
    Stripe.urlScheme = 'madebymaa';
    await Stripe.instance.applySettings();

    final intent = await _api.createStripePaymentIntent(amountRupees: amount);
    if (intent.clientSecret.isEmpty || intent.id.isEmpty) {
      throw Optica2ApiException('Could not start online payment.');
    }

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent.clientSecret,
        merchantDisplayName: 'Made by Maa',
        primaryButtonLabel: 'Add ₹${amount.toStringAsFixed(0)}',
        style: ThemeMode.system,
      ),
    );

    if (mounted) setState(() => _paying = false);
    await Stripe.instance.presentPaymentSheet();
    if (!mounted) return;
    setState(() => _paying = true);

    await _api.verifyStripePayment(paymentIntentId: intent.id);
    await _finishTopup(paymentMethod: 'stripe', paymentReference: intent.id);
  }

  Future<void> _payCashfree(double amount) async {
    final session = await CustomerSessionPrefs.load();
    final checkoutOrder = await _api.createCashfreeOrder(
      amountRupees: amount,
      customerPhone: session?.phone,
    );
    if (checkoutOrder.orderId.isEmpty ||
        checkoutOrder.paymentSessionId.isEmpty) {
      throw Optica2ApiException('Could not start online payment.');
    }

    final environment = _paymentConfig.cashfreeEnvironment.isNotEmpty
        ? _paymentConfig.cashfreeEnvironment
        : checkoutOrder.environment;

    if (mounted) setState(() => _paying = false);
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
    setState(() => _paying = true);

    await _api.verifyCashfreePayment(orderId: paidOrderId);
    await _finishTopup(
      paymentMethod: 'cashfree',
      paymentReference: paidOrderId,
    );
  }

  Future<void> _finishTopup({
    required String paymentMethod,
    required String paymentReference,
  }) async {
    final session = await CustomerSessionPrefs.load();
    final amount = _pendingAmount ?? _amount;
    if (session == null || amount < 1) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError('Sign in to add funds.');
      return;
    }

    try {
      await _api.topupWallet(
        customerId: session.id,
        customerPhone: session.phone,
        amountRupees: amount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
      );
      if (!mounted) return;
      setState(() => _paying = false);
      AppToast.success(context, '₹${amount.toStringAsFixed(0)} added to wallet.');
      Navigator.of(context).pop(true);
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      _showError('Payment received but wallet credit failed. Contact support.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: ProfileInfoScaffold(
        title: 'Add funds',
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (!_canTopup)
                    Text(
                      'Top-up is off in admin, or no online payment gateway is enabled.',
                      style: AppFonts.style(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepGreen.withValues(alpha: 0.7),
                      ),
                    )
                  else ...[
                    Text(
                      'Amount',
                      style: AppFonts.style(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in _presets)
                          ChoiceChip(
                            label: Text('₹${preset.toStringAsFixed(0)}'),
                            selected: _amount == preset,
                            onSelected: (_) {
                              setState(() {
                                _amountController.text =
                                    preset.toStringAsFixed(0);
                              });
                            },
                            selectedColor:
                                AppColors.brandPurple.withValues(alpha: 0.18),
                            labelStyle: AppFonts.style(
                              context,
                              fontWeight: FontWeight.w700,
                              color: AppColors.deepGreen,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (_) => setState(() {}),
                      style: AppFonts.style(context, fontSize: 18),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Pay with',
                      style: AppFonts.style(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_razorpayAvailable)
                      _MethodTile(
                        selected: _paymentMethod == 'razorpay',
                        title: 'Razorpay',
                        onTap: () =>
                            setState(() => _paymentMethod = 'razorpay'),
                      ),
                    if (_stripeAvailable) ...[
                      if (_razorpayAvailable) const SizedBox(height: 8),
                      _MethodTile(
                        selected: _paymentMethod == 'stripe',
                        title: 'Stripe',
                        onTap: () => setState(() => _paymentMethod = 'stripe'),
                      ),
                    ],
                    if (_cashfreeAvailable) ...[
                      if (_razorpayAvailable || _stripeAvailable)
                        const SizedBox(height: 8),
                      _MethodTile(
                        selected: _paymentMethod == 'cashfree',
                        title: 'Cashfree',
                        onTap: () =>
                            setState(() => _paymentMethod = 'cashfree'),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _paying ? null : _startTopup,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _paying
                              ? 'Processing…'
                              : 'Add ₹${_amount > 0 ? _amount.toStringAsFixed(0) : '0'}',
                          style: AppFonts.style(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.selected,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.brandPurple
                  : AppColors.brandPurple.withValues(alpha: 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.brandPurple : AppColors.deepGreen,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppFonts.style(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
