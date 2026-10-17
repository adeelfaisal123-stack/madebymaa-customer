import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_dish_category.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';
import 'customer_search_field.dart';
import 'discover_section_heading.dart';

/// Dish categories on Explore — minimal header and horizontal chip row.
class DishCategoriesSection extends StatelessWidget {
  const DishCategoriesSection({
    super.key,
    required this.categories,
    this.isLoading = false,
    this.onCategoryTap,
  });

  final List<CustomerDishCategory> categories;
  final bool isLoading;
  final ValueChanged<CustomerDishCategory>? onCategoryTap;

  static const _previewCount = 5;
  static const _gridColumns = 3;
  static const _horizontalPadding = 20.0;
  static const _crossGap = 12.0;
  static const _tileSize = 68.0;
  static const _railHeight = 104.0;
  static const _cardRadius = 10.0;

  static ({double imageSize, double aspectRatio}) _gridMetrics(
    BuildContext context,
  ) {
    final screenW = MediaQuery.sizeOf(context).width;
    final cellW =
        (screenW - _horizontalPadding * 2 - _crossGap * (_gridColumns - 1)) /
        _gridColumns;
    const labelGap = 8.0;
    const labelHeight = 32.0;
    final cellH = _tileSize + labelGap + labelHeight;
    return (imageSize: _tileSize, aspectRatio: cellW / cellH);
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoriesSheet(
        categories: categories,
        onSelected: (category) {
          Navigator.of(ctx).pop();
          onCategoryTap?.call(category);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.brandPurple,
            ),
          ),
        ),
      );
    }

    if (categories.isEmpty) return const SizedBox.shrink();

    final preview = categories.take(_previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_horizontalPadding, 24, 12, 0),
          child: DiscoverSectionHeading(
            title: l10n.categoriesTitle,
            accent: AppColors.brandPurple,
            titleFontSize: 22,
            trailing: categories.length > _previewCount
                ? TextButton(
                    onPressed: () => _openSheet(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.viewAll,
                      style: AppFonts.style(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPurple,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _railHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            itemCount: preview.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _CategoryTile(
                category: preview[index],
                onTap: () => onCategoryTap?.call(preview[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onTap,
  });

  final CustomerDishCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DishCategoriesSection._cardRadius),
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              _CategoryAvatar(category: category),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepGreen,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category});

  final CustomerDishCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DishCategoriesSection._tileSize,
      height: DishCategoriesSection._tileSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DishCategoriesSection._cardRadius),
        color: Colors.white,
        border: Border.all(
          color: AppColors.homeLightPurple,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPurple.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _CategoryImage(category: category),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.category});

  final CustomerDishCategory category;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveOptica2AssetUrl(category.imageUrl);
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
        errorBuilder: (_, _, _) => _iconFallback(context),
      );
    }

    return _iconFallback(context);
  }

  Widget _iconFallback(BuildContext context) {
    return ColoredBox(
      color: AppColors.deepGreen.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          _iconForSlug(category.slug),
          color: AppColors.deepGreen.withValues(alpha: 0.35),
          size: 28,
        ),
      ),
    );
  }

  static IconData _iconForSlug(String slug) {
    return switch (slug) {
      'biryani' => Icons.rice_bowl_rounded,
      'rice' => Icons.rice_bowl_outlined,
      'curries' || 'curry' => Icons.soup_kitchen_rounded,
      'snacks' => Icons.cookie_rounded,
      'sweets' => Icons.cake_rounded,
      'bread' || 'roti' => Icons.bakery_dining_rounded,
      _ => Icons.restaurant_rounded,
    };
  }
}

class _CategoriesSheet extends StatefulWidget {
  const _CategoriesSheet({required this.categories, required this.onSelected});

  final List<CustomerDishCategory> categories;
  final ValueChanged<CustomerDishCategory> onSelected;

  @override
  State<_CategoriesSheet> createState() => _CategoriesSheetState();
}

class _CategoriesSheetState extends State<_CategoriesSheet> {
  final _searchController = TextEditingController();

  List<CustomerDishCategory> get _filtered => widget.categories
      .where((c) => categoryMatchesQuery(c.name, _searchController.text))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final metrics = DishCategoriesSection._gridMetrics(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: DiscoverSectionHeading(
                  title: l10n.categoriesTitle,
                  accent: AppColors.brandPurple,
                  titleFontSize: 22,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: CustomerSearchField(
                  controller: _searchController,
                  hint: l10n.searchCategories,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.searchNoCategories,
                          style: AppFonts.style(
                            context,
                            fontSize: 14,
                            color: AppColors.deepGreen.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : GridView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          DishCategoriesSection._horizontalPadding,
                          4,
                          DishCategoriesSection._horizontalPadding,
                          20 + bottomInset,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: DishCategoriesSection._gridColumns,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: DishCategoriesSection._crossGap,
                          childAspectRatio: metrics.aspectRatio,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final category = _filtered[index];
                          return _CategoryTile(
                            category: category,
                            onTap: () => widget.onSelected(category),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

bool categoryMatchesQuery(String name, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return name.toLowerCase().contains(q);
}
