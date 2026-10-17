import 'dart:async';

import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

import '../models/customer_payment_config.dart';

class CashfreeCheckoutException implements Exception {
  CashfreeCheckoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CashfreeCheckoutService {
  CashfreeCheckoutService._();

  static final CashfreeCheckoutService instance = CashfreeCheckoutService._();

  final _gateway = CFPaymentGatewayService();
  Completer<String>? _pendingOrder;
  var _callbackRegistered = false;

  void _ensureCallback() {
    if (_callbackRegistered) return;
    _gateway.setCallback(_onVerify, _onError);
    _callbackRegistered = true;
  }

  void _onVerify(String orderId) {
    final pending = _pendingOrder;
    if (pending == null || pending.isCompleted) return;
    pending.complete(orderId);
  }

  void _onError(CFErrorResponse errorResponse, String orderId) {
    final pending = _pendingOrder;
    if (pending == null || pending.isCompleted) return;

    final message = errorResponse.getMessage();
    pending.completeError(
      CashfreeCheckoutException(
        (message != null && message.isNotEmpty)
            ? message
            : 'Payment failed. Try again or use COD.',
      ),
    );
  }

  Future<String> startCheckout(CashfreeCheckoutOrder order) async {
    if (order.orderId.isEmpty || order.paymentSessionId.isEmpty) {
      throw CashfreeCheckoutException('Could not start online payment.');
    }

    _ensureCallback();
    _pendingOrder = Completer<String>();

    final environment = order.environment == 'production'
        ? CFEnvironment.PRODUCTION
        : CFEnvironment.SANDBOX;

    try {
      final session = CFSessionBuilder()
          .setEnvironment(environment)
          .setOrderId(order.orderId)
          .setPaymentSessionId(order.paymentSessionId)
          .build();

      final checkout =
          CFWebCheckoutPaymentBuilder().setSession(session).build();
      _gateway.doPayment(checkout);
    } on CFException catch (e) {
      _pendingOrder = null;
      throw CashfreeCheckoutException(e.message);
    }

    return _pendingOrder!.future;
  }
}
