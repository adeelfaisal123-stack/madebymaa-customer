import 'package:flutter/material.dart';

import '../customer_review_prefs.dart';
import '../customer_session_prefs.dart';
import '../models/customer_order.dart';
import '../services/customer_orders_store.dart';
import '../services/optica2_api.dart';
import '../widgets/order_review_sheet.dart';

abstract final class OrderReviewPrompt {
  static Future<void> maybeShow(
    BuildContext context, {
    Optica2Api? api,
  }) async {
    final session = await CustomerSessionPrefs.load();
    if (session == null || !context.mounted) return;

    final client = api ?? Optica2Api();
    final ownsClient = api == null;
    try {
      await CustomerOrdersStore.instance.refresh(api: client);
    } catch (_) {
      if (ownsClient) client.close();
      return;
    }

    if (!context.mounted) {
      if (ownsClient) client.close();
      return;
    }

    CustomerOrder? target;
    for (final order in CustomerOrdersStore.instance.orders) {
      if (!order.review.canSubmit) continue;
      if (await CustomerReviewPrefs.isSkipped(order.id)) continue;
      target = order;
      break;
    }

    if (target == null) {
      if (ownsClient) client.close();
      return;
    }

    await OrderReviewSheet.show(
      context,
      order: target,
      api: ownsClient ? client : api,
    );

    if (ownsClient) client.close();
  }
}
