import 'package:flutter/material.dart';

import '../models/customer_dish_subcategory.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';

/// Horizontal sub category chips below search when browsing a dish category.
class DishSubcategoriesRow extends StatelessWidget {
  const DishSubcategoriesRow({
    super.key,
    required this.subcategories,
    required this.allLabel,
    this.selectedId,
    this.isLoading = false,
    this.onSelected,
  });

  final List<CustomerDishSubcategory> subcategories;
  final String allLabel;
  final int? selectedId;
  final bool isLoading;
  final ValueChanged<int?>? onSelected;

  static const rowHeight = 44.0;

  static const _accentColors = [
    AppColors.brandPurple,
    AppColors.terracotta,
    AppColors.sage,
    AppColors.deepGreen,
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: rowHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandPurple,
            ),
          ),
        ),
      );
    }

    if (subcategories.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = <_SubcategoryItem>[
      _SubcategoryItem(id: null, name: allLabel, slug: 'all'),
      for (var i = 0; i < subcategories.length; i++)
        _SubcategoryItem(
          id: subcategories[i].id,
          name: subcategories[i].name,
          slug: subcategories[i].slug,
          imageUrl: subcategories[i].imageUrl,
        ),
    ];

    return SizedBox(
      height: rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final active = selectedId == item.id;
          final accent = _accentColors[i % _accentColors.length];

          return _SubcategoryChip(
            item: item,
            accent: accent,
            active: active,
            onTap: () => onSelected?.call(item.id),
          );
        },
      ),
    );
  }
}

class _SubcategoryItem {
  const _SubcategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
  });

  final int? id;
  final String name;
  final String slug;
  final String? imageUrl;
}

class _SubcategoryChip extends StatelessWidget {
  const _SubcategoryChip({
    required this.item,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final _SubcategoryItem item;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: DishSubcategoriesRow.rowHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent,
                      Color.lerp(accent, Colors.black, 0.12)!,
                    ],
                  )
                : null,
            color: active ? null : Colors.white,
            border: Border.all(
              color: active
                  ? accent.withValues(alpha: 0.0)
                  : accent.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white.withValues(alpha: 0.22)
                        : accent.withValues(alpha: 0.12),
                    border: Border.all(
                      color: active
                          ? Colors.white.withValues(alpha: 0.35)
                          : accent.withValues(alpha: 0.18),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _SubcategoryThumb(
                    item: item,
                    accent: accent,
                    active: active,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.name,
                  style: AppFonts.style(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: active ? Colors.white : AppColors.deepGreen,
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

class _SubcategoryThumb extends StatelessWidget {
  const _SubcategoryThumb({
    required this.item,
    required this.accent,
    required this.active,
  });

  final _SubcategoryItem item;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (item.slug == 'all') {
      return Icon(
        Icons.apps_rounded,
        size: 16,
        color: active ? Colors.white : accent,
      );
    }

    final imageUrl = resolveOptica2AssetUrl(item.imageUrl);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        headers: const {
          'User-Agent': 'MadeByMaa-Customer/1.0',
          'Accept': 'image/*',
        },
        errorBuilder: (_, _, _) => _iconFallback(),
      );
    }

    return _iconFallback();
  }

  Widget _iconFallback() {
    return ColoredBox(
      color: accent.withValues(alpha: active ? 0.08 : 0.06),
      child: Center(
        child: Icon(
          _iconForSlug(item.slug),
          size: 16,
          color: active ? Colors.white : accent,
        ),
      ),
    );
  }

  static IconData _iconForSlug(String slug) {
    if (slug.contains('biryani')) return Icons.rice_bowl_rounded;
    if (slug.contains('rice')) return Icons.rice_bowl_outlined;
    if (slug.contains('curry') || slug.contains('dal') || slug.contains('paneer')) {
      return Icons.soup_kitchen_rounded;
    }
    if (slug.contains('samosa') ||
        slug.contains('pakora') ||
        slug.contains('sandwich')) {
      return Icons.cookie_rounded;
    }
    if (slug.contains('jamun') ||
        slug.contains('jalebi') ||
        slug.contains('kheer') ||
        slug.contains('sweet')) {
      return Icons.cake_rounded;
    }
    if (slug.contains('naan') ||
        slug.contains('roti') ||
        slug.contains('paratha') ||
        slug.contains('bread')) {
      return Icons.bakery_dining_rounded;
    }
    if (slug.contains('lassi') ||
        slug.contains('chai') ||
        slug.contains('juice') ||
        slug.contains('coffee')) {
      return Icons.local_cafe_rounded;
    }
    return Icons.restaurant_rounded;
  }
}
