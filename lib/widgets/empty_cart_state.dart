import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Empty cart state — sad Maa mascot illustration, title, and optional browse CTA.
class EmptyCartState extends StatelessWidget {
  const EmptyCartState({
    super.key,
    required this.title,
    this.subtitle,
    this.browseLabel,
    this.onBrowse,
  });

  final String title;
  final String? subtitle;
  final String? browseLabel;
  final VoidCallback? onBrowse;

  static const _imageAsset = 'assets/images/empty_cart.png';

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
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  context,
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.deepGreen.withValues(alpha: 0.58),
                ),
              ),
            ],
            if (onBrowse != null &&
                browseLabel != null &&
                browseLabel!.isNotEmpty) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onBrowse,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                label: Text(
                  browseLabel!,
                  style: AppFonts.style(
                    context,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
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
