import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../dish_swipe_hint_prefs.dart';
import '../l10n/app_localizations.dart';
import '../models/customer_dish.dart';
import '../models/customer_review.dart';
import '../models/dish_detail_entry.dart';
import '../services/customer_cart_store.dart';
import '../services/customer_wishlist_store.dart';
import '../services/optica2_api.dart';
import '../services/recently_viewed_dishes_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_system_ui.dart';
import '../utils/optica2_asset_url.dart';
import '../widgets/app_toast.dart';
import '../widgets/customer_reviews_bottom_sheet.dart';
import '../widgets/floating_food_icons.dart';
import 'kitchen_detail_screen.dart';

/// Full-screen dish view with quantity, cart, wishlist, and swipe browsing.
class DishDetailScreen extends StatefulWidget {
  const DishDetailScreen({
    super.key,
    required this.entries,
    required this.initialIndex,
  }) : assert(entries.length > 0),
       assert(initialIndex >= 0 && initialIndex < entries.length);

  final List<DishDetailEntry> entries;
  final int initialIndex;

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen>
    with TickerProviderStateMixin {
  late int _currentIndex;
  late Color _accent;
  late int _quantity;
  late final AnimationController _heartPulse;
  late final AnimationController _entrance;
  late final PageController _pageController;

  late bool _showSwipeHint;

  final _cart = CustomerCartStore.instance;
  final _wishlist = CustomerWishlistStore.instance;
  final _api = Optica2Api();

  DishDetailEntry get _entry => widget.entries[_currentIndex];
  CustomerDish get _dish => _entry.dish;
  bool get _canSwipe => widget.entries.length > 1;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _syncEntryState();
    _heartPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _showSwipeHint = _canSwipe;
    _wishlist.addListener(_onWishlistChanged);
    _loadSwipeHint();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward();
      _recordRecentView();
    });
  }

  Future<void> _loadSwipeHint() async {
    if (!_canSwipe) {
      if (mounted) setState(() => _showSwipeHint = false);
      return;
    }

    final dismissed = await DishSwipeHintPrefs.isDismissed();
    if (!mounted) return;

    if (dismissed) {
      setState(() => _showSwipeHint = false);
      return;
    }

    setState(() => _showSwipeHint = true);
  }

  Future<void> _dismissSwipeHint() async {
    if (!_showSwipeHint) return;
    HapticFeedback.lightImpact();
    setState(() => _showSwipeHint = false);
    await DishSwipeHintPrefs.markDismissed();
  }

  void _syncEntryState() {
    final entry = _entry;
    _accent = entry.accentColor ?? AppColors.brandPurple;
    final inCart = _cart.quantityFor(entry.kitchenId, entry.dish.id);
    _quantity = inCart > 0 ? inCart : 1;
  }

  void _recordRecentView() {
    RecentlyViewedDishesStore.instance.recordView(_entry);
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _syncEntryState();
    });
    HapticFeedback.selectionClick();
    _entrance.forward(from: 0);
    _recordRecentView();
  }

  void _showReviews() {
    CustomerReviewsBottomSheet.show(
      context,
      title: '${_dish.name} reviews',
      loadReviews: () => _api.fetchDishReviews(_dish.id),
    );
  }

  @override
  void dispose() {
    _wishlist.removeListener(_onWishlistChanged);
    _pageController.dispose();
    _heartPulse.dispose();
    _entrance.dispose();
    _api.close();
    super.dispose();
  }

  void _onWishlistChanged() {
    if (mounted) setState(() {});
  }

  bool get _isWishlisted =>
      _wishlist.isSaved(_entry.kitchenId, _entry.dish.id);

  void _toggleWishlist() {
    HapticFeedback.lightImpact();
    final wasSaved = _isWishlisted;
    _wishlist.toggle(
      dish: _entry.dish,
      kitchenId: _entry.kitchenId,
      kitchenName: _entry.kitchenName,
      kitchenLogoUrl: _entry.kitchenLogoUrl,
    );
    if (!wasSaved) {
      _heartPulse.forward(from: 0);
    }
    final msg = _isWishlisted ? 'Saved to wishlist' : 'Removed from wishlist';
    AppToast.success(context, msg);
  }

  void _addToCart() {
    HapticFeedback.mediumImpact();
    final added = _cart.setDishQuantity(
      dish: _entry.dish,
      kitchenId: _entry.kitchenId,
      kitchenName: _entry.kitchenName,
      quantity: _quantity,
      kitchenInstantDeliveryEnabled: _entry.kitchenInstantDeliveryEnabled,
    );
    if (!added) {
      AppToast.warning(
        context,
        _cart.kitchenConflictMessage(_entry.kitchenId) ??
            'Clear your cart before ordering from another kitchen.',
      );
      return;
    }
    AppToast.cart(context, '${_entry.dish.name} added to cart');
  }

  void _openKitchen() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KitchenDetailScreen(kitchenId: _entry.kitchenId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = _ActionDock.scrollBottomPadding(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final hintBottom = bottomInset + _ActionDock.barHeight + 12;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.overlayOnDark,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.entries.length,
              physics: _canSwipe
                  ? const PageScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final entry = widget.entries[index];
                final dish = entry.dish;
                final accent = entry.accentColor ?? AppColors.brandPurple;
                final imageUrl = resolveOptica2AssetUrl(dish.imageUrl);
                final animate = index == _currentIndex;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: FloatingFoodIcons(
                        opacity: 0.10,
                        count: 32,
                        seed: 19 + index,
                      ),
                    ),
                    RefreshIndicator(
                      color: AppColors.brandPurple,
                      onRefresh: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 350),
                        );
                      },
                      child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: animate
                              ? _StaggeredFade(
                                  entrance: _entrance,
                                  start: 0.0,
                                  end: 0.45,
                                  child: _DishHeader(
                                    dish: dish,
                                    imageUrl: imageUrl,
                                    accent: accent,
                                    kitchenName: entry.kitchenName,
                                    chefName: entry.chefName,
                                    rating: dish.rating,
                                    onShowReviews: _showReviews,
                                    onOpenKitchen: _openKitchen,
                                  ),
                                )
                              : _DishHeader(
                                  dish: dish,
                                  imageUrl: imageUrl,
                                  accent: accent,
                                  kitchenName: entry.kitchenName,
                                  chefName: entry.chefName,
                                  rating: dish.rating,
                                  onShowReviews: _showReviews,
                                  onOpenKitchen: _openKitchen,
                                ),
                        ),
                        SliverToBoxAdapter(
                          child: animate
                              ? _StaggeredFade(
                                  entrance: _entrance,
                                  start: 0.2,
                                  end: 0.65,
                                  child: _DetailContent(
                                    dish: dish,
                                    accent: accent,
                                    bottomInset: bottomPad,
                                    entrance: _entrance,
                                  ),
                                )
                              : _DetailContent(
                                  dish: dish,
                                  accent: accent,
                                  bottomInset: bottomPad,
                                  entrance: _entrance,
                                ),
                        ),
                      ],
                    ),
                    ),
                  ],
                );
              },
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    if (_canSwipe) ...[
                      const Spacer(),
                      _DishPagerIndicator(
                        current: _currentIndex,
                        total: widget.entries.length,
                      ),
                    ],
                    const Spacer(),
                    _WishlistButton(
                      saved: _isWishlisted,
                      pulse: _heartPulse,
                      onTap: _toggleWishlist,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ActionDock(
                accent: _accent,
                quantity: _quantity,
                priceLabel: _dish.priceLabel,
                onDecrement: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
                onIncrement: () => setState(() => _quantity++),
                onAddToCart: _addToCart,
              ),
            ),
            if (_showSwipeHint && _canSwipe)
              Positioned(
                left: 16,
                right: 16,
                bottom: hintBottom,
                child: _SwipeHintBanner(
                  accent: _accent,
                  onSkip: _dismissSwipeHint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DishPagerIndicator extends StatelessWidget {
  const _DishPagerIndicator({
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swipe_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 6),
          Text(
            '${current + 1} / $total',
            style: GoogleFonts.exo2(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// One-time floating coach-mark: swipe left/right to browse dishes.
class _SwipeHintBanner extends StatefulWidget {
  const _SwipeHintBanner({
    required this.accent,
    required this.onSkip,
  });

  final Color accent;
  final VoidCallback onSkip;

  @override
  State<_SwipeHintBanner> createState() => _SwipeHintBannerState();
}

class _SwipeHintBannerState extends State<_SwipeHintBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (context, child) {
        final bob = Curves.easeInOut.transform(_float.value);
        return Transform.translate(
          offset: Offset(0, -4 * bob),
          child: child,
        );
      },
      child: Material(
        elevation: 10,
        shadowColor: widget.accent.withValues(alpha: 0.35),
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.35),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.accent.withValues(alpha: 0.1),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onSkip,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.deepGreen.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.exo2(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepGreen.withValues(alpha: 0.72),
                          height: 1,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                child: Row(
                  children: [
                    _SwipeHintArrow(
                      icon: Icons.chevron_left_rounded,
                      animation: _float,
                      reverse: false,
                      hint: 'Next',
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            size: 22,
                            color: widget.accent,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Swipe right for previous · Swipe left for next',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.exo2(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepGreen,
                              height: 1.25,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SwipeHintArrow(
                      icon: Icons.chevron_right_rounded,
                      animation: _float,
                      reverse: false,
                      hint: 'Previous',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeHintArrow extends StatelessWidget {
  const _SwipeHintArrow({
    required this.icon,
    required this.animation,
    required this.reverse,
    this.hint,
  });

  final IconData icon;
  final Animation<double> animation;
  final bool reverse;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = reverse ? 1 - animation.value : animation.value;
        final shift = (t - 0.5) * (icon == Icons.chevron_right_rounded ? 8 : -8);
        return Tooltip(
          message: hint ?? '',
          child: Transform.translate(
            offset: Offset(shift, 0),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.deepGreen.withValues(alpha: 0.45 + t * 0.35),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HEADER — hero image + info card (no overlap; name always visible)
// ═══════════════════════════════════════════════════════════════════════════

class _DishHeader extends StatelessWidget {
  const _DishHeader({
    required this.dish,
    required this.imageUrl,
    required this.accent,
    required this.kitchenName,
    required this.chefName,
    required this.rating,
    required this.onShowReviews,
    required this.onOpenKitchen,
  });

  final CustomerDish dish;
  final String? imageUrl;
  final Color accent;
  final String kitchenName;
  final String? chefName;
  final CustomerRatingSummary rating;
  final VoidCallback onShowReviews;
  final VoidCallback onOpenKitchen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroImage(
          imageUrl: imageUrl,
          accent: accent,
          isVeg: dish.isVeg,
          hasDiscount: dish.hasDiscount,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: _SummaryCard(
            dish: dish,
            accent: accent,
            kitchenName: kitchenName,
            chefName: chefName,
            rating: rating,
            onShowReviews: onShowReviews,
            onOpenKitchen: onOpenKitchen,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HERO IMAGE
// ═══════════════════════════════════════════════════════════════════════════

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.imageUrl,
    required this.accent,
    required this.isVeg,
    required this.hasDiscount,
  });

  final String? imageUrl;
  final Color accent;
  final bool isVeg;
  final bool hasDiscount;

  static const double _height = 300;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: _height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                headers: const {
                  'User-Agent': 'MadeByMaa-Customer/1.0',
                  'Accept': 'image/*',
                },
                errorBuilder: (_, _, _) => _HeroFallback(accent: accent),
              )
            else
              _HeroFallback(accent: accent),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.38),
                    Colors.transparent,
                    AppColors.cream.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -40,
              child: _Blob(
                size: 140,
                color: accent.withValues(alpha: 0.4),
                blur: 50,
              ),
            ),
            if (hasDiscount)
              Positioned(top: 88, right: 16, child: _OfferStamp()),
            Positioned(
              top: 88,
              left: 16,
              child: _MealAccentTag(accent: accent, isVeg: isVeg),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.blur});

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: blur, spreadRadius: blur / 2),
          ],
        ),
      ),
    );
  }
}

class _MealAccentTag extends StatelessWidget {
  const _MealAccentTag({required this.accent, required this.isVeg});

  final Color accent;
  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVeg ? Icons.eco_rounded : Icons.local_fire_department_rounded,
            size: 14,
            color: isVeg ? AppColors.sage : AppColors.terracotta,
          ),
          const SizedBox(width: 5),
          Text(
            isVeg ? 'Pure veg' : 'Non-veg',
            style: GoogleFonts.exo2(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isVeg ? AppColors.sage : AppColors.terracotta,
              height: 1,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferStamp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.18,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.terracotta, Color(0xFFB44A1B)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              offset: const Offset(0, 8),
              color: AppColors.terracotta.withValues(alpha: 0.4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_offer_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              'Special offer',
              style: GoogleFonts.exo2(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, AppColors.brandPurpleDeep],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          size: 96,
          color: Colors.white.withValues(alpha: 0.26),
        ),
      ),
    );
  }
}

/// Solid info card below the hero — kitchen, chef, dish name, price and rating.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.dish,
    required this.accent,
    required this.kitchenName,
    required this.chefName,
    required this.rating,
    required this.onShowReviews,
    required this.onOpenKitchen,
  });

  final CustomerDish dish;
  final Color accent;
  final String kitchenName;
  final String? chefName;
  final CustomerRatingSummary rating;
  final VoidCallback onShowReviews;
  final VoidCallback onOpenKitchen;

  @override
  Widget build(BuildContext context) {
    final category = dish.displayCategoryLabel.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: Colors.black.withValues(alpha: 0.08),
          ),
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: accent.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.45)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _KitchenChefCard(
                    accent: accent,
                    kitchenName: kitchenName,
                    chefName: chefName,
                    onTap: onOpenKitchen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dish.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.exo2(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepGreen,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _CategoryPill(label: category, accent: accent),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F0F2)),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _PriceBlock(dish: dish, accent: accent)),
                      const SizedBox(width: 12),
                      _RatingChip(rating: rating, onTap: onShowReviews),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.exo2(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen.withValues(alpha: 0.75),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact card showing the kitchen name + the chef who cooks it. Tappable to
/// open the kitchen detail screen.
class _KitchenChefCard extends StatelessWidget {
  const _KitchenChefCard({
    required this.accent,
    required this.kitchenName,
    required this.chefName,
    required this.onTap,
  });

  final Color accent;
  final String kitchenName;
  final String? chefName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chef = chefName?.trim();
    final hasChef = chef != null && chef.isNotEmpty;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.14),
                accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.78)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      color: accent.withValues(alpha: 0.32),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kitchenName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.exo2(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                        height: 1.1,
                      ),
                    ),
                    if (hasChef) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _ChefIcon(size: 11, color: accent),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'by $chef',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.exo2(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                                height: 1.1,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: accent.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small custom-painted chef silhouette (head with a toque) that matches the
/// chef-icon used on the kitchen detail screen.
class _ChefIcon extends StatelessWidget {
  const _ChefIcon({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ChefIconPainter(color: color)),
    );
  }
}

