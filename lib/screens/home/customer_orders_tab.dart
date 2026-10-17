import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/customer_order.dart';
import '../../navigation/customer_shell_navigation.dart';
import '../../services/customer_orders_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/empty_orders_state.dart';
import '../../widgets/floating_food_icons.dart';
import '../featured_dishes_screen.dart';
import '../order_detail_screen.dart';

class CustomerOrdersTab extends StatefulWidget {
  const CustomerOrdersTab({super.key});

  @override
  State<CustomerOrdersTab> createState() => _CustomerOrdersTabState();
}

class _CustomerOrdersTabState extends State<CustomerOrdersTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomerOrdersStore.instance.refresh();
    });
  }

  Future<void> _refresh() => CustomerOrdersStore.instance.refresh();

  void _openBrowseDishes() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => const FeaturedDishesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: FloatingFoodIcons(
              opacity: 0.10,
              count: 26,
              minSize: 18,
              maxSize: 32,
              seed: 61,
              entrance: false,
            ),
          ),
          ListenableBuilder(
            listenable: CustomerOrdersStore.instance,
            builder: (context, _) {
              final store = CustomerOrdersStore.instance;
              final orders = store.orders;

              if (store.loading && !store.loadedOnce) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.brandPurple,
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.brandPurple,
                onRefresh: _refresh,
                child: orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.12,
                          ),
                          EmptyOrdersState(
                            title: store.error != null
                                ? 'Could not load orders'
                                : 'No orders yet',
                            subtitle: store.error ??
                                'Order homestyle meals from mom chefs near you — your history will show up here.',
                            actionLabel: store.error == null
                                ? 'Browse dishes'
                                : null,
                            onAction:
                                store.error == null ? _openBrowseDishes : null,
                          ),
                          if (store.error != null) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Pull down to try again',
                                style: AppFonts.style(
                                  context,
                                  fontSize: 13,
                                  color: AppColors.deepGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Your orders',
                                          style: AppFonts.style(
                                            context,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.deepGreen,
                                            height: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${orders.length} ${orders.length == 1 ? 'order' : 'orders'}',
                                          style: AppFonts.style(
                                            context,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.deepGreen
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.brandPurple
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.brandPurple,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (store.error != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 12),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.terracotta
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.terracotta
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      store.error!,
                                      style: AppFonts.style(
                                        context,
                                        fontSize: 13,
                                        color: AppColors.terracotta,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              12,
                              20,
                              CustomerBottomNav.contentBottomPadding(context),
                            ),
                            sliver: SliverList.separated(
                              itemCount: orders.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, i) =>
                                  _OrderCard(order: orders[i]),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'delivered' || 'refunded' => (
          AppColors.sage.withValues(alpha: 0.18),
          AppColors.sage,
        ),
      'on_way' || 'picked_up' => (
          AppColors.brandPurple.withValues(alpha: 0.14),
          AppColors.brandPurple,
        ),
      'ready_to_pick_up' => (
          AppColors.deepGreen.withValues(alpha: 0.12),
          AppColors.deepGreen,
        ),
      'cancelled' => (
          AppColors.terracotta.withValues(alpha: 0.14),
          AppColors.terracotta,
        ),
      _ => (
          AppColors.deepGreen.withValues(alpha: 0.08),
          AppColors.deepGreen.withValues(alpha: 0.65),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.style(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final date = order.placedAt;
    final dateLabel =
        '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final accent = switch (order.status) {
      'delivered' => AppColors.sage,
      'cancelled' => AppColors.terracotta,
      'on_way' || 'picked_up' => AppColors.brandPurple,
      _ => AppColors.brandPurple,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context, rootNavigator: true).push<void>(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(
                order: order,
                navIndex: CustomerShellNavigation.tabOrders,
              ),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: accent.withValues(alpha: 0.1),
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                blurRadius: 4,
                color: Colors.black.withValues(alpha: 0.03),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.id,
                              style: AppFonts.style(
                                context,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandPurple,
                              ),
                            ),
                            const Spacer(),
                            _StatusChip(
                              label: order.statusLabel,
                              status: order.status,
                            ),
                            if (order.hasRefund) ...[
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: order.refundLabel,
                                status: 'refunded',
                              ),
                            ] else if (order.refundPending) ...[
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: order.refundLabel,
                                status: 'pending',
                              ),
                            ],
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.sage.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.paymentLabel,
                                style: AppFonts.style(
                                  context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.sage,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateLabel,
                          style: AppFonts.style(
                            context,
                            fontSize: 12,
                            color: AppColors.deepGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          order.kitchenNames.join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            context,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.deepGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order.itemCount} items · ${order.totalLabel}',
                          style: AppFonts.style(
                            context,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepGreen,
                          ),
                        ),
                        if (order.paymentReference != null &&
                            order.paymentReference!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Txn: ${order.paymentReference}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              color: AppColors.deepGreen.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.deepGreen.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                order.deliveryAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.style(
                                  context,
                                  fontSize: 12,
                                  height: 1.35,
                                  color: AppColors.deepGreen.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.deepGreen.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ],
                        ),
                      ],
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
