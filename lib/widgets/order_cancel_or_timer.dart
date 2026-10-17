import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_order.dart';
import '../theme/app_colors.dart';
import '../utils/order_delivery_time.dart';

/// Cancel button (when >2h until delivery) or countdown timer (when ≤2h).
class OrderCancelOrTimer extends StatefulWidget {
  const OrderCancelOrTimer({
    super.key,
    required this.order,
    this.onCancel,
    this.compact = false,
    this.cancelling = false,
  });

  final CustomerOrder order;
  final VoidCallback? onCancel;
  final bool compact;
  final bool cancelling;

  @override
  State<OrderCancelOrTimer> createState() => _OrderCancelOrTimerState();
}

class _OrderCancelOrTimerState extends State<OrderCancelOrTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OrderCancelOrTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id ||
        oldWidget.order.status != widget.order.status) {
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (!orderShouldShowDeliveryTimer(widget.order)) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!orderShouldShowDeliveryTimer(widget.order)) {
        _timer?.cancel();
      }
      setState(() {});
    });
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel order?',
          style: GoogleFonts.exo2(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Are you sure you want to cancel ${widget.order.id}? '
          'This action cannot be undone.',
          style: GoogleFonts.exo2(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Keep order', style: GoogleFonts.exo2()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.terracotta,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Cancel order', style: GoogleFonts.exo2()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (orderCanBeCancelled(widget.order)) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: widget.cancelling || widget.onCancel == null
              ? null
              : () => _confirmCancel(context),
          icon: widget.cancelling
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.terracotta.withValues(alpha: 0.8),
                  ),
                )
              : const Icon(Icons.cancel_outlined, size: 18),
          label: Text(
            widget.cancelling ? 'Cancelling…' : 'Cancel order',
            style: GoogleFonts.exo2(
              fontSize: widget.compact ? 12 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.terracotta,
            side: BorderSide(color: AppColors.terracotta.withValues(alpha: 0.45)),
            padding: EdgeInsets.symmetric(
              vertical: widget.compact ? 10 : 12,
              horizontal: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.compact ? 12 : 14),
            ),
          ),
        ),
      );
    }

    if (orderShouldShowDeliveryTimer(widget.order)) {
      final remaining = timeUntilOrderDelivery(widget.order);
      if (remaining == null || remaining.inSeconds <= 0) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 14,
          vertical: widget.compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.amberGlow.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(widget.compact ? 12 : 14),
          border: Border.all(
            color: AppColors.amberGlow.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: widget.compact ? 18 : 20,
              color: AppColors.deepGreen.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Will be ready in',
                    style: GoogleFonts.exo2(
                      fontSize: widget.compact ? 11 : 12,
                      color: AppColors.deepGreen.withValues(alpha: 0.65),
                    ),
                  ),
                  Text(
                    formatDeliveryCountdown(remaining),
                    style: GoogleFonts.robotoMono(
                      fontSize: widget.compact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Cancellation closed',
              style: GoogleFonts.exo2(
                fontSize: widget.compact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.deepGreen.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
