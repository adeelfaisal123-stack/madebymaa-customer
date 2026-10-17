import 'package:flutter/material.dart';

import '../data/bundled_cuisines.dart';
import '../l10n/app_localizations.dart';
import '../models/customer_cuisine.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';
import '../screens/cuisine_browse_screen.dart';
import 'discover_section_heading.dart';
import 'viewport_load_animation.dart';

/// Cuisines on Explore — two-row horizontal slider.
class CuisinesSection extends StatelessWidget {
  const CuisinesSection({
    super.key,
    required this.cuisines,
    this.isLoading = false,
  });

  final List<CustomerCuisine> cuisines;
  final bool isLoading;

  static const _horizontalPadding = 20.0;
  static const _columnGap = 14.0;
  static const _rowGap = 12.0;
  static const _tileWidth = 72.0;

  static const _imageSize = 64.0;
  static const _labelGap = 6.0;
  static const _labelHeight = 14.0;

  static double get _rowHeight => _imageSize + _labelGap + _labelHeight;

  static double get _sliderHeight => _rowHeight * 2 + _rowGap;

  void _openCuisine(BuildContext context, CustomerCuisine cuisine) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CuisineBrowseScreen(
          cuisineId: cuisine.id > 0 ? cuisine.id : null,
          cuisineName: cuisine.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = cuisines.isNotEmpty ? cuisines : BundledCuisines.list;

    if (isLoading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandPurple,
            ),
          ),
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    final columnCount = (items.length + 1) ~/ 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: DiscoverSectionHeading(
            title: l10n.cuisinesTitle,
            accent: AppColors.terracotta,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: _sliderHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            itemCount: columnCount,
            separatorBuilder: (_, _) => const SizedBox(width: _columnGap),
            itemBuilder: (context, column) {
              final topIndex = column * 2;
              final bottomIndex = topIndex + 1;

              return SizedBox(
                width: _tileWidth,
                child: Column(
                  children: [
                    _CuisineTile(
                      cuisine: items[topIndex],
                      index: topIndex,
                      onTap: () => _openCuisine(context, items[topIndex]),
                    ),
                    const SizedBox(height: _rowGap),
                    if (bottomIndex < items.length)
                      _CuisineTile(
                        cuisine: items[bottomIndex],
                        index: bottomIndex,
                        onTap: () => _openCuisine(context, items[bottomIndex]),
                      )
                    else
                      SizedBox(height: _rowHeight),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CuisineTile extends StatelessWidget {
  const _CuisineTile({
    required this.cuisine,
    required this.index,
    required this.onTap,
  });

  final CustomerCuisine cuisine;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CuisineLoadInAnimation(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: CuisinesSection._tileWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: CuisinesSection._imageSize,
                  height: CuisinesSection._imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFECECEC),
                    border: Border.all(
                      color: AppColors.deepGreen.withValues(alpha: 0.08),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(child: _CuisineImage(cuisine: cuisine)),
                  ),
                ),
                const SizedBox(height: CuisinesSection._labelGap),
                SizedBox(
                  height: CuisinesSection._labelHeight,
                  child: Center(
                    child: Text(
                      cuisine.name,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.style(
                        context,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.0,
                        color: AppColors.deepGreen,
                      ),
                    ),
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

class _CuisineLoadInAnimation extends StatelessWidget {
  const _CuisineLoadInAnimation({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ViewportLoadAnimation(
      index: index,
      duration: const Duration(milliseconds: 300),
      stagger: const Duration(milliseconds: 35),
      curve: Curves.easeOutBack,
      beginOffset: const Offset(0, 12),
      beginScale: 0.88,
      child: child,
    );
  }
}

class _CuisineImage extends StatelessWidget {
  const _CuisineImage({required this.cuisine});

  final CustomerCuisine cuisine;

  @override
  Widget build(BuildContext context) {
    final assetPath = cuisine.assetPath;
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
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
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _fallbackIcon(),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(
        Icons.restaurant_rounded,
        color: AppColors.brandPurple,
        size: 24,
      ),
    );
  }
}
