import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../navigation/customer_shell_navigation.dart';
import '../services/optica2_api.dart';
import '../customer_session_prefs.dart';
import '../services/customer_push_service.dart';
import '../services/order_review_prompt.dart';
import '../theme/app_colors.dart';
import '../utils/app_system_ui.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/startup_popup_dialog.dart';
import 'home/customer_cart_tab.dart';
import 'home/customer_discover_tab.dart';
import 'home/customer_nearby_tab.dart';
import 'home/customer_orders_tab.dart';
import 'home/customer_profile_tab.dart';

/// Main customer shell with creative bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var _navIndex = CustomerShellNavigation.tabExplore;
  final _api = Optica2Api();

  static const _tabs = [
    CustomerDiscoverTab(),
    CustomerNearbyTab(),
    CustomerOrdersTab(),
    CustomerCartTab(),
    CustomerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    CustomerShellNavigation.onTabSelected = (index) {
      if (mounted) setState(() => _navIndex = index);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartupPopup();
      _registerPushToken();
    });
  }

  Future<void> _registerPushToken() async {
    final session = await CustomerSessionPrefs.load();
    if (session == null) return;
    try {
      await CustomerPushService.registerDevice(
        api: _api,
        customerId: session.id,
        phoneE164: session.phone,
      );
    } catch (_) {
      // Silent fail — home should still load if push registration fails.
    }
  }

  @override
  void dispose() {
    if (CustomerShellNavigation.onTabSelected != null) {
      CustomerShellNavigation.onTabSelected = null;
    }
    _api.close();
    super.dispose();
  }

  Future<void> _showStartupPopup() async {
    if (!mounted) return;
    try {
      final popup = await _api.fetchStartupPopup();
      if (!mounted) return;
      if (!popup.enabled) {
        await OrderReviewPrompt.maybeShow(context, api: _api);
        return;
      }
      await StartupPopupDialog.showIfNeeded(context, popup);
    } catch (_) {
      // Silent fail — home should still load if popup API is down.
    }
    if (!mounted) return;
    await OrderReviewPrompt.maybeShow(context, api: _api);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = CustomerShellNavigation.navItems(l10n);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayLightBackground,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        extendBody: true,
        body: IndexedStack(
          index: _navIndex,
          children: _tabs,
        ),
        bottomNavigationBar: CustomerBottomNav(
          currentIndex: _navIndex,
          items: navItems,
          centerIndex: CustomerShellNavigation.centerTabIndex,
          onChanged: _onNavChanged,
        ),
      ),
    );
  }

  void _onNavChanged(int index) {
    if (index == CustomerShellNavigation.tabExplore) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      CustomerShellNavigation.resetExploreHome?.call();
    }
    setState(() => _navIndex = index);
  }
}
