import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/dish_detail_entry.dart';
import '../../navigation/customer_shell_navigation.dart';
import '../../services/customer_cart_store.dart';
import '../../services/customer_wishlist_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../utils/app_system_ui.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/customer_dish_line_card.dart';
import '../../widgets/empty_wishlist_state.dart';
import '../../utils/dish_detail_route.dart';
import '../dish_detail_screen.dart';
import '../featured_dishes_screen.dart';

class CustomerFavoritesTab extends StatefulWidget {
  const CustomerFavoritesTab({
    super.key,
    this.navIndex = CustomerShellNavigation.tabProfile,
  });

  final int navIndex;

  @override
  State<CustomerFavoritesTab> createState() => _CustomerFavoritesTabState();
}

class _CustomerFavoritesTabState extends State<CustomerFavoritesTab> {
  late int _navIndex;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.navIndex;
  }

  void _onNavChanged(int index) {
    if (index == _navIndex) {
      Navigator.of(context).pop();
      return;
    }
    CustomerShellNavigation.selectTab(context, index);
  }

  void _openBrowseDishes(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FeaturedDishesScreen()),
    );
  }

  void _openDish(BuildContext context, int index, List<WishlistEntry> entries) {
    final dishEntries = [
      for (var i = 0; i < entries.length; i++)
        DishDetailEntry.fromCustomerDish(
          dish: entries[i].dish,
          kitchenId: entries[i].kitchenId,
          kitchenName: entries[i].kitchenName,
          kitchenLogoUrl: entries[i].kitchenLogoUrl,
          index: i,
        ),
    ];
    Navigator.of(context).push(
      DishDetailRoute.push(
        DishDetailScreen(
          entries: dishEntries,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _confirmClearWishlist(BuildContext context) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Clear wishlist?',
      message: 'Remove all saved dishes from your wishlist?',
      confirmLabel: 'Clear all',
    );
    if (confirmed == true) {
      CustomerWishlistStore.instance.clear();
      if (context.mounted) {
        AppToast.info(context, 'Wishlist cleared');
      }
    }
  }

  Future<void> _confirmRemoveEntry(
    BuildContext context,
    WishlistEntry entry,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Remove from wishlist?',
      message: 'Remove ${entry.dish.name} from your wishlist?',
      confirmLabel: 'Remove',
    );
    if (confirmed == true) {
      CustomerWishlistStore.instance.remove(entry.kitchenId, entry.dish.id);
      if (context.mounted) {
        AppToast.info(context, '${entry.dish.name} removed');
      }
    }
  }

  void _addToCart(BuildContext context, WishlistEntry entry) {
    HapticFeedback.mediumImpact();
    final cart = CustomerCartStore.instance;
    final added = cart.addDish(
      dish: entry.dish,
      kitchenId: entry.kitchenId,
      kitchenName: entry.kitchenName,
    );
    if (!added) {
      AppToast.warning(
        context,
        cart.kitchenConflictMessage(entry.kitchenId) ??
            'Clear your cart before ordering from another kitchen.',
      );
      return;
    }
    AppToast.cart(context, '${entry.dish.name} added to cart');
  }

  static Future<bool?> _showConfirmDialog(
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

  String _subtitle(int count, int kitchenCount) {
    if (count == 0) return 'No saved dishes yet';
    final dishLabel = '$count ${count == 1 ? 'dish' : 'dishes'} saved';
    if (kitchenCount > 1) {
      return '$dishLabel · $kitchenCount kitchens';
    }
    return dishLabel;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomPad = CustomerBottomNav.contentBottomPadding(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: ListenableBuilder(
        listenable: CustomerWishlistStore.instance,
        builder: (context, _) {
          final entries = CustomerWishlistStore.instance.entries;
          final kitchenCount = entries.map((e) => e.kitchenId).toSet().length;

          return Scaffold(
            backgroundColor: AppColors.cream,
            extendBody: true,
            appBar: AppBar(
              backgroundColor: AppColors.cream,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: AppColors.deepGreen),
              title: Text(
                'Wishlist',
                style: AppFonts.style(
                  context,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                ),
              ),
              actions: [
                if (entries.isNotEmpty)
                  TextButton(
                    onPressed: () => _confirmClearWishlist(context),
                    child: Text(
                      'Clear all',
                      style: AppFonts.style(
                        context,
                        fontWeight: FontWeight.w700,
                        color: AppColors.terracotta,
                      ),
                    ),
                  ),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.brandPurple,
              onRefresh: () async {
                CustomerWishlistStore.instance.refresh();
                await Future<void>.delayed(const Duration(milliseconds: 350));
              },
              child: entries.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPad),
                    children: [
                      EmptyWishlistState(
                        title: 'Your wishlist is empty',
                        subtitle:
                            'Tap the heart on any dish to save homestyle favourites for later.',
                        actionLabel: 'Browse dishes',
                        onAction: () => _openBrowseDishes(context),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: entries.length + 2,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _subtitle(entries.length, kitchenCount),
                            style: AppFonts.style(
                              context,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.deepGreen.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }

                      if (i == entries.length + 1) {
                        return _BrowseDishesButton(
                          onTap: () => _openBrowseDishes(context),
                        );
                      }

                      final entry = entries[i - 1];
                      final dish = entry.dish;
                      return CustomerDishLineCard(
                        dishName: dish.name,
                        kitchenName: entry.kitchenName,
                        priceLabel:
                            '₹${dish.effectivePrice.toStringAsFixed(0)}',
                        isVeg: dish.isVeg,
                        imageUrl: dish.imageUrl,
                        category: dish.mainCategory?.name,
                        onTap: () => _openDish(context, i - 1, entries),
                        onRemove: () => _confirmRemoveEntry(context, entry),
                        trailing: CustomerDishAddButton(
                          onTap: () => _addToCart(context, entry),
                        ),
                      );
                    },
                  ),
            ),
            bottomNavigationBar: CustomerBottomNav(
              currentIndex: _navIndex,
              items: CustomerShellNavigation.navItems(l10n),
              centerIndex: CustomerShellNavigation.centerTabIndex,
              onChanged: _onNavChanged,
            ),
          );
        },
      ),
    );
  }
}

class _BrowseDishesButton extends StatelessWidget {
  const _BrowseDishesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 18,
                  color: AppColors.brandPurple.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Text(
                  'Browse dishes',
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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
