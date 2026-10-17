import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

class CustomerNavItem {
  const CustomerNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Full-width bottom dock with top-rounded corners and elevated center hub.
class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onChanged,
    this.centerIndex = 2,
  }) : assert(items.length == 5, 'CustomerBottomNav expects exactly 5 items');

  final int currentIndex;
  final List<CustomerNavItem> items;
  final ValueChanged<int> onChanged;
  final int centerIndex;

  static const barHeight = 64.0;
  static const hubRise = 14.0;
  static const topRadius = 24.0;

  /// Scroll/list padding so content clears the docked bar.
  static double contentBottomPadding(BuildContext context) {
    return barHeight +
        hubRise +
        MediaQuery.viewPaddingOf(context).bottom +
        14;
  }

  static BorderRadius get _topBorderRadius =>
      const BorderRadius.vertical(top: Radius.circular(topRadius));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final centerSelected = currentIndex == centerIndex;
    final totalHeight = barHeight + hubRise + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomInset,
            child: _DockedNavBar(
              currentIndex: currentIndex,
              items: items,
              centerIndex: centerIndex,
              bottomInset: bottomInset,
              onChanged: onChanged,
            ),
          ),
          Positioned(
            bottom: barHeight + bottomInset - 26,
            child: _CenterHub(
              item: items[centerIndex],
              selected: centerSelected,
              onTap: () => onChanged(centerIndex),
            ),
          ),
        ],
      ),
    );
  }
}

class _DockedNavBar extends StatelessWidget {
  const _DockedNavBar({
    required this.currentIndex,
    required this.items,
    required this.centerIndex,
    required this.bottomInset,
    required this.onChanged,
  });

  final int currentIndex;
  final List<CustomerNavItem> items;
  final int centerIndex;
  final double bottomInset;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: CustomerBottomNav._topBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandPurpleDeep.withValues(alpha: 0.94),
                const Color(0xFF241040).withValues(alpha: 0.96),
              ],
            ),
            borderRadius: CustomerBottomNav._topBorderRadius,
            border: Border(
              top: BorderSide(
                color: AppColors.brandPurple.withValues(alpha: 0.45),
                width: 1.2,
              ),
              left: BorderSide(
                color: AppColors.brandPurple.withValues(alpha: 0.45),
                width: 1.2,
              ),
              right: BorderSide(
                color: AppColors.brandPurple.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: CustomerBottomNav.barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavTab(
                          item: items[i],
                          selected: currentIndex == i,
                          isCenter: i == centerIndex,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onChanged(i);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.selected,
    required this.isCenter,
    required this.onTap,
  });

  final CustomerNavItem item;
  final bool selected;
  final bool isCenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return SizedBox(
        height: CustomerBottomNav.barHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Spacer(),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: AppFonts.style(
                context,
                fontSize: selected ? 10 : 9,
                height: 1.1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected
                    ? AppColors.amberGlow
                    : Colors.white.withValues(alpha: 0.42),
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    final color = selected
        ? AppColors.amberGlow
        : Colors.white.withValues(alpha: 0.48);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.08),
        child: SizedBox(
          height: CustomerBottomNav.barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 23,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppFonts.style(
                  context,
                  fontSize: selected ? 10 : 9,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: color,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterHub extends StatelessWidget {
  const _CenterHub({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CustomerNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: AnimatedScale(
          scale: selected ? 1.04 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.amberGlow, AppColors.terracotta],
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? const Color(0x80E8C468)
                      : const Color(0x66E8C468),
                  blurRadius: selected ? 20 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              color: AppColors.brandPurpleDeep,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
