import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_order.dart';
import '../theme/app_colors.dart';
import '../utils/order_delivery_time.dart';
import 'order_cancel_or_timer.dart';
import 'order_status_timeline.dart';

/// Tracking banner shown while an order is still in progress (not delivered).
class PendingOrderStatusCard extends StatelessWidget {
  const PendingOrderStatusCard({
    super.key,
    required this.order,
    this.onTap,
    this.onCancel,
    this.compact = false,
    this.cancelling = false,
  });

  final CustomerOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final bool compact;
  final bool cancelling;

  IconData _iconForStatus(String status) {
    return switch (status) {
      'pending' => Icons.schedule_rounded,
      'ready_to_pick_up' => Icons.inventory_2_outlined,
      'picked_up' => Icons.shopping_bag_outlined,
      'on_way' => Icons.delivery_dining_rounded,
      _ => Icons.local_shipping_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPurple.withValues(alpha: 0.1),
            Colors.white,
            AppColors.amberGlow.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: AppColors.brandPurple.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPurple.withValues(alpha: 0.12),
                ),
                child: Icon(
                  _iconForStatus(order.status),
                  color: AppColors.brandPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.trackingTitle,
                      style: GoogleFonts.exo2(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.id} · ${order.totalLabel}',
                      style: GoogleFonts.exo2(
                        fontSize: compact ? 11 : 12,
                        color: AppColors.deepGreen.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.deepGreen.withValues(alpha: 0.35),
                ),
            ],
          ),
          SizedBox(height: compact ? 12 : 14),
          Text(
            order.trackingMessage,
            style: GoogleFonts.exo2(
              fontSize: compact ? 11 : 12,
              height: 1.4,
              color: AppColors.deepGreen.withValues(alpha: 0.65),
            ),
          ),
          SizedBox(height: compact ? 12 : 14),
          OrderStatusTimeline(
            status: order.status,
            compact: true,
            showStepLabels: true,
          ),
          if (order.isPending &&
              (orderCanBeCancelled(order) || orderShouldShowDeliveryTimer(order))) ...[
            SizedBox(height: compact ? 12 : 14),
            OrderCancelOrTimer(
              order: order,
              compact: compact,
              onCancel: onCancel,
              cancelling: cancelling,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
