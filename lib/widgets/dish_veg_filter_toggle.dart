import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';

enum DishVegFilter { veg, all, nonVeg }

/// Icon-only veg / all / non-veg toggle for category browse.
class DishVegFilterToggle extends StatelessWidget {
  const DishVegFilterToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DishVegFilter value;
  final ValueChanged<DishVegFilter> onChanged;

  static const height = 40.0;
  static const width = 124.0;
  static const circleSize = 34.0;
  static const trackInset = 3.0;

  static const _options = [
    (
      filter: DishVegFilter.veg,
      icon: Icons.eco_rounded,
      label: null,
      accent: AppColors.sage,
      glow: AppColors.brandPurpleLight,
    ),
    (
      filter: DishVegFilter.all,
      icon: null,
      label: null, // filled from l10n.categoryAll
      accent: AppColors.brandPurple,
      glow: Color(0xFF8B5FD6),
    ),
    (
      filter: DishVegFilter.nonVeg,
      icon: Icons.kebab_dining_rounded,
      label: null,
      accent: AppColors.terracotta,
      glow: Color(0xFFE88B5A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = _options.indexWhere((o) => o.filter == value).clamp(0, 2);
    final accent = _options[index].accent;
    final glow = _options[index].glow;
    final activeOption = _options[index];

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          color: Colors.white,
          border: Border.all(color: accent.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 3),
              color: glow.withValues(alpha: 0.14),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentW = constraints.maxWidth / 3;
            final circleLeft =
                trackInset + index * segmentW + (segmentW - circleSize) / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  left: circleLeft,
                  top: trackInset,
                  width: circleSize,
                  height: circleSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: _SelectionOrb(accent: accent, glow: glow),
                      ),
                      _SegmentContent(
                        icon: activeOption.icon,
                        label: activeOption.filter == DishVegFilter.all
                            ? l10n.categoryAll
                            : activeOption.label,
                        accent: accent,
                        active: true,
                        circleSize: circleSize,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _options.length; i++)
                      _Segment(
                        icon: _options[i].icon,
                        label: _options[i].filter == DishVegFilter.all
                            ? l10n.categoryAll
                            : _options[i].label,
                        accent: _options[i].accent,
                        active: value == _options[i].filter,
                        onTap: () => onChanged(_options[i].filter),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectionOrb extends StatelessWidget {
  const _SelectionOrb({
    required this.accent,
    required this.glow,
  });

  final Color accent;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: glow.withValues(alpha: 0.35),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, Colors.white, 0.2)!,
            accent,
            Color.lerp(accent, Colors.black, 0.1)!,
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final IconData? icon;
  final String? label;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: accent.withValues(alpha: 0.12),
          child: SizedBox(
            height: DishVegFilterToggle.height,
            child: Center(
              child: active
                  ? SizedBox(
                      width: DishVegFilterToggle.circleSize,
                      height: DishVegFilterToggle.circleSize,
                    )
                  : Container(
                      width: DishVegFilterToggle.circleSize,
                      height: DishVegFilterToggle.circleSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.06),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.35),
                          width: 1.4,
                        ),
                      ),
                      child: _SegmentContent(
                        icon: icon,
                        label: label,
                        accent: accent,
                        active: false,
                        circleSize: DishVegFilterToggle.circleSize,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentContent extends StatelessWidget {
  const _SegmentContent({
    required this.icon,
    required this.label,
    required this.accent,
    required this.active,
    required this.circleSize,
  });

  final IconData? icon;
  final String? label;
  final Color accent;
  final bool active;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    if (label != null && icon == null) {
      return Text(
        label!,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: AppFonts.style(
          context,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          color: active ? Colors.white : accent,
        ),
      );
    }

    return Icon(
      icon,
      size: circleSize * 0.5,
      color: active ? Colors.white : accent,
    );
  }
}

extension DishVegFilterX on DishVegFilter {
  bool matchesDish({required bool isVeg}) {
    return switch (this) {
      DishVegFilter.all => true,
      DishVegFilter.veg => isVeg,
      DishVegFilter.nonVeg => !isVeg,
    };
  }
}
