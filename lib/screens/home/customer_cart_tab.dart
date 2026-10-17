import 'package:flutter/material.dart';

import '../../models/cart_line_item.dart';
import '../../services/customer_cart_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/customer_dish_line_card.dart';
import '../../widgets/empty_cart_state.dart';
import '../../widgets/floating_food_icons.dart';
import '../checkout_screen.dart';
import '../featured_dishes_screen.dart';

class CustomerCartTab extends StatelessWidget {
  const CustomerCartTab({super.key});

  void _openCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
    );
  }

  void _openAllDishes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FeaturedDishesScreen()),
    );
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await _showCartConfirmDialog(
      context,
      title: 'Clear cart?',
      message: 'Remove all items from your cart?',
      confirmLabel: 'Clear all',
    );
    if (confirmed == true) {
      CustomerCartStore.instance.clear();
      if (context.mounted) {
        AppToast.info(context, 'Cart cleared');
      }
    }
  }

  Future<void> _confirmRemoveLine(BuildContext context, CartLineItem line) async {
    final confirmed = await _showCartConfirmDialog(
      context,
      title: 'Remove item?',
      message: 'Remove ${line.dishName} from your cart?',
      confirmLabel: 'Remove',
    );
    if (confirmed == true) {
      CustomerCartStore.instance.removeLine(line.kitchenId, line.dishId);
      if (context.mounted) {
        AppToast.info(context, '${line.dishName} removed');
      }
    }
  }

  static Future<bool?> _showCartConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: AppFonts.style(
            ctx,
            fontWeight: FontWeight.w800,
            color: AppColors.deepGreen,
          ),
        ),
        content: Text(
          message,
          style: AppFonts.style(
            ctx,
            fontSize: 14,
            height: 1.45,
            color: AppColors.deepGreen.withValues(alpha: 0.75),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppFonts.style(
                ctx,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen.withValues(alpha: 0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: AppFonts.style(
                ctx,
                fontWeight: FontWeight.w800,
                color: AppColors.terracotta,
              ),
            ),
          ),
        ],
      ),
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
              seed: 53,
              entrance: false,
            ),
          ),
          ListenableBuilder(
            listenable: CustomerCartStore.instance,
            builder: (context, _) {
              final cart = CustomerCartStore.instance;

              if (cart.lines.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.brandPurple,
                  onRefresh: () async {
                    CustomerCartStore.instance.refresh();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.12,
                      ),
                      EmptyCartState(
                        title: 'Your cart is empty',
                        subtitle:
                            'Discover homestyle dishes from mom chefs near you and add your favourites.',
                        browseLabel: 'Browse dishes',
                        onBrowse: () => _openAllDishes(context),
                      ),
                    ],
                  ),
                );
              }

              final bottomPad = CustomerBottomNav.contentBottomPadding(context);
              final kitchenCount =
                  cart.lines.map((l) => l.kitchenId).toSet().length;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your cart',
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
                                '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}'
                                '${kitchenCount > 1 ? ' · $kitchenCount kitchens' : ''}',
                                style: AppFonts.style(
                                  context,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _confirmClearCart(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.terracotta.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_sweep_outlined,
                                    size: 16,
                                    color: AppColors.terracotta.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Clear',
                                    style: AppFonts.style(
                                      context,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.brandPurple.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: AppColors.brandPurple,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.brandPurple,
                      onRefresh: () async {
                        CustomerCartStore.instance.refresh();
                        await Future<void>.delayed(
                          const Duration(milliseconds: 350),
                        );
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: cart.lines.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == cart.lines.length) {
                            return _AddMoreItemsButton(
                              onTap: () => _openAllDishes(context),
                            );
                          }
                          return _CartLineCard(
                            line: cart.lines[i],
                            onRemove: () =>
                                _confirmRemoveLine(context, cart.lines[i]),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.brandPurple.withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 18,
                            color: AppColors.brandPurple.withValues(alpha: 0.1),
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.03),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Subtotal',
                                  style: AppFonts.style(
                                    context,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepGreen.withValues(
                                      alpha: 0.65,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  cart.subtotalLabel,
                                  style: AppFonts.style(
                                    context,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandPurple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Taxes & delivery calculated at checkout',
                                style: AppFonts.style(
                                  context,
                                  fontSize: 11,
                                  color: AppColors.deepGreen.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
                    child: FilledButton(
                      onPressed: () => _openCheckout(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Proceed to checkout',
                            style: AppFonts.style(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddMoreItemsButton extends StatelessWidget {
  const _AddMoreItemsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.22),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: AppColors.brandPurple.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.brandPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.brandPurple,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Add more items',
                  style: AppFonts.style(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPurple,
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

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.line,
    required this.onRemove,
  });

  final CartLineItem line;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cart = CustomerCartStore.instance;
    final category = line.mainCategoryName?.trim();

    return CustomerDishLineCard(
      dishName: line.dishName,
      kitchenName: line.kitchenName,
      priceLabel: line.lineTotalLabel,
      priceSubtext: line.quantity > 1
          ? '  · ₹${line.unitPrice.toStringAsFixed(0)} ea'
          : null,
      isVeg: line.isVeg,
      imageUrl: line.imageUrl,
      category: category,
      onRemove: onRemove,
      trailing: CustomerDishQtyStepper(
        quantity: line.quantity,
        onDecrement: line.quantity > 1
            ? () => cart.setQuantity(
                  line.kitchenId,
                  line.dishId,
                  line.quantity - 1,
                )
            : null,
        onIncrement: () => cart.setQuantity(
          line.kitchenId,
          line.dishId,
          line.quantity + 1,
        ),
      ),
    );
  }
}
