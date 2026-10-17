import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_order.dart';
import '../navigation/customer_shell_navigation.dart';
import '../services/customer_orders_store.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../utils/app_system_ui.dart';
import '../utils/optica2_asset_url.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/order_refund_sheet.dart';
import '../widgets/order_review_sheet.dart';
import '../widgets/pending_order_status_card.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    this.navIndex = CustomerShellNavigation.tabOrders,
  });

  final CustomerOrder order;
  final int navIndex;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late int _navIndex;
  var _cancelling = false;
  final _api = Optica2Api();

  CustomerOrder get order {
    final fromStore = CustomerOrdersStore.instance.orders
        .where((existing) => existing.id == widget.order.id)
        .firstOrNull;
    return fromStore ?? widget.order;
  }

  @override
  void initState() {
    super.initState();
    _navIndex = widget.navIndex;
    CustomerOrdersStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    CustomerOrdersStore.instance.removeListener(_onStoreChanged);
    _api.close();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cancelOrder() async {
    setState(() => _cancelling = true);
    try {
      await CustomerOrdersStore.instance.cancelOrder(api: _api, order: order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${order.id} was cancelled.')),
      );
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel order.')),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _onNavChanged(int index) {
    if (index == _navIndex) {
      Navigator.of(context).pop();
      return;
    }
    CustomerShellNavigation.selectTab(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final top = AppSystemUi.topInset(context, 0);
    final bottom = CustomerBottomNav.contentBottomPadding(context);
    final date = order.placedAt;
    final dateLabel =
        '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.cream,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          order.id,
          style: GoogleFonts.exo2(
            fontWeight: FontWeight.w800,
            color: AppColors.deepGreen,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brandPurple,
        onRefresh: () => CustomerOrdersStore.instance.refresh(api: _api),
        child: ListView(
        padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          if (order.isInProgress) ...[
            PendingOrderStatusCard(
              order: order,
              cancelling: _cancelling,
              onCancel: _cancelOrder,
            ),
            const SizedBox(height: 14),
          ] else if (order.isCancelled) ...[
            _CancelledBanner(order: order),
            const SizedBox(height: 14),
          ] else if (order.isDelivered && order.review.canSubmit) ...[
            _ReviewPromptCard(
              order: order,
              onReview: () => OrderReviewSheet.show(context, order: order, api: _api),
            ),
            const SizedBox(height: 14),
          ] else if (order.isDelivered && order.review.submitted) ...[
            _ReviewSubmittedBanner(),
            const SizedBox(height: 14),
          ],
          if (order.isDelivered && order.canApplyForRefund) ...[
            _RefundPromptCard(
              onApply: () => OrderRefundSheet.show(context, order: order, api: _api),
            ),
            const SizedBox(height: 14),
          ] else if (order.refundPending) ...[
            RefundPendingBanner(order: order),
            const SizedBox(height: 14),
          ],
          _InfoCard(
            title: 'Order status',
            children: [
              _Row(label: 'Status', value: order.statusLabel),
              _Row(label: 'Placed', value: dateLabel),
              _Row(label: 'Items', value: '${order.itemCount}'),
              _Row(label: 'Kitchens', value: order.kitchenNames.join(' · ')),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Payment & transaction',
            children: [
              _Row(label: 'Method', value: order.paymentLabel),
              _Row(label: 'Payment status', value: order.paymentStatusLabel),
              if (order.refundStatus != 'none') ...[
                _Row(label: 'Refund status', value: order.refundLabel),
                if (order.refundRequestDescription != null &&
                    order.refundRequestDescription!.trim().isNotEmpty)
                  _Row(
                    label: 'Your request',
                    value: order.refundRequestDescription!,
                  ),
                if (order.refundedAmount != null)
                  _Row(label: 'Refunded amount', value: order.refundAmountLabel),
                if (order.refundNote != null && order.refundNote!.isNotEmpty)
                  _Row(label: 'Refund note', value: order.refundNote!),
              ],
              _Row(
                label: 'Transaction ID',
                value: order.paymentReference ?? '—',
                mono: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Delivery',
            children: [
              _Row(label: 'Slot', value: order.deliverySlotDisplay),
              _Row(label: 'Address', value: order.deliveryAddress),
              if (order.notes != null && order.notes!.isNotEmpty)
                _Row(label: 'Notes', value: order.notes!),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Items',
            style: GoogleFonts.exo2(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 10),
          for (final line in order.lines) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: line.imageUrl != null
                        ? Image.network(
                            resolveOptica2AssetUrl(line.imageUrl!) ?? line.imageUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imageFallback(line.isVeg),
                          )
                        : _imageFallback(line.isVeg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.dishName,
                          style: GoogleFonts.exo2(
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line.kitchenName,
                          style: GoogleFonts.exo2(
                            fontSize: 12,
                            color: AppColors.deepGreen.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${line.quantity} × ₹${line.unitPrice.toStringAsFixed(0)} · ${line.lineTotalLabel}',
                          style: GoogleFonts.exo2(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _InfoCard(
            title: 'Bill summary',
            children: [
              _Row(label: 'Subtotal', value: order.subtotalLabel),
              _Row(label: 'Delivery fee', value: order.deliveryFeeLabel),
              if (order.gstAmount > 0)
                _Row(label: 'GST', value: order.gstAmountLabel),
              _Row(label: 'Total paid', value: order.totalLabel, bold: true),
            ],
          ),
        ],
      ),
      ),
      bottomNavigationBar: CustomerBottomNav(
        currentIndex: _navIndex,
        items: CustomerShellNavigation.navItems(l10n),
        centerIndex: CustomerShellNavigation.centerTabIndex,
        onChanged: _onNavChanged,
      ),
    );
  }

  Widget _imageFallback(bool isVeg) {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.sage.withValues(alpha: 0.15),
      child: Icon(
        isVeg ? Icons.eco_rounded : Icons.restaurant_rounded,
        color: AppColors.sage,
      ),
    );
  }
}

class _RefundPromptCard extends StatelessWidget {
  const _RefundPromptCard({required this.onApply});

  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: AppColors.brandPurple.withValues(alpha: 0.07),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue with this order?',
            style: GoogleFonts.exo2(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Apply for a refund with a short description and optional photo.',
            style: GoogleFonts.exo2(
              fontSize: 12,
              height: 1.4,
              color: AppColors.deepGreen.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: Text(
              'Apply for refund',
              style: GoogleFonts.exo2(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSubmittedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sage.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: AppColors.sage),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Thanks for rating this order!',
              style: GoogleFonts.exo2(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPromptCard extends StatelessWidget {
  const _ReviewPromptCard({required this.order, required this.onReview});

  final CustomerOrder order;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.amberGlow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amberGlow.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your order?',
            style: GoogleFonts.exo2(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rate the kitchen and dishes from ${order.id}.',
            style: GoogleFonts.exo2(
              fontSize: 12,
              height: 1.4,
              color: AppColors.deepGreen.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onReview,
            icon: const Icon(Icons.star_rounded, size: 18),
            label: Text('Leave a review', style: GoogleFonts.exo2(fontWeight: FontWeight.w800)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPurple,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.terracotta.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.terracotta.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: AppColors.terracotta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.trackingTitle,
                  style: GoogleFonts.exo2(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.trackingMessage,
                  style: GoogleFonts.exo2(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.deepGreen.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.exo2(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.mono = false,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool mono;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.exo2(
                fontSize: 12,
                color: AppColors.deepGreen.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.deepGreen,
                    )
                  : GoogleFonts.exo2(
                      fontSize: 13,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.deepGreen,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
