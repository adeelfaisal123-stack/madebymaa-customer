import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Friendly empty state when no dishes are available to show.
class NoDishesEmptyState extends StatelessWidget {
  const NoDishesEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.compact = false,
    this.forSearch = false,
  });

  final String message;
  final String? subtitle;
  final bool compact;

  /// Sad Maa mascot tuned for search-with-no-results (vs generic empty menu).
  final bool forSearch;

  static const _imageAsset = 'assets/images/empty_dishes.png';
  static const _searchImageAsset = 'assets/images/empty_dishes_search.png';

  @override
  Widget build(BuildContext context) {
    final imageWidth = compact ? 200.0 : 280.0;
    final imageHeight = compact ? 220.0 : 300.0;
    final horizontalPad = compact ? 24.0 : 28.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPad,
          vertical: compact ? 20 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: imageWidth,
              height: imageHeight,
              child: Image.asset(
                forSearch ? _searchImageAsset : _imageAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, _, _) => _IllustrationFallback(
                  size: imageWidth,
                ),
              ),
            ),
            SizedBox(height: compact ? 18 : 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.style(
                context,
                fontSize: compact ? 17 : 20,
                fontWeight: FontWeight.w900,
                color: AppColors.deepGreen,
                height: 1.25,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  context,
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.deepGreen.withValues(alpha: 0.58),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IllustrationFallback extends StatelessWidget {
  const _IllustrationFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPurple.withValues(alpha: 0.18),
            AppColors.sage.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: size * 0.34,
        color: AppColors.brandPurple.withValues(alpha: 0.72),
      ),
    );
  }
}
