import 'package:flutter/material.dart';

import '../customer_session_prefs.dart';
import '../models/customer_wallet.dart';
import '../services/optica2_api.dart';
import '../services/payment_config_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';
import '../widgets/profile_info_scaffold.dart';
import 'wallet_topup_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _api = Optica2Api();
  CustomerWalletSnapshot? _snapshot;
  var _loading = true;
  var _topupEnabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final session = await CustomerSessionPrefs.load();
    if (!mounted) return;

    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Sign in to view your wallet.';
      });
      return;
    }

    try {
      final config = await PaymentConfigService.ensureLoaded(api: _api);
      final snapshot = await _api.fetchWallet(
        customerId: session.id,
        customerPhone: session.phone,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _topupEnabled = config?.walletTopupEnabled ?? false;
        _loading = false;
      });
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load wallet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = _snapshot?.wallet;
    final transactions = _snapshot?.transactions ?? const [];

    return ProfileInfoScaffold(
      title: 'My wallet',
      body: RefreshIndicator(
        color: AppColors.brandPurple,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(message: _error!, onRetry: _load)
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandPurple,
                      AppColors.brandPurpleDeep,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 24,
                      color: AppColors.brandPurple.withValues(alpha: 0.28),
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available balance',
                      style: AppFonts.style(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      wallet?.balanceLabel ?? '₹0',
                      style: AppFonts.style(
                        context,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Total credited',
                          value: '₹${wallet?.totalCredited.toStringAsFixed(0) ?? '0'}',
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          label: 'Total used',
                          value: '₹${wallet?.totalDebited.toStringAsFixed(0) ?? '0'}',
                        ),
                      ],
                    ),
                    if (_topupEnabled) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final added = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const WalletTopupScreen(),
                              ),
                            );
                            if (added == true && mounted) _load();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.brandPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Add funds',
                            style: AppFonts.style(
                              context,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandPurple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'History',
                style: AppFonts.style(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                ),
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                _MessageCard(
                  message:
                      'No wallet activity yet. Add funds, or wait for admin credits and refunds.',
                  onRetry: null,
                )
              else
                ...transactions.map((tx) => _TransactionTile(transaction: tx)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.style(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppFonts.style(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final CustomerWalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    if (transaction.isOrderRefund && transaction.order != null) {
      return _OrderRefundTile(
        transaction: transaction,
        order: transaction.order!,
      );
    }

    final positive = transaction.isCredit;
    final accent = positive ? AppColors.sage : AppColors.terracotta;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive ? Icons.add_rounded : Icons.remove_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.typeLabel,
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
                if (transaction.orderNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.orderNumber!,
                    style: AppFonts.style(
                      context,
                      fontSize: 12,
                      color: AppColors.deepGreen.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.note!,
                    style: AppFonts.style(
                      context,
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.deepGreen.withValues(alpha: 0.62),
                    ),
                  ),
                ],
                if (transaction.createdAtHuman != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.createdAtHuman!,
                    style: AppFonts.style(
                      context,
                      fontSize: 11,
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            transaction.amountLabel,
            style: AppFonts.style(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRefundTile extends StatelessWidget {
  const _OrderRefundTile({
    required this.transaction,
    required this.order,
  });

  final CustomerWalletTransaction transaction;
  final WalletRefundOrderDetail order;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.sage;
    final note = order.refundNote ?? transaction.note;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            color: accent.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.replay_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.typeLabel,
                        style: AppFonts.style(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.orderNumber,
                        style: AppFonts.style(
                          context,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepGreen.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  transaction.amountLabel,
                  style: AppFonts.style(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RefundMetaChip(
                      icon: Icons.local_shipping_outlined,
                      label: order.statusLabel,
                    ),
                    _RefundMetaChip(
                      icon: Icons.payments_outlined,
                      label: order.paymentLabel,
                    ),
                    _RefundMetaChip(
                      icon: Icons.verified_outlined,
                      label: order.refundStatusLabel,
                      accent: accent,
                    ),
                  ],
                ),
                if (order.placedAtHuman != null &&
                    order.placedAtHuman!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Ordered ${order.placedAtHuman!}',
                    style: AppFonts.style(
                      context,
                      fontSize: 11,
                      color: AppColors.deepGreen.withValues(alpha: 0.48),
                    ),
                  ),
                ],
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Order items',
                    style: AppFonts.style(
                      context,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: AppColors.deepGreen.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _RefundItemRow(item: item),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                _RefundAmountRow(
                  label: 'Subtotal',
                  value: order.subtotalLabel,
                ),
                const SizedBox(height: 4),
                _RefundAmountRow(
                  label: 'Delivery fee',
                  value: order.deliveryFeeLabel,
                ),
                const SizedBox(height: 6),
                _RefundAmountRow(
                  label: 'Refunded to wallet',
                  value: order.refundedAmountLabel,
                  emphasized: true,
                ),
                if (note != null && note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      note,
                      style: AppFonts.style(
                        context,
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.deepGreen.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                ],
                if (transaction.createdAtHuman != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Credited ${transaction.createdAtHuman!}',
                    style: AppFonts.style(
                      context,
                      fontSize: 11,
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundMetaChip extends StatelessWidget {
  const _RefundMetaChip({
    required this.icon,
    required this.label,
    this.accent = AppColors.brandPurple,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.style(
              context,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.deepGreen.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundItemRow extends StatelessWidget {
  const _RefundItemRow({required this.item});

  final WalletRefundOrderItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveOptica2AssetUrl(item.imageUrl);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 44,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _itemFallback(),
                  )
                : _itemFallback(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.quantity}× ${item.dishName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  context,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepGreen,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.kitchenName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  context,
                  fontSize: 11,
                  color: AppColors.deepGreen.withValues(alpha: 0.52),
                ),
              ),
            ],
          ),
        ),
        Text(
          item.lineTotalLabel,
          style: AppFonts.style(
            context,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.deepGreen.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }

  Widget _itemFallback() {
    return ColoredBox(
      color: AppColors.brandPurple.withValues(alpha: 0.08),
      child: Icon(
        Icons.restaurant_rounded,
        size: 20,
        color: AppColors.brandPurple.withValues(alpha: 0.45),
      ),
    );
  }
}

class _RefundAmountRow extends StatelessWidget {
  const _RefundAmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppFonts.style(
              context,
              fontSize: emphasized ? 12.5 : 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.deepGreen.withValues(
                alpha: emphasized ? 0.82 : 0.58,
              ),
            ),
          ),
        ),
        Text(
          value,
          style: AppFonts.style(
            context,
            fontSize: emphasized ? 14 : 12,
            fontWeight: FontWeight.w800,
            color: emphasized ? AppColors.sage : AppColors.deepGreen,
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.style(
              context,
              fontSize: 14,
              height: 1.45,
              color: AppColors.deepGreen.withValues(alpha: 0.72),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}
