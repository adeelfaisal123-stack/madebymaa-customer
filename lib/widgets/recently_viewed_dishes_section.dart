import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/dish_detail_entry.dart';
import '../services/recently_viewed_dishes_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/customer_dish_card.dart';
import 'discover_section_heading.dart';

class RecentlyViewedDishesSection extends StatefulWidget {
  const RecentlyViewedDishesSection({
    super.key,
    required this.entries,
    required this.onDishTap,
  });

  static const maxDishes = 8;
  static const dishesPerPage = 2;

  final List<RecentlyViewedDishEntry> entries;
  final void Function(List<DishDetailEntry> entries, int initialIndex) onDishTap;

  @override
  State<RecentlyViewedDishesSection> createState() =>
      _RecentlyViewedDishesSectionState();
}

class _RecentlyViewedDishesSectionState extends State<RecentlyViewedDishesSection> {
  final _pageController = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries = widget.entries.take(RecentlyViewedDishesSection.maxDishes).toList();
    if (visibleEntries.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final detailEntries = [
      for (var i = 0; i < visibleEntries.length; i++)
        visibleEntries[i].toDetailEntry(i),
    ];

    final screenW = MediaQuery.sizeOf(context).width;
    const horizontalPadding = 20.0;
    const crossGap = 12.0;
    final cardWidth = (screenW - horizontalPadding * 2 - crossGap) / 2;
    final cardHeight = cardWidth / CustomerDishCard.gridAspectRatio;
    final pageCount = (visibleEntries.length + 1) ~/ 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(horizontalPadding, 28, horizontalPadding, 10),
          child: DiscoverSectionHeading(
            title: l10n.recentlyViewedTitle,
            accent: AppColors.deepGreen,
            trailing: pageCount > 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_page + 1} / $pageCount',
                      style: AppFonts.style(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.deepGreen.withValues(alpha: 0.45),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, pageIndex) {
              final firstIndex = pageIndex * RecentlyViewedDishesSection.dishesPerPage;
              final secondIndex = firstIndex + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: _DishTile(
                        entry: visibleEntries[firstIndex],
                        index: firstIndex,
                        onTap: () => widget.onDishTap(detailEntries, firstIndex),
                      ),
                    ),
                    const SizedBox(width: crossGap),
                    Expanded(
                      child: secondIndex < visibleEntries.length
                          ? _DishTile(
                              entry: visibleEntries[secondIndex],
                              index: secondIndex,
                              onTap: () =>
                                  widget.onDishTap(detailEntries, secondIndex),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) {
              final active = _page == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.deepGreen
                      : AppColors.deepGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.entry,
    required this.index,
    required this.onTap,
  });

  final RecentlyViewedDishEntry entry;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final featured = entry.toFeaturedDish();
    return CustomerDishCard(
      dish: CustomerDishCardModel.fromFeatured(featured),
      accent: CustomerDishCard.accentForIndex(index),
      onTap: onTap,
    );
  }
}
