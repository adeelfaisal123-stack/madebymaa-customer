import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_featured_kitchen.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';
import 'customer_reviews_section.dart';

/// Kitchen row card used across explore, nearby, and browse-all screens.
class KitchenListCard extends StatelessWidget {
  const KitchenListCard({
    super.key,
    required this.kitchen,
    required this.index,
    required this.onTap,
    this.animate = true,
    this.showSubtitle = false,
  });

  /// Vertical gap between cards in lists.
  static const listSeparatorHeight = 22.0;

  final CustomerFeaturedKitchen kitchen;
  final int index;
  final VoidCallback onTap;
  final bool animate;
  final bool showSubtitle;

  static const _cardHeight = 110.0;
  static const _imageWidth = 108.0;
  static const _imageHeight = 124.0;
  static const _tagRowHeight = 22.0;
  static const _arrowTabWidth = 42.0;
  static const _arrowTabHeight = 36.0;
  static const _cardRadius = BorderRadius.all(Radius.circular(22));

  static const _contentPaddingV = 6.0;
  static const _detailsRightPadding = 12.0;
  static const _titleGap = 2.0;
  static const _beforeMetaGap = 2.0;
  static const _metaInnerGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final accent = switch (index % 3) {
      0 => AppColors.brandPurple,
      1 => AppColors.deepGreen,
      _ => AppColors.sage,
    };

    final coverUrl =
        resolveOptica2AssetUrl(kitchen.coverUrl) ??
        resolveOptica2AssetUrl(kitchen.logoUrl);
    final tags = kitchen.tags.take(2).toList();

    final coverPanel = _KitchenCoverPanel(
      coverUrl: coverUrl,
      accent: accent,
      width: _imageWidth,
      height: _imageHeight,
    );
    final details = Expanded(child: _buildDetails(context, accent, tags));

