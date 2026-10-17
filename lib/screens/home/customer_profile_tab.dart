import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../customer_location_prefs.dart';
import '../../customer_session_prefs.dart';
import '../../l10n/app_localizations.dart';
import '../../locale_prefs.dart';
import '../../main.dart';
import '../../models/customer_auth.dart';
import '../../navigation/customer_shell_navigation.dart';
import '../../services/customer_orders_store.dart';
import '../../services/customer_wishlist_store.dart';
import '../../services/optica2_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_fonts.dart';
import '../../utils/app_navigation.dart';
import '../../utils/app_system_ui.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/floating_food_icons.dart';
import '../../widgets/kitchen_browse_chrome.dart';
import '../about_screen.dart';
import '../delivery_locations_screen.dart';
import '../help_support_screen.dart';
import '../location_picker_screen.dart';
import '../login_screen.dart';
import '../terms_privacy_screen.dart';
import '../edit_profile_screen.dart';
import '../wallet_screen.dart';
import 'customer_favorites_tab.dart';

class CustomerProfileTab extends StatefulWidget {
  const CustomerProfileTab({super.key});

  @override
  State<CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<CustomerProfileTab> {
  final _scrollController = ScrollController();
  var _stickyHeader = false;
  var _heroHeight = 0.0;

  String _address = '';
  String _locationLabel = '';
  int _locationCount = 0;
  Locale _locale = const Locale('en');
  CustomerAuth? _session;
  String? _walletBalanceLabel;
  final _walletApi = Optica2Api();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomerOrdersStore.instance.refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _walletApi.close();
    super.dispose();
  }

