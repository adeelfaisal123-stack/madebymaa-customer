import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Light purple CTA for "View all" sections on the home screen.
class ViewAllButton extends StatelessWidget {
  const ViewAllButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          color: AppColors.homeLightPurple,
          border: Border.all(
            color: AppColors.brandPurple.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPurple.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.brandPurple.withValues(alpha: 0.08),
            highlightColor: AppColors.brandPurple.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppFonts.style(
                    context,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPurpleDeep,
                    height: 1.1,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