    final card = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _cardHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: _cardRadius,
                  color: Colors.white,
                  border: Border.all(color: accent.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      color: accent.withValues(alpha: 0.1),
                    ),
                    BoxShadow(
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    SizedBox(width: _imageWidth + 12),
                    details,
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: (_cardHeight - _imageHeight) / 2,
              child: coverPanel,
            ),
            _buildCardArrow(accent),
          ],
        ),
      ),
    );

    if (!animate) return card;

    return _KitchenCardLoadAnimation(index: index, child: card);
  }

  Widget _buildCardArrow(Color accent) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: _arrowTabWidth,
        height: _arrowTabHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              accent.withValues(alpha: 0.14),
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(22),
          ),
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.16)),
            left: BorderSide(color: accent.withValues(alpha: 0.16)),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(-2, -2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 17,
          color: accent,
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    Color accent,
    List<String> tags,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        0,
        _contentPaddingV,
        _detailsRightPadding,
        _contentPaddingV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kitchen.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.style(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
              height: 1.12,
            ),
          ),
          if (showSubtitle) ...[
            const SizedBox(height: _titleGap),
            Text(
              kitchen.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.style(
                context,
                fontSize: 12.5,
                color: AppColors.deepGreen.withValues(alpha: 0.58),
                height: 1.2,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: _titleGap),
            SizedBox(
              height: _tagRowHeight,
              child: Row(
                children: [
                  for (var i = 0; i < tags.length; i++) ...[
                    Flexible(
                      child: KitchenTagChip(
                        label: tags[i],
                        color: i.isEven ? AppColors.sage : accent,
                      ),
                    ),
                    if (i != tags.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: _beforeMetaGap),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingSummaryRow(
                average: kitchen.rating.average,
                count: kitchen.rating.count,
                compact: true,
              ),
              SizedBox(height: _metaInnerGap),
              KitchenCardStatusBadges(
                kitchen: kitchen,
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KitchenCardLoadAnimation extends StatefulWidget {
  const _KitchenCardLoadAnimation({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_KitchenCardLoadAnimation> createState() =>
      _KitchenCardLoadAnimationState();
}

class _KitchenCardLoadAnimationState extends State<_KitchenCardLoadAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    final delayIndex = widget.index > 4 ? 4 : widget.index;
    Future<void>.delayed(Duration(milliseconds: 45 * delayIndex), () {
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(18 * (1 - value), 8 * (1 - value)),
            child: Transform.scale(
              alignment: Alignment.centerLeft,
              scale: 0.96 + (0.04 * value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _KitchenCoverPanel extends StatelessWidget {
  const _KitchenCoverPanel({
    required this.coverUrl,
    required this.accent,
    required this.width,
    required this.height,
  });

  final String? coverUrl;
  final Color accent;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomRight: Radius.circular(22),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: coverUrl != null && coverUrl!.isNotEmpty
                  ? Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _KitchenCoverFallback(accent: accent),
                    )
                  : _KitchenCoverFallback(accent: accent),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.5)],
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

class _KitchenCoverFallback extends StatelessWidget {
  const _KitchenCoverFallback({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.soup_kitchen_rounded,
        color: accent.withValues(alpha: 0.75),
        size: 34,
      ),
    );
  }
}

/// Open / closed badges for kitchen list cards.
class KitchenCardStatusBadges extends StatelessWidget {
  const KitchenCardStatusBadges({
    super.key,
    required this.kitchen,
    this.compact = true,
    this.alignment = Alignment.centerLeft,
  });

  final CustomerFeaturedKitchen kitchen;
  final bool compact;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kitchen.isClosed)
            KitchenClosedBadge(compact: compact)
          else
            KitchenOpenBadge(compact: compact),
        ],
      ),
    );
  }
}

/// Attractive banner for closed kitchens on the kitchen profile page.
class KitchenClosedProfileBanner extends StatelessWidget {
  const KitchenClosedProfileBanner({super.key, this.onPreOrderTap});

  final VoidCallback? onPreOrderTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.amberGlow.withValues(alpha: 0.14),
              AppColors.brandPurple.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.brandPurple.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              offset: const Offset(0, 10),
              color: AppColors.brandPurple.withValues(alpha: 0.08),
            ),
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 2),
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: Column(
            children: [
              const _KitchenClosedProfileIllustration(),
              const SizedBox(height: 18),
              Text(
                l10n.kitchenClosedProfileTitle,
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.kitchenClosedProfileSubtitle,
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  context,
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.deepGreen.withValues(alpha: 0.62),
                ),
              ),
              if (onPreOrderTap != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPreOrderTap,
                    icon: const Icon(Icons.event_available_rounded, size: 20),
                    label: Text(
                      l10n.kitchenClosedPreOrderButton,
                      style: AppFonts.style(
                        context,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenClosedProfileIllustration extends StatelessWidget {
  const _KitchenClosedProfileIllustration();

  static const _warmAmber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.amberGlow.withValues(alpha: 0.35),
                  AppColors.brandPurple.withValues(alpha: 0.12),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  color: AppColors.brandPurple.withValues(alpha: 0.12),
                ),
              ],
            ),
            child: const SizedBox(
              width: 96,
              height: 96,
              child: Center(
                child: Icon(
                  Icons.restaurant_rounded,
                  size: 42,
                  color: AppColors.terracotta,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: _warmAmber.withValues(alpha: 0.35),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.nightlight_round,
                  size: 20,
                  color: _warmAmber.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.brandPurple,
                    AppColors.brandPurpleDeep,
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: AppColors.brandPurple.withValues(alpha: 0.35),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge shown when a kitchen is accepting orders.
class KitchenOpenBadge extends StatelessWidget {
  const KitchenOpenBadge({super.key, this.compact = false});

  final bool compact;

  static const _greenLight = Color(0xFF6EE7B7);
  static const _greenMid = Color(0xFF22C55E);
  static const _greenDeep = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dotSize = compact ? 6.0 : 7.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenLight, _greenMid, _greenDeep],
          stops: [0.0, 0.45, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: _greenMid.withValues(alpha: 0.38),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: dotSize + 4,
            height: dotSize + 4,
            child: Center(
              child: _KitchenStatusHeartbeat(
                color: Colors.white,
                size: dotSize,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.kitchenOpen,
            style: AppFonts.style(
              context,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge shown when a kitchen is not accepting orders.
class KitchenClosedBadge extends StatelessWidget {
  const KitchenClosedBadge({super.key, this.compact = false});

  final bool compact;

  static const _danger = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final iconSize = compact ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: _danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _KitchenStatusHeartbeat(
            color: _danger,
            size: iconSize,
            child: Icon(
              Icons.lock_clock_rounded,
              size: iconSize,
              color: _danger,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            l10n.kitchenClosed,
            style: AppFonts.style(
              context,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              color: _danger,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Double-beat pulse used for Open / Closed status indicators.
class _KitchenStatusHeartbeat extends StatefulWidget {
  const _KitchenStatusHeartbeat({
    required this.color,
    required this.size,
    required this.child,
  });

  final Color color;
  final double size;
  final Widget child;

  @override
  State<_KitchenStatusHeartbeat> createState() => _KitchenStatusHeartbeatState();
}

class _KitchenStatusHeartbeatState extends State<_KitchenStatusHeartbeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _beatScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _beatScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.42), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.42, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.24), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.24, end: 1.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
    ]).animate(_controller);

    _ringScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 2.4), weight: 3),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 2.1), weight: 3),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 5),
    ]).animate(_controller);

    _ringOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0.0), weight: 3),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 3),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size + 4,
      height: widget.size + 4,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.scale(
                scale: _ringScale.value,
                child: Opacity(
                  opacity: _ringOpacity.value.clamp(0.0, 1.0),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              );
            },
          ),
          ScaleTransition(scale: _beatScale, child: widget.child),
        ],
      ),
    );
  }
}

class KitchenTagChip extends StatelessWidget {
  const KitchenTagChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.style(
          context,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}
