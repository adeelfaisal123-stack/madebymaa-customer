import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_super_category.dart';
import '../theme/app_colors.dart';

/// Meal-time super category filters — matches kitchen page pill style.
class SuperCategoriesRow extends StatelessWidget {
  const SuperCategoriesRow({
    super.key,
    required this.categories,
    required this.allLabel,
    this.selectedId,
    this.isLoading = false,
    this.onSelected,
  });

  final List<CustomerSuperCategory> categories;
  final String allLabel;
  final int? selectedId;
  final bool isLoading;
  final ValueChanged<int?>? onSelected;

  static const rowHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: rowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 20),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandPurple,
              ),
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <_SuperCategoryItem>[
      _SuperCategoryItem(
        id: null,
        name: allLabel,
        timeRange: '',
        slug: 'all',
      ),
      for (final category in categories)
        _SuperCategoryItem(
          id: category.id,
          name: category.name,
          timeRange: category.timeRange,
          slug: category.slug,
        ),
    ];

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final active = selectedId == item.id;
          final accent = _mealAccentFor(item.slug, item.name);
          final icon = item.id == null
              ? Icons.apps_rounded
              : _mealIconFor(item.slug, item.name);

          return _MealTimeFilterChip(
            label: item.name,
            subtitle: item.timeRange.isEmpty ? null : item.timeRange,
            icon: icon,
            accent: accent,
            selected: active,
            onTap: () => onSelected?.call(item.id),
          );
        },
      ),
    );
  }

  static IconData iconForSlug(String slug) => _mealIconFor(slug, slug);

  static IconData _mealIconFor(String slug, String label) {
    final s = slug.toLowerCase();
    final l = label.toLowerCase();
    if (s.contains('all') || l.contains('all')) return Icons.apps_rounded;
    if (s.contains('break') || l.contains('break')) {
      return Icons.breakfast_dining_rounded;
    }
    if (s.contains('lunch') || l.contains('lunch')) {
      return Icons.lunch_dining_rounded;
    }
    if (s.contains('dinner') || l.contains('dinner')) {
      return Icons.dinner_dining_rounded;
    }
    if (s.contains('evening') || l.contains('evening')) {
      return Icons.wb_twilight_rounded;
    }
    if (s.contains('snack') || l.contains('snack')) {
      return Icons.cookie_rounded;
    }
    if (s.contains('sweet') || l.contains('sweet')) {
      return Icons.cake_rounded;
    }
    if (s.contains('brunch') || l.contains('brunch')) {
      return Icons.brunch_dining_rounded;
    }
    if (s.contains('drink') ||
        s.contains('beverage') ||
        l.contains('drink') ||
        l.contains('beverage')) {
      return Icons.local_cafe_rounded;
    }
    return Icons.access_time_rounded;
  }

  static Color _mealAccentFor(String slug, String label) {
    final s = slug.toLowerCase();
    final l = label.toLowerCase();
    if (s.contains('all') || l.contains('all')) return AppColors.brandPurple;
    if (s.contains('break') || l.contains('break')) return AppColors.amberGlow;
    if (s.contains('lunch') || l.contains('lunch')) return AppColors.terracotta;
    if (s.contains('dinner') || l.contains('dinner')) return AppColors.sage;
    if (s.contains('evening') || l.contains('evening')) {
      return AppColors.brandPurple;
    }
    if (s.contains('snack') || l.contains('snack')) {
      return AppColors.brandPurple;
    }
    if (s.contains('sweet') || l.contains('sweet')) {
      return AppColors.terracotta;
    }
    return AppColors.brandPurple;
  }
}

class _SuperCategoryItem {
  const _SuperCategoryItem({
    required this.id,
    required this.name,
    required this.timeRange,
    required this.slug,
  });

  final int? id;
  final String name;
  final String timeRange;
  final String slug;
}

class _MealTimeFilterChip extends StatelessWidget {
  const _MealTimeFilterChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, _shade(accent, 0.78)],
              )
            : null,
        color: selected ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? Colors.transparent : accent.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  color: accent.withValues(alpha: 0.36),
                ),
              ]
            : [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: selected
              ? Colors.white.withValues(alpha: 0.14)
              : accent.withValues(alpha: 0.08),
          highlightColor: selected
              ? Colors.white.withValues(alpha: 0.06)
              : accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : accent,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.exo2(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppColors.deepGreen,
                        height: 1.05,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.exo2(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.86)
                              : AppColors.deepGreen.withValues(alpha: 0.55),
                          height: 1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _shade(Color base, double factor) {
    return Color.from(
      alpha: base.a,
      red: (base.r * factor).clamp(0.0, 1.0),
      green: (base.g * factor).clamp(0.0, 1.0),
      blue: (base.b * factor).clamp(0.0, 1.0),
    );
  }
}
