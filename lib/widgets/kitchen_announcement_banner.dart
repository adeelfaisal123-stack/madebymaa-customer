import 'package:flutter/material.dart';

import '../models/customer_kitchen_announcement.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

/// Read-only seller announcement on the kitchen profile.
class KitchenAnnouncementBanner extends StatelessWidget {
  const KitchenAnnouncementBanner({
    super.key,
    required this.announcement,
  });

  final CustomerKitchenAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    final type = announcement.type ?? KitchenAnnouncementType.general;
    final accent = _accentFor(type);
    final typeLabel = announcement.displayTypeLabel;
    final description = announcement.description?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: accent.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(type.icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (typeLabel.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        typeLabel,
                        style: AppFonts.style(
                          context,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: accent,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    announcement.title.trim(),
                    style: AppFonts.style(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepGreen,
                      height: 1.25,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppFonts.style(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.deepGreen.withValues(alpha: 0.62),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _accentFor(KitchenAnnouncementType type) {
    return switch (type) {
      KitchenAnnouncementType.general => AppColors.brandPurple,
      KitchenAnnouncementType.offer => AppColors.sage,
      KitchenAnnouncementType.holiday => AppColors.terracotta,
      KitchenAnnouncementType.menuUpdate => AppColors.deepGreen,
    };
  }
}