class _ChefIconPainter extends CustomPainter {
  const _ChefIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(w * 0.40, h * 0.74)
      ..cubicTo(w * 0.40, h * 0.86, w * 0.24, h * 0.84, w * 0.18, h * 1.02)
      ..lineTo(w * 0.82, h * 1.02)
      ..cubicTo(w * 0.76, h * 0.84, w * 0.60, h * 0.86, w * 0.60, h * 0.74)
      ..close();
    canvas.drawPath(body, paint);

    canvas.drawCircle(Offset(w * 0.5, h * 0.60), w * 0.145, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.40, w * 0.40, h * 0.12),
        Radius.circular(w * 0.035),
      ),
      paint,
    );

    canvas.drawCircle(Offset(w * 0.32, h * 0.31), w * 0.155, paint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.31), w * 0.155, paint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.24), w * 0.185, paint);
  }

  @override
  bool shouldRepaint(_ChefIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.dish, required this.accent});

  final CustomerDish dish;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Price',
          style: GoogleFonts.exo2(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.deepGreen.withValues(alpha: 0.5),
            letterSpacing: 1.2,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              dish.priceLabel,
              style: GoogleFonts.exo2(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: accent,
                height: 1,
                letterSpacing: -0.6,
              ),
            ),
            if (dish.hasDiscount) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  dish.originalPriceLabel!,
                  style: GoogleFonts.exo2(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepGreen.withValues(alpha: 0.4),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.deepGreen.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating, required this.onTap});

  final CustomerRatingSummary rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasReviews = rating.hasReviews;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            gradient: hasReviews
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD66B), AppColors.amberGlow],
                  )
                : null,
            color: hasReviews ? null : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasReviews
                  ? AppColors.amberGlow.withValues(alpha: 0.6)
                  : const Color(0xFFE7E7EC),
            ),
            boxShadow: hasReviews
                ? [
                    BoxShadow(
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                      color: AppColors.amberGlow.withValues(alpha: 0.4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasReviews
                        ? Icons.star_rounded
                        : Icons.rate_review_rounded,
                    size: 16,
                    color: hasReviews
                        ? AppColors.deepGreen
                        : AppColors.deepGreen.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasReviews ? rating.average.toStringAsFixed(1) : 'New',
                    style: GoogleFonts.exo2(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepGreen,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                hasReviews
                    ? '${rating.count} ${rating.count == 1 ? 'review' : 'reviews'}'
                    : 'Be first',
                style: GoogleFonts.exo2(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepGreen.withValues(alpha: 0.62),
                  height: 1,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  CONTENT BELOW THE SUMMARY CARD
// ═══════════════════════════════════════════════════════════════════════════

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.dish,
    required this.accent,
    required this.bottomInset,
    required this.entrance,
  });

  final CustomerDish dish;
  final Color accent;
  final double bottomInset;
  final AnimationController entrance;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDescription =
        dish.description != null && dish.description!.trim().isNotEmpty;
    final hasIngredients =
        dish.ingredients != null && dish.ingredients!.trim().isNotEmpty;

    final sections = <Widget>[];

    if (hasDescription) {
      sections.add(
        _SectionCard(
          icon: Icons.menu_book_rounded,
          accent: accent,
          title: l10n.dishDetailAbout,
          child: Text(
            dish.description!.trim(),
            style: GoogleFonts.exo2(
              fontSize: 15,
              height: 1.55,
              color: AppColors.deepGreen.withValues(alpha: 0.78),
            ),
          ),
        ),
      );
    }

    if (hasIngredients) {
      sections.add(
        _SectionCard(
          icon: Icons.eco_rounded,
          accent: AppColors.sage,
          title: l10n.dishDetailIngredients,
          child: Text(
            dish.ingredients!.trim(),
            style: GoogleFonts.exo2(
              fontSize: 15,
              height: 1.55,
              color: AppColors.deepGreen.withValues(alpha: 0.78),
            ),
          ),
        ),
      );
    }

    sections.add(_QuickInfoTiles(accent: accent));

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _StaggeredFade(
              entrance: entrance,
              start: 0.25 + i * 0.08,
              end: 0.55 + i * 0.08,
              child: sections[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.exo2(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Three highlight tiles at the bottom: hot, fresh, homestyle.
class _QuickInfoTiles extends StatelessWidget {
  const _QuickInfoTiles({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GradientInfoTile(
            icon: Icons.local_fire_department_rounded,
            title: 'Hot',
            subtitle: 'Served warm',
            colors: const [Color(0xFFFFB36A), AppColors.terracotta],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GradientInfoTile(
            icon: Icons.spa_rounded,
            title: 'Fresh',
            subtitle: 'Made on order',
            colors: const [AppColors.brandPurpleLight, AppColors.brandPurple],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GradientInfoTile(
            icon: Icons.home_rounded,
            title: 'Homestyle',
            subtitle: 'Real recipe',
            colors: [accent.withValues(alpha: 0.92), AppColors.brandPurpleDeep],
          ),
        ),
      ],
    );
  }
}

class _GradientInfoTile extends StatelessWidget {
  const _GradientInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: colors.last.withValues(alpha: 0.12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.exo2(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColors.deepGreen,
              letterSpacing: 0.1,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.exo2(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreen.withValues(alpha: 0.55),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ANIMATIONS, TOP CHROME, BOTTOM ACTION DOCK
// ═══════════════════════════════════════════════════════════════════════════

/// Fades and translates [child] in once based on a normalized window of
/// [entrance]'s 0..1 progress.
class _StaggeredFade extends StatelessWidget {
  const _StaggeredFade({
    required this.entrance,
    required this.start,
    required this.end,
    required this.child,
  });

  final AnimationController entrance;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: entrance,
      builder: (context, c) {
        final v = entrance.value;
        final raw = end > start
            ? ((v - start) / (end - start)).clamp(0.0, 1.0)
            : 1.0;
        final curved = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: curved,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - curved)),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class _ActionDock extends StatelessWidget {
  static const _contentHeight = 70.0;
  static const barHeight = _contentHeight;

  const _ActionDock({
    required this.accent,
    required this.quantity,
    required this.priceLabel,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
  });

  final Color accent;
  final int quantity;
  final String priceLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;

  /// Scroll padding so content clears the pinned add-to-cart bar.
  static double scrollBottomPadding(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return _contentHeight + bottomInset + 12;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 10 + bottomInset),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.12)),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                  color: accent.withValues(alpha: 0.12),
                ),
              ],
            ),
            child: Row(
              children: [
                _QtyStepper(
                  accent: accent,
                  quantity: quantity,
                  onDecrement: onDecrement,
                  onIncrement: onIncrement,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    child: InkWell(
                      onTap: onAddToCart,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, accent.withValues(alpha: 0.78)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                              color: accent.withValues(alpha: 0.36),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Add to cart · $priceLabel',
                                style: GoogleFonts.exo2(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.accent,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final Color accent;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          SizedBox(
            width: 36,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.deepGreen,
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 44,
          child: Icon(icon, size: 20, color: AppColors.deepGreen),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({
    required this.saved,
    required this.pulse,
    required this.onTap,
  });

  final bool saved;
  final AnimationController pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.18).animate(
        CurvedAnimation(parent: pulse, curve: Curves.elasticOut),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: saved
                ? AppColors.terracotta.withValues(alpha: 0.92)
                : Colors.black.withValues(alpha: 0.28),
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  saved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
