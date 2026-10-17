import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/customer_featured_dish.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../widgets/customer_dish_card.dart';
import '../widgets/no_dishes_empty_state.dart';
import 'discover_section_heading.dart';
import 'view_all_button.dart';

class FeaturedDishesCarousel extends StatefulWidget {
  const FeaturedDishesCarousel({
    super.key,
    required this.dishes,
    required this.onDishTap,
    this.isLoading = false,
    this.onViewAll,
    this.showViewAll = false,
    this.emptyMessage,
  });

  final List<CustomerFeaturedDish> dishes;
  final void Function(CustomerFeaturedDish dish, int index) onDishTap;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final bool showViewAll;
  final String? emptyMessage;

  @override
  State<FeaturedDishesCarousel> createState() => _FeaturedDishesCarouselState();
}

class _FeaturedDishesCarouselState extends State<FeaturedDishesCarousel> {
  static const _cardHeight = 248.0;
  static const _autoInterval = Duration(seconds: 5);

  final _pageController = PageController(viewportFraction: 0.86);
  Timer? _autoTimer;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    _restartAutoPlay();
  }

  @override
  void didUpdateWidget(FeaturedDishesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dishes.length != widget.dishes.length) {
      _page = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _restartAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _restartAutoPlay() {
    _autoTimer?.cancel();
    if (widget.dishes.length < 2) return;
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted) return;
      final next = (_page + 1) % widget.dishes.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openDish(CustomerFeaturedDish dish, int index) {
    widget.onDishTap(dish, index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 16),
        child: SizedBox(
          height: _cardHeight,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.brandPurple,
              ),
            ),
          ),
        ),
      );
    }

    if (widget.dishes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.emptyMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: NoDishesEmptyState(
                message: widget.emptyMessage!,
                compact: true,
              ),
            ),
          if (widget.showViewAll && widget.onViewAll != null) ...[
            const SizedBox(height: 4),
            ViewAllButton(
              label: l10n.viewAll,
              onTap: widget.onViewAll!,
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: DiscoverSectionHeading(
            title: l10n.tastyDishesTitle,
            subtitle: l10n.tastyDishesSubtitle,
            icon: Icons.restaurant_rounded,
            accent: AppColors.terracotta,
            trailing: widget.dishes.length > 1
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_page + 1} / ${widget.dishes.length}',
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
          height: _cardHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.dishes.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final dish = widget.dishes[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: CustomerDishCard(
                  dish: CustomerDishCardModel.fromFeatured(dish),
                  accent: CustomerDishCard.accentForIndex(index),
                  onTap: () => _openDish(dish, index),
                ),
              );
            },
          ),
        ),
        if (widget.dishes.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.dishes.length, (i) {
              final active = _page == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.brandPurple
                      : AppColors.brandPurple.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
        if (widget.showViewAll && widget.onViewAll != null) ...[
          const SizedBox(height: 12),
          ViewAllButton(
            label: l10n.viewAll,
            onTap: widget.onViewAll!,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
