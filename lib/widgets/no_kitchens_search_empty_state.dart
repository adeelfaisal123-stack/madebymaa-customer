import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Creative empty state when kitchen search or filters return no results.
class NoKitchensSearchEmptyState extends StatelessWidget {
  const NoKitchensSearchEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.onClearFilters,
    this.clearFiltersLabel,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClearFilters;
  final String? clearFiltersLabel;
  final bool compact;

  static const _imageAsset = 'assets/images/empty_kitchens_search.png';

  @override
  Widget build(BuildContext context) {
    final horizontalPad = compact ? 24.0 : 32.0;
    final illustrationSize = compact ? 200.0 : 240.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPad,
          vertical: compact ? 24 : 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: illustrationSize,
              height: illustrationSize * 0.92,
              child: Image.asset(
                _imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _KitchenSearchEmptyIllustration(
                  size: illustrationSize,
                ),
              ),
            ),
            SizedBox(height: compact ? 20 : 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.style(
                context,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: AppColors.deepGreen,
                height: 1.2,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  context,
                  fontSize: compact ? 13 : 15,
                  height: 1.5,
                  color: AppColors.deepGreen.withValues(alpha: 0.58),
                ),
              ),
            ],
            if (onClearFilters != null &&
                clearFiltersLabel != null &&
                clearFiltersLabel!.isNotEmpty) ...[
              const SizedBox(height: 22),
              FilledButton.tonalIcon(
                onPressed: onClearFilters,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPurple.withValues(alpha: 0.1),
                  foregroundColor: AppColors.brandPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  clearFiltersLabel!,
                  style: AppFonts.style(
                    context,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KitchenSearchEmptyIllustration extends StatelessWidget {
  const _KitchenSearchEmptyIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cardW = size * 0.62;
    final cardH = size * 0.52;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: size * 0.06,
          left: size * 0.08,
          child: _GlowOrb(
            diameter: size * 0.42,
            colors: [
              AppColors.brandPurple.withValues(alpha: 0.22),
              AppColors.brandPurple.withValues(alpha: 0.02),
            ],
          ),
        ),
        Positioned(
          bottom: size * 0.04,
          right: size * 0.04,
          child: _GlowOrb(
            diameter: size * 0.34,
            colors: [
              AppColors.sage.withValues(alpha: 0.28),
              AppColors.sage.withValues(alpha: 0.02),
            ],
          ),
        ),
        Positioned(
          top: size * 0.12,
          right: size * 0.14,
          child: _FloatingBadge(
            icon: Icons.search_rounded,
            color: AppColors.brandPurple,
            size: size * 0.16,
          ),
        ),
        Positioned(
          bottom: size * 0.16,
          left: size * 0.1,
          child: _FloatingBadge(
            icon: Icons.ramen_dining_rounded,
            color: AppColors.terracotta,
            size: size * 0.14,
          ),
        ),
        Container(
          width: cardW,
          height: cardH,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.1),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 28,
                offset: const Offset(0, 14),
                color: AppColors.brandPurple.withValues(alpha: 0.14),
              ),
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 4),
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: cardH * 0.16,
                child: Icon(
                  Icons.storefront_rounded,
                  size: size * 0.18,
                  color: AppColors.brandPurple.withValues(alpha: 0.16),
                ),
              ),
              CustomPaint(
                size: Size(cardW * 0.72, cardH * 0.42),
                painter: _EmptySearchCurvePainter(),
              ),
              Positioned(
                bottom: cardH * 0.14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MiniDot(color: AppColors.brandPurple.withValues(alpha: 0.35)),
                    const SizedBox(width: 6),
                    _MiniDot(color: AppColors.sage.withValues(alpha: 0.45)),
                    const SizedBox(width: 6),
                    _MiniDot(color: AppColors.terracotta.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: size * 0.02,
          right: size * 0.22,
          child: Container(
            width: size * 0.18,
            height: size * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  color: AppColors.brandPurple.withValues(alpha: 0.28),
                ),
              ],
            ),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: size * 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.diameter,
    required this.colors,
  });

  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 5),
            color: color.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class _MiniDot extends StatelessWidget {
  const _MiniDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptySearchCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.deepGreen.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.18,
        size.width * 0.92,
        size.height * 0.72,
      );

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.34),
      size.width * 0.12,
      Paint()
        ..color = AppColors.brandPurple.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawLine(
      Offset(size.width * 0.8, size.height * 0.46),
      Offset(size.width * 0.92, size.height * 0.58),
      Paint()
        ..color = AppColors.brandPurple.withValues(alpha: 0.22)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
