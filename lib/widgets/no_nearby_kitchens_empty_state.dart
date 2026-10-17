import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Nearby tab empty state — sad cartoon illustration and title only.
class NoNearbyKitchensEmptyState extends StatelessWidget {
  const NoNearbyKitchensEmptyState({
    super.key,
    required this.title,
    this.onClearFilters,
    this.clearFiltersLabel,
  });

  final String title;
  final VoidCallback? onClearFilters;
  final String? clearFiltersLabel;

  static const _imageAsset = 'assets/images/empty_nearby_kitchens.png';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 280,
              height: 300,
              child: Image.asset(
                _imageAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.style(
                context,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.deepGreen,
                height: 1.25,
                letterSpacing: -0.2,
              ),
            ),
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
