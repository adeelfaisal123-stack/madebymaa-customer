import 'package:flutter/material.dart';

import '../models/customer_cuisine.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/app_system_ui.dart';
import '../utils/optica2_asset_url.dart';
import 'customer_search_field.dart';
import 'floating_food_icons.dart';

/// Shared hero, sticky bar, and cuisine filter for kitchen browse screens.
abstract final class KitchenBrowseChrome {
  static const waveHeight = 48.0;
}

class KitchenBrowseMeasureSize extends StatefulWidget {
  const KitchenBrowseMeasureSize({
    super.key,
    required this.onChange,
    required this.child,
  });

  final ValueChanged<double> onChange;
  final Widget child;

  @override
  State<KitchenBrowseMeasureSize> createState() =>
      _KitchenBrowseMeasureSizeState();
}

class _KitchenBrowseMeasureSizeState extends State<KitchenBrowseMeasureSize> {
  final _key = GlobalKey();
  double _lastHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  void didUpdateWidget(covariant KitchenBrowseMeasureSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  void _reportSize() {
    final context = _key.currentContext;
    if (context == null) return;
    final height = context.size?.height ?? 0;
    if (height > 0 && height != _lastHeight) {
      _lastHeight = height;
      widget.onChange(height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class KitchenBrowseHero extends StatelessWidget {
  const KitchenBrowseHero({
    super.key,
    required this.title,
    required this.searchHint,
    required this.searchController,
    required this.onSearchChanged,
    required this.onHeightResolved,
    this.showBackButton = false,
    this.onBack,
    this.foodIconSeed = 19,
    this.trailing,
    this.lightBackground = false,
  });

  final String title;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<double> onHeightResolved;
  final bool showBackButton;
  final VoidCallback? onBack;
  final int foodIconSeed;
  final Widget? trailing;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    final top = AppSystemUi.topInset(context, 8);
    final light = lightBackground;

    return KitchenBrowseMeasureSize(
      onChange: onHeightResolved,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: light
                ? const BoxDecoration(color: AppColors.homeLightPurple)
                : const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
                    ),
                  ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FloatingFoodIcons(
                    opacity: light ? 0.12 : 0.14,
                    count: 12,
                    seed: foodIconSeed,
                    entrance: false,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    top + 8,
                    16,
                    KitchenBrowseChrome.waveHeight + 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showBackButton) ...[
                            KitchenBrowseBackButton(
                              onTap: onBack ?? () {},
                              light: !light,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.style(
                                context,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: light
                                    ? AppColors.brandPurpleDeep
                                    : Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            trailing!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomerSearchField(
                        controller: searchController,
                        hint: searchHint,
                        onChanged: onSearchChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: KitchenBrowseChrome.waveHeight,
            child: CustomPaint(
              painter: light
                  ? const KitchenBrowseHeroLightWavePainter()
                  : const KitchenBrowseHeroWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Title hero without search — profile and similar tabs.
class KitchenBrowseTitleHero extends StatelessWidget {
  const KitchenBrowseTitleHero({
    super.key,
    required this.title,
    required this.onHeightResolved,
    this.subtitle,
    this.foodIconSeed = 19,
    this.showBackButton = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final ValueChanged<double> onHeightResolved;
  final int foodIconSeed;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = AppSystemUi.topInset(context, 8);

    return KitchenBrowseMeasureSize(
      onChange: onHeightResolved,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: FloatingFoodIcons(
                    opacity: 0.14,
                    count: 12,
                    seed: foodIconSeed,
                    entrance: false,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    top + 8,
                    16,
                    KitchenBrowseChrome.waveHeight + 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showBackButton) ...[
                            KitchenBrowseBackButton(
                              onTap: onBack ?? () {},
                              light: true,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.style(
                                context,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            context,
                            fontSize: 13,
                            height: 1.35,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: KitchenBrowseChrome.waveHeight,
            child: CustomPaint(
              painter: KitchenBrowseHeroWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class KitchenBrowseStickyTitleBar extends StatelessWidget {
  const KitchenBrowseStickyTitleBar({
    super.key,
    required this.topInset,
    required this.title,
    this.trailing,
    this.showBackButton = false,
    this.onBack,
  });

  final double topInset;
  final String title;
  final Widget? trailing;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return KitchenBrowseStickyShell(
      topInset: topInset,
      child: Row(
        children: [
          if (showBackButton) ...[
            KitchenBrowseBackButton(
              onTap: onBack ?? () {},
              light: true,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.style(
                context,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class KitchenBrowseStickyBar extends StatelessWidget {
  const KitchenBrowseStickyBar({
    super.key,
    required this.topInset,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    this.showBackButton = false,
    this.onBack,
    this.trailing,
    this.lightBackground = false,
  });

  final double topInset;
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool lightBackground;

  @override
  Widget build(BuildContext context) {
    return KitchenBrowseStickyShell(
      topInset: topInset,
      lightGradient: lightBackground,
      child: Row(
        children: [
          if (showBackButton) ...[
            KitchenBrowseBackButton(
              onTap: onBack ?? () {},
              light: !lightBackground,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: CustomerSearchField(
              controller: searchController,
              hint: searchHint,
              onChanged: onSearchChanged,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Purple gradient sticky strip with bottom wave — pass any toolbar [child].
class KitchenBrowseStickyShell extends StatelessWidget {
  const KitchenBrowseStickyShell({
    super.key,
    required this.topInset,
    required this.child,
    this.lightGradient = false,
  });

  final double topInset;
  final Widget child;
  final bool lightGradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: lightGradient ? AppColors.homeLightPurple : Colors.transparent,
      elevation: lightGradient ? 0 : 4,
      shadowColor: AppColors.brandPurple.withValues(alpha: lightGradient ? 0.1 : 0.22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: lightGradient ? AppColors.homeLightPurple : null,
              gradient: lightGradient
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.brandPurple,
                        AppColors.brandPurpleDeep,
                      ],
                    ),
              boxShadow: lightGradient
                  ? [
                      BoxShadow(
                        color: AppColors.brandPurple.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, topInset, 12, 10),
              child: child,
            ),
          ),
          SizedBox(
            height: KitchenBrowseChrome.waveHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: lightGradient
                  ? const KitchenBrowseStickyLightWavePainter()
                  : const KitchenBrowseStickyWavePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class KitchenBrowseCuisineFilter extends StatelessWidget {
  const KitchenBrowseCuisineFilter({
    super.key,
    required this.allLabel,
    required this.cuisines,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  final String allLabel;
  final List<CustomerCuisine> cuisines;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            KitchenBrowseCuisineChip(
              label: allLabel,
              selected: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final cuisine in cuisines) ...[
              const SizedBox(width: 8),
              KitchenBrowseCuisineChip(
                label: cuisine.name,
                cuisine: cuisine,
                selected: selected == cuisine.name,
                onTap: () => onSelected(cuisine.name),
              ),
            ],
            if (trailing != null) ...trailing!,
          ],
        ),
      ),
    );
  }
}

/// Multi-select cuisine picker with images (e.g. Nearby tab).
class KitchenBrowseCuisineDropdown extends StatelessWidget {
  const KitchenBrowseCuisineDropdown({
    super.key,
    required this.allLabel,
    required this.cuisineLabel,
    required this.cuisines,
    required this.selected,
    required this.onChanged,
    this.trailing,
  });

  final String allLabel;
  final String cuisineLabel;
  final List<CustomerCuisine> cuisines;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final List<Widget>? trailing;

  String _summaryLabel() {
    if (selected.isEmpty) return '$cuisineLabel · $allLabel';
    if (selected.length == 1) return selected.first;
    return '$cuisineLabel · ${selected.length} selected';
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CuisineMultiSelectSheet(
        allLabel: allLabel,
        cuisineLabel: cuisineLabel,
        cuisines: cuisines,
        initialSelected: Set<String>.from(selected),
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final active = selected.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openPicker(context),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? AppColors.brandPurple.withValues(alpha: 0.45)
                          : AppColors.deepGreen.withValues(alpha: 0.08),
                      width: active ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: active ? 14 : 10,
                        offset: const Offset(0, 4),
                        color: active
                            ? AppColors.brandPurple.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        size: 18,
                        color: active
                            ? AppColors.brandPurple
                            : AppColors.deepGreen.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _summaryLabel(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            context,
                            fontSize: 13,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w700,
                            color: active
                                ? AppColors.brandPurple
                                : AppColors.deepGreen,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.deepGreen.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...trailing!,
        ],
      ),
    );
  }
}

class _CuisineMultiSelectSheet extends StatefulWidget {
  const _CuisineMultiSelectSheet({
    required this.allLabel,
    required this.cuisineLabel,
    required this.cuisines,
    required this.initialSelected,
  });

  final String allLabel;
  final String cuisineLabel;
  final List<CustomerCuisine> cuisines;
  final Set<String> initialSelected;

  @override
  State<_CuisineMultiSelectSheet> createState() =>
      _CuisineMultiSelectSheetState();
}

class _CuisineMultiSelectSheetState extends State<_CuisineMultiSelectSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
  }

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  void _selectAll() => setState(() => _selected.clear());

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.cuisineLabel,
                      style: AppFonts.style(
                        context,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepGreen,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectAll,
                    child: Text(
                      widget.allLabel,
                      style: AppFonts.style(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                itemCount: widget.cuisines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cuisine = widget.cuisines[index];
                  final checked = _selected.contains(cuisine.name);
                  return _CuisineMultiSelectTile(
                    cuisine: cuisine,
                    checked: checked,
                    onTap: () => _toggle(cuisine.name),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _selected.isEmpty
                        ? 'Show all cuisines'
                        : 'Apply (${_selected.length})',
                    style: AppFonts.style(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuisineMultiSelectTile extends StatelessWidget {
  const _CuisineMultiSelectTile({
    required this.cuisine,
    required this.checked,
    required this.onTap,
  });

  final CustomerCuisine cuisine;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: checked
                  ? AppColors.brandPurple.withValues(alpha: 0.45)
                  : AppColors.deepGreen.withValues(alpha: 0.08),
              width: checked ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: _KitchenBrowseCuisineImage(cuisine: cuisine),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cuisine.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    context,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: checked ? AppColors.brandPurple : AppColors.deepGreen,
                  ),
                ),
              ),
              Icon(
                checked
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 22,
                color: checked
                    ? AppColors.brandPurple
                    : AppColors.deepGreen.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimum star rating filter for kitchen browse screens.
class KitchenBrowseStarRatingDropdown extends StatelessWidget {
  const KitchenBrowseStarRatingDropdown({
    super.key,
    required this.allLabel,
    required this.ratingLabel,
    required this.minStars,
    required this.onChanged,
  });

  final String allLabel;
  final String ratingLabel;
  final int? minStars;
  final ValueChanged<int?> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StarRatingPickerSheet(
        allLabel: allLabel,
        ratingLabel: ratingLabel,
        selected: minStars,
        onSelect: (value) {
          onChanged(value);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = minStars != null;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? AppColors.amberGlow.withValues(alpha: 0.55)
                    : AppColors.deepGreen.withValues(alpha: 0.08),
                width: active ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: active ? 14 : 10,
                  offset: const Offset(0, 4),
                  color: active
                      ? AppColors.amberGlow.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(10, 11, 8, 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 17,
                  color: active
                      ? AppColors.amberGlow
                      : AppColors.deepGreen.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                if (active)
                  _StarRatingRow(
                    stars: minStars!,
                    size: 12,
                    activeColor: AppColors.amberGlow,
                  )
                else
                  Text(
                    ratingLabel,
                    style: AppFonts.style(
                      context,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepGreen,
                    ),
                  ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.deepGreen.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRatingPickerSheet extends StatelessWidget {
  const _StarRatingPickerSheet({
    required this.allLabel,
    required this.ratingLabel,
    required this.selected,
    required this.onSelect,
  });

  final String allLabel;
  final String ratingLabel;
  final int? selected;
  final ValueChanged<int?> onSelect;

  static const _options = [5, 4, 3, 2, 1];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 28,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ratingLabel,
                  style: AppFonts.style(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
            ),
            _StarRatingOptionTile(
              label: allLabel,
              selected: selected == null,
              onTap: () => onSelect(null),
              child: Icon(
                Icons.star_outline_rounded,
                size: 22,
                color: AppColors.deepGreen.withValues(alpha: 0.35),
              ),
            ),
            for (final stars in _options)
              _StarRatingOptionTile(
                label: '$stars★ & up',
                selected: selected == stars,
                onTap: () => onSelect(stars),
                child: _StarRatingRow(
                  stars: stars,
                  size: 18,
                  activeColor: AppColors.amberGlow,
                ),
              ),
            SizedBox(height: 12 + bottomInset),
          ],
        ),
      ),
    );
  }
}

class _StarRatingOptionTile extends StatelessWidget {
  const _StarRatingOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.amberGlow.withValues(alpha: 0.55)
                    : AppColors.deepGreen.withValues(alpha: 0.08),
                width: selected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(
              children: [
                child,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppFonts.style(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? AppColors.deepGreen
                          : AppColors.deepGreen.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: AppColors.amberGlow,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.stars,
    this.size = 14,
    this.activeColor = AppColors.amberGlow,
  });

  final int stars;
  final double size;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i <= stars
                ? activeColor
                : AppColors.deepGreen.withValues(alpha: 0.2),
          ),
      ],
    );
  }
}

class KitchenBrowseFilterChip extends StatelessWidget {
  const KitchenBrowseFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.brandPurple.withValues(alpha: 0.5)
                  : AppColors.deepGreen.withValues(alpha: 0.08),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: selected ? 14 : 10,
                offset: const Offset(0, 4),
                color: selected
                    ? AppColors.brandPurple.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? AppColors.brandPurple
                      : AppColors.deepGreen.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: selected ? AppColors.brandPurple : AppColors.deepGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KitchenBrowseCuisineChip extends StatelessWidget {
  const KitchenBrowseCuisineChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.cuisine,
  });

  final String label;
  final CustomerCuisine? cuisine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.brandPurple.withValues(alpha: 0.5)
                : AppColors.deepGreen.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 4),
              color: selected
                  ? AppColors.brandPurple.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: SizedBox(
                width: 36,
                height: 36,
                child: cuisine == null
                    ? ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: Icon(
                            Icons.grid_view_rounded,
                            size: 20,
                            color: selected
                                ? AppColors.brandPurple
                                : AppColors.deepGreen.withValues(alpha: 0.55),
                          ),
                        ),
                      )
                    : _KitchenBrowseCuisineImage(cuisine: cuisine!),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 96),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: selected ? AppColors.brandPurple : AppColors.deepGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KitchenBrowseCuisineImage extends StatelessWidget {
  const _KitchenBrowseCuisineImage({required this.cuisine});

  final CustomerCuisine cuisine;

  @override
  Widget build(BuildContext context) {
    final assetPath = cuisine.assetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _networkOrFallback(),
      );
    }
    return _networkOrFallback();
  }

  Widget _networkOrFallback() {
    final imageUrl = resolveOptica2AssetUrl(cuisine.imageUrl);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const ColoredBox(color: Colors.white);
        },
        errorBuilder: (_, _, _) => _fallbackIcon(),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: AppColors.brandPurple.withValues(alpha: 0.7),
          size: 18,
        ),
      ),
    );
  }
}

/// Open / closed filter — sliding pill with icons for kitchen browse.
class KitchenOpenClosedToggle extends StatefulWidget {
  const KitchenOpenClosedToggle({
    super.key,
    required this.showOpen,
    required this.openLabel,
    required this.closedLabel,
    required this.onChanged,
    this.fullWidth = false,
  });

  static const _openGreen = Color(0xFF16A34A);
  static const _openGreenDeep = Color(0xFF15803D);
  static const _closedRed = Color(0xFFEF4444);
  static const _closedRedDeep = Color(0xFFDC2626);

  final bool showOpen;
  final String openLabel;
  final String closedLabel;
  final ValueChanged<bool> onChanged;
  /// Full-width bar below hero (light surface styling).
  final bool fullWidth;

  @override
  State<KitchenOpenClosedToggle> createState() => _KitchenOpenClosedToggleState();
}

class _KitchenOpenClosedToggleState extends State<KitchenOpenClosedToggle> {
  static const _compactHeight = 34.0;
  static const _fullHeight = 44.0;
  static const _radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final fullWidth = widget.fullWidth;
    final height = fullWidth ? _fullHeight : _compactHeight;
    final activeColor =
        widget.showOpen ? KitchenOpenClosedToggle._openGreen : KitchenOpenClosedToggle._closedRed;
    final activeDeep = widget.showOpen
        ? KitchenOpenClosedToggle._openGreenDeep
        : KitchenOpenClosedToggle._closedRedDeep;

    final toggle = DecoratedBox(
      decoration: BoxDecoration(
        color: fullWidth ? Colors.white : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_radius + 2),
        border: Border.all(
          color: fullWidth
              ? activeColor.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.22),
        ),
        boxShadow: fullWidth
            ? [
                BoxShadow(
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                  color: activeColor.withValues(alpha: 0.12),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: widget.showOpen
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [activeColor, activeDeep],
                      ),
                      borderRadius: BorderRadius.circular(_radius),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: fullWidth ? 8 : 12,
                          offset: const Offset(0, 3),
                          color: activeColor.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _KitchenOpenClosedOption(
                      label: widget.openLabel,
                      icon: Icons.restaurant_rounded,
                      accent: KitchenOpenClosedToggle._openGreen,
                      selected: widget.showOpen,
                      onLightBackground: fullWidth,
                      onTap: () => widget.onChanged(true),
                    ),
                  ),
                  Expanded(
                    child: _KitchenOpenClosedOption(
                      label: widget.closedLabel,
                      icon: Icons.nightlight_round,
                      accent: KitchenOpenClosedToggle._closedRed,
                      selected: !widget.showOpen,
                      onLightBackground: fullWidth,
                      onTap: () => widget.onChanged(false),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: toggle);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 148, maxWidth: 176),
      child: toggle,
    );
  }
}

class _KitchenOpenClosedOption extends StatelessWidget {
  const _KitchenOpenClosedOption({
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onLightBackground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final bool onLightBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : onLightBackground
            ? accent.withValues(alpha: 0.72)
            : accent.withValues(alpha: 0.9);
    final labelColor = selected
        ? Colors.white
        : onLightBackground
            ? accent.withValues(alpha: 0.78)
            : accent.withValues(alpha: 0.92);
    final iconSize =
        onLightBackground ? (selected ? 20.0 : 18.0) : (selected ? 18.0 : 16.0);
    final fontSize =
        onLightBackground ? (selected ? 14.0 : 13.5) : (selected ? 11.0 : 10.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: onLightBackground ? 10 : 6,
            vertical: onLightBackground ? 10 : 7,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : accent.withValues(alpha: onLightBackground ? 0.12 : 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize * 0.58,
                  color: fg,
                ),
              ),
              SizedBox(width: onLightBackground ? 8 : 5),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  style: AppFonts.style(
                    context,
                    fontSize: fontSize,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: labelColor,
                    letterSpacing: 0.15,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KitchenBrowseBackButton extends StatelessWidget {
  const KitchenBrowseBackButton({
    super.key,
    required this.onTap,
    required this.light,
  });

  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light
          ? Colors.black.withValues(alpha: 0.28)
          : AppColors.brandPurple.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            color: light ? Colors.white : AppColors.brandPurple,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class KitchenBrowseHeroWavePainter extends CustomPainter {
  const KitchenBrowseHeroWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.cream,
    );
    canvas.drawPath(_kitchenBrowseWaveTopPath(size), _kitchenBrowseWavePaint(size));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KitchenBrowseHeroLightWavePainter extends CustomPainter {
  const KitchenBrowseHeroLightWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.cream,
    );
    canvas.drawPath(
      _kitchenBrowseWaveTopPath(size),
      _kitchenBrowseLightWavePaint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KitchenBrowseStickyWavePainter extends CustomPainter {
  const KitchenBrowseStickyWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_kitchenBrowseWaveTopPath(size), _kitchenBrowseWavePaint(size));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class KitchenBrowseStickyLightWavePainter extends CustomPainter {
  const KitchenBrowseStickyLightWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.cream,
    );
    canvas.drawPath(
      _kitchenBrowseWaveTopPath(size),
      _kitchenBrowseLightWavePaint(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _kitchenBrowseWaveTopPath(Size size) {
  return Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * 0.5)
    ..cubicTo(
      size.width * 0.88,
      size.height * 0.66,
      size.width * 0.76,
      size.height * 0.4,
      size.width * 0.55,
      size.height * 0.58,
    )
    ..cubicTo(
      size.width * 0.36,
      size.height * 0.76,
      size.width * 0.2,
      size.height * 0.42,
      0,
      size.height * 0.58,
    )
    ..close();
}

Paint _kitchenBrowseWavePaint(Size size) {
  return Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.brandPurple, AppColors.brandPurpleDeep],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
}

Paint _kitchenBrowseLightWavePaint() {
  return Paint()..color = AppColors.homeLightPurple;
}
