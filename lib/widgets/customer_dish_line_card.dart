import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';

/// Compact horizontal dish row — shared by cart and wishlist.
class CustomerDishLineCard extends StatelessWidget {
  const CustomerDishLineCard({
    super.key,
    required this.dishName,
    required this.kitchenName,
    required this.priceLabel,
    required this.isVeg,
    this.imageUrl,
    this.category,
    this.priceSubtext,
    this.onTap,
    this.onRemove,
    this.trailing,
  });

  final String dishName;
  final String kitchenName;
  final String priceLabel;
  final bool isVeg;
  final String? imageUrl;
  final String? category;
  final String? priceSubtext;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? trailing;

  static const cardHeight = 100.0;
  static const imageWidth = 88.0;
  static const cardRadius = BorderRadius.all(Radius.circular(18));

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveOptica2AssetUrl(imageUrl);
    const accent = AppColors.brandPurple;
    final categoryLabel = category?.trim() ?? '';

    return SizedBox(
      height: cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: cardRadius,
          border: Border.all(color: accent.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: accent.withValues(alpha: 0.08),
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.03),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: cardRadius,
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    children: [
                      _DishLineImage(
                        imageUrl: resolvedImageUrl,
                        accent: accent,
                        isVeg: isVeg,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      dishName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.style(
                                        context,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.deepGreen,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  if (onRemove != null)
                                    _DishLineIconButton(
                                      icon: Icons.close_rounded,
                                      tooltip: 'Remove',
                                      onTap: onRemove!,
                                    ),
                                ],
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kitchenName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.style(
                                          context,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.deepGreen.withValues(
                                            alpha: 0.52,
                                          ),
                                          height: 1.1,
                                        ),
                                      ),
                                      if (categoryLabel.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          categoryLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.style(
                                            context,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.sage,
                                            height: 1,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: priceLabel,
                                      style: AppFonts.style(
                                        context,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.brandPurple,
                                        height: 1,
                                      ),
                                    ),
                                    if (priceSubtext != null &&
                                        priceSubtext!.isNotEmpty)
                                      TextSpan(
                                        text: priceSubtext,
                                        style: AppFonts.style(
                                          context,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.deepGreen.withValues(
                                            alpha: 0.42,
                                          ),
                                          height: 1,
                                        ),
                                      ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 10),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: trailing!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerDishQtyStepper extends StatelessWidget {
  const CustomerDishQtyStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.deepGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            enabled: onDecrement != null,
            compact: true,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                context,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppColors.deepGreen,
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            enabled: true,
            highlight: true,
            compact: true,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class CustomerDishAddButton extends StatelessWidget {
  const CustomerDishAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.brandPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 16,
                color: AppColors.brandPurple,
              ),
              const SizedBox(width: 2),
              Text(
                'Add',
                style: AppFonts.style(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishLineImage extends StatelessWidget {
  const _DishLineImage({
    required this.imageUrl,
    required this.accent,
    required this.isVeg,
  });

  final String? imageUrl;
  final Color accent;
  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CustomerDishLineCard.imageWidth,
      height: CustomerDishLineCard.cardHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Image.network(imageUrl!, fit: BoxFit.cover)
          else
            ColoredBox(
              color: accent.withValues(alpha: 0.08),
              child: Icon(
                Icons.restaurant_rounded,
                color: accent.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isVeg ? AppColors.sage : AppColors.terracotta,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isVeg ? AppColors.sage : AppColors.terracotta,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishLineIconButton extends StatelessWidget {
  const _DishLineIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              icon,
              size: 15,
              color: AppColors.deepGreen.withValues(alpha: 0.32),
            ),
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.highlight = false,
    this.compact = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final bool highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.deepGreen.withValues(alpha: 0.2)
        : highlight
            ? AppColors.brandPurple
            : AppColors.deepGreen.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        child: Padding(
          padding: EdgeInsets.all(compact ? 5 : 8),
          child: Icon(icon, size: compact ? 15 : 18, color: color),
        ),
      ),
    );
  }
}