  void _onScroll() {
    if (_heroHeight <= 0 || !_scrollController.hasClients) return;
    final sticky = _scrollController.offset >= _heroHeight - 4;
    if (sticky != _stickyHeader && mounted) {
      setState(() => _stickyHeader = sticky);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _load(),
      CustomerOrdersStore.instance.refresh(),
    ]);
  }

  Future<void> _load() async {
    final saved = await CustomerLocationPrefs.load();
    final locale = await LocalePrefs.load();
    final session = await CustomerSessionPrefs.load();
    var locationCount = 0;
    if (session != null) {
      await CustomerLocationPrefs.migrateLegacyToCustomer(session.id);
      locationCount =
          (await CustomerLocationPrefs.listForCustomer(session.id)).length;
    }
    if (mounted) {
      setState(() {
        _address = saved?.address ?? '';
        _locationLabel = saved?.displayLabel ?? '';
        _locationCount = locationCount;
        _locale = locale;
        _session = session;
      });
    }
    await _loadWalletBalance(session);
  }

  Future<void> _loadWalletBalance(CustomerAuth? session) async {
    if (session == null) {
      if (mounted) setState(() => _walletBalanceLabel = null);
      return;
    }

    try {
      final snapshot = await _walletApi.fetchWallet(
        customerId: session.id,
        customerPhone: session.phone,
      );
      if (!mounted) return;
      setState(() {
        _walletBalanceLabel = snapshot.wallet.balanceLabel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _walletBalanceLabel = null);
    }
  }

  Future<void> _openWallet() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
    await _loadWalletBalance(_session);
  }

  Future<void> _openDeliveryLocations() async {
    final session = _session;
    if (session == null) {
      final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LocationPickerScreen(popOnSave: true),
        ),
      );
      if (ok == true) await _load();
      return;
    }

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => const DeliveryLocationsScreen()),
    );
    await _load();
  }

  String _languageLabel(AppLocalizations l10n) =>
      _locale.languageCode == 'te' ? l10n.languageTelugu : l10n.languageEnglish;

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  l10n.chooseLanguage,
                  style: AppFonts.style(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  l10n.languageEnglish,
                  style: AppFonts.style(context, fontWeight: FontWeight.w600),
                ),
                trailing: _locale.languageCode == 'en'
                    ? const Icon(Icons.check_rounded, color: AppColors.brandPurple)
                    : null,
                onTap: () => Navigator.pop(context, const Locale('en')),
              ),
              ListTile(
                title: Text(
                  l10n.languageTelugu,
                  style: AppFonts.style(context, fontWeight: FontWeight.w600),
                ),
                trailing: _locale.languageCode == 'te'
                    ? const Icon(Icons.check_rounded, color: AppColors.brandPurple)
                    : null,
                onTap: () => Navigator.pop(context, const Locale('te')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || picked == null || picked == _locale) return;
    CustomerApp.of(context)?.setLocale(picked);
    setState(() => _locale = picked);
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _signIn() async {
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (ok == true) await _load();
  }

  Future<void> _openEditProfile() async {
    final session = _session;
    if (session == null) return;

    final updated = await Navigator.of(context, rootNavigator: true).push<CustomerAuth>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(session: session),
      ),
    );
    if (updated != null) {
      setState(() => _session = updated);
    } else {
      await _load();
    }
  }

  Future<void> _signOut() async {
    await AppNavigation.afterLogout(context);
  }

  void _openOrders() {
    CustomerShellNavigation.selectTab(
      context,
      CustomerShellNavigation.tabOrders,
    );
  }

  Future<void> _openWishlist() async {
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(builder: (_) => const CustomerFavoritesTab()),
    );
  }

  String _ordersSubtitle(AppLocalizations l10n) {
    final store = CustomerOrdersStore.instance;
    if (store.loading && !store.loadedOnce) {
      return 'Loading your orders…';
    }
    if (store.error != null) {
      return 'Could not load orders';
    }
    final count = store.orders.length;
    if (count == 0) {
      return 'No orders yet';
    }
    return '$count ${count == 1 ? 'order' : 'orders'}';
  }

  String _wishlistSubtitle() {
    final count = CustomerWishlistStore.instance.entries.length;
    if (count == 0) {
      return 'No saved dishes yet';
    }
    return '$count ${count == 1 ? 'dish' : 'dishes'} saved';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = _session;
    final isSignedIn = session != null;
    final bottomPad = CustomerBottomNav.contentBottomPadding(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayOnDark,
      child: ColoredBox(
        color: AppColors.cream,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: FloatingFoodIcons(
                opacity: 0.10,
                count: 26,
                minSize: 18,
                maxSize: 34,
                seed: 83,
                entrance: false,
              ),
            ),
            RefreshIndicator(
              color: AppColors.brandPurple,
              onRefresh: _refresh,
              edgeOffset: AppSystemUi.topInset(context, 8),
              child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      KitchenBrowseTitleHero(
                        title: l10n.navProfile,
                        subtitle: isSignedIn
                            ? 'Manage your account & preferences'
                            : l10n.profileGuestSubtitle,
                        foodIconSeed: 84,
                        onHeightResolved: (height) {
                          if (_heroHeight != height) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _heroHeight = height);
                            });
                          }
                        },
                      ),
                      Transform.translate(
                        offset: const Offset(0, -36),
                        child: Material(
                          color: Colors.transparent,
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                            child: _ProfileUserCard(
                              isSignedIn: isSignedIn,
                              name: isSignedIn
                                  ? session.name
                                  : l10n.profileGuestName,
                              phone: isSignedIn
                                  ? session.phone
                                  : l10n.profileGuestSubtitle,
                              email: isSignedIn ? session.email : null,
                              onSignIn: _signIn,
                              onSignOut: _signOut,
                              signInLabel: l10n.profileSignIn,
                              signOutLabel: l10n.profileSignOut,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPad),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _ProfileSectionHeader(title: 'Your activity'),
                    ListenableBuilder(
                      listenable: CustomerOrdersStore.instance,
                      builder: (context, _) => _ProfileTile(
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppColors.brandPurple,
                        title: l10n.navOrders,
                        subtitle: _ordersSubtitle(l10n),
                        onTap: _openOrders,
                      ),
                    ),
                    if (isSignedIn)
                      _ProfileTile(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.amberGlow,
                        title: 'Wallet',
                        subtitle: _walletBalanceLabel == null
                            ? 'View balance and history'
                            : '${_walletBalanceLabel!} available',
                        onTap: _openWallet,
                      ),
                    ListenableBuilder(
                      listenable: CustomerWishlistStore.instance,
                      builder: (context, _) => _ProfileTile(
                        icon: Icons.favorite_rounded,
                        iconColor: AppColors.terracotta,
                        title: 'Wishlist',
                        subtitle: _wishlistSubtitle(),
                        onTap: _openWishlist,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _ProfileSectionHeader(title: 'Preferences'),
                    _ProfileTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.brandPurple,
                      title: l10n.language,
                      subtitle: _languageLabel(l10n),
                      onTap: _pickLanguage,
                    ),
                    _ProfileTile(
                      icon: Icons.location_on_outlined,
                      iconColor: AppColors.sage,
                      title: isSignedIn ? 'Delivery locations' : 'Delivery location',
                      subtitle: _address.isEmpty
                          ? 'Not set'
                          : isSignedIn && _locationCount > 1
                              ? '$_locationLabel · $_locationCount saved'
                              : _address,
                      onTap: _openDeliveryLocations,
                    ),
                    if (isSignedIn)
                      _ProfileTile(
                        icon: Icons.edit_outlined,
                        iconColor: AppColors.terracotta,
                        title: 'Edit profile',
                        subtitle: 'Update name, email, and account details',
                        onTap: _openEditProfile,
                      ),
                    const SizedBox(height: 8),
                    const _ProfileSectionHeader(title: 'Support & info'),
                    _ProfileTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.brandPurple,
                      title: 'Help & support',
                      subtitle: 'FAQ and contact options',
                      onTap: () => _openPage(const HelpSupportScreen()),
                    ),
                    _ProfileTile(
                      icon: Icons.description_outlined,
                      iconColor: AppColors.sage,
                      title: 'Terms & privacy',
                      subtitle: 'Terms, conditions, and privacy policy',
                      onTap: () => _openPage(const TermsPrivacyScreen()),
                    ),
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.terracotta,
                      title: 'About Made by Maa',
                      subtitle: 'Our story and mission',
                      onTap: () => _openPage(const AboutScreen()),
                    ),
                  ]),
                ),
              ),
            ],
          ),
            ),
          if (_stickyHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: KitchenBrowseStickyTitleBar(
                topInset: AppSystemUi.topInset(context, 8),
                title: l10n.navProfile,
                trailing: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileUserCard extends StatelessWidget {
  const _ProfileUserCard({
    required this.isSignedIn,
    required this.name,
    required this.phone,
    required this.email,
    required this.onSignIn,
    required this.onSignOut,
    required this.signInLabel,
    required this.signOutLabel,
  });

  final bool isSignedIn;
  final String name;
  final String phone;
  final String? email;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final String signInLabel;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.brandPurple.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: AppColors.brandPurple.withValues(alpha: 0.12),
          ),
          BoxShadow(
            blurRadius: 4,
            offset: const Offset(0, 2),
            color: Colors.black.withValues(alpha: 0.03),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                        color: AppColors.brandPurple.withValues(alpha: 0.28),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSignedIn
                            ? Icons.person_rounded
                            : Icons.person_outline_rounded,
                        color: AppColors.brandPurple,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepGreen,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          context,
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.deepGreen.withValues(alpha: 0.58),
                        ),
                      ),
                      if (isSignedIn &&
                          email != null &&
                          email!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            context,
                            fontSize: 12,
                            color: AppColors.deepGreen.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isSignedIn)
              _ProfileActionButton(
                label: signOutLabel,
                icon: Icons.logout_rounded,
                danger: true,
                onTap: onSignOut,
              )
            else
              _ProfileActionButton(
                label: signInLabel,
                icon: Icons.login_rounded,
                filled: true,
                onTap: onSignIn,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border? border;

    if (danger) {
      bg = AppColors.terracotta.withValues(alpha: 0.1);
      fg = AppColors.terracotta;
      border = Border.all(color: AppColors.terracotta.withValues(alpha: 0.35));
    } else if (filled) {
      bg = AppColors.brandPurple;
      fg = Colors.white;
      border = null;
    } else {
      bg = AppColors.brandPurple.withValues(alpha: 0.08);
      fg = AppColors.brandPurple;
      border = Border.all(color: AppColors.brandPurple.withValues(alpha: 0.18));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.style(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.deepGreen.withValues(alpha: 0.42),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.brandPurple.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                  color: AppColors.brandPurple.withValues(alpha: 0.07),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppFonts.style(
                            context,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.deepGreen,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.style(
                              context,
                              fontSize: 12,
                              height: 1.35,
                              color: AppColors.deepGreen.withValues(alpha: 0.52),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.deepGreen.withValues(alpha: 0.28),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
