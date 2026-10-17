import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Title block for Explore tab sections (kitchens, categories, cuisines, etc.).
class DiscoverSectionHeading extends StatelessWidget {
  const DiscoverSectionHeading({
    super.key,
    required this.title,
    this.icon,
    this.accent = AppColors.brandPurple,
    this.subtitle,
    this.trailing,
    this.titleFontSize = 24,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color accent;
  final Widget? trailing;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.style(
                  context,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deepGreen,
                  height: 1.12,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: AppFonts.style(
                    context,
                    fontSize: 13,
                    height: 1.35,
                    color: AppColors.deepGreen.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
