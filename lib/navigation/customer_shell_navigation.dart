import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/customer_bottom_nav.dart';

/// Lets full-screen routes (e.g. order detail) switch tabs on [HomeScreen].
abstract final class CustomerShellNavigation {
  static const tabExplore = 0;
  static const tabNearby = 1;
  static const tabOrders = 2;
  static const tabCart = 3;
  static const tabProfile = 4;
  static const centerTabIndex = tabOrders;

  static void Function(int index)? onTabSelected;

  /// Pops the Explore tab nested stack back to the home feed.
  static VoidCallback? resetExploreHome;

  static void selectTab(BuildContext context, int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (index == tabExplore) {
      resetExploreHome?.call();
    }
    onTabSelected?.call(index);
  }

  static void goToExploreHome(BuildContext context) {
    selectTab(context, tabExplore);
  }

  static List<CustomerNavItem> navItems(AppLocalizations l10n) {
    return [
      CustomerNavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore_rounded,
        label: l10n.navExplore,
      ),
      CustomerNavItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: l10n.navNearby,
      ),
      CustomerNavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: l10n.navOrders,
      ),
      CustomerNavItem(
        icon: Icons.shopping_bag_outlined,
        activeIcon: Icons.shopping_bag_rounded,
        label: l10n.navCart,
      ),
      CustomerNavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: l10n.navProfile,
      ),
    ];
  }
}
