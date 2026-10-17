import 'package:flutter/material.dart';

import '../models/customer_dish.dart';
import '../models/customer_featured_dish.dart';
import '../theme/app_colors.dart';
import '../utils/app_fonts.dart';
import '../utils/optica2_asset_url.dart';

/// Display data for [CustomerDishCard] — decoupled from API models.
class CustomerDishCardModel {
  const CustomerDishCardModel({
    required this.name,
    required this.metaLabel,
    required this.price,
    required this.effectivePrice,
    required this.isVeg,
    this.subtitle,
    this.imageUrl,
  });

  final String name;
  final String? subtitle;
  final String metaLabel;
  final double price;
  final double effectivePrice;
  final bool isVeg;
  final String? imageUrl;

  bool get hasDiscount => effectivePrice < price - 0.01;

  factory CustomerDishCardModel.fromFeatured(CustomerFeaturedDish dish) {
    final cuisine = dish.restaurantCuisine?.trim();
    return CustomerDishCardModel(
      name: dish.name,
      subtitle: dish.restaurantName,
      metaLabel: cuisine != null && cuisine.isNotEmpty
          ? cuisine
          : 'Home kitchen',
      price: dish.price,
      effectivePrice: dish.effectivePrice,
      isVeg: dish.isVeg,
      imageUrl: dish.imageUrl,
    );
  }

  factory CustomerDishCardModel.fromDish(
    CustomerDish dish, {
    String? kitchenName,
  }) {
    return CustomerDishCardModel(
      name: dish.name,
      subtitle: kitchenName,
      metaLabel: dish.displayCategoryLabel,
      price: dish.price,
      effectivePrice: dish.effectivePrice,
      isVeg: dish.isVeg,
      imageUrl: dish.imageUrl,
    );
  }
}

/// Unified dish grid/list card used across explore, kitchen menu, carousel, and wishlist.
class CustomerDishCard extends StatelessWidget {
  const CustomerDishCard({
    super.key,
    required this.dish,
    required this.accent,
    required this.onTap,
    this.footerTrailing,
  });

  static const gridAspectRatio = 0.64;

  final CustomerDishCardModel dish;
  final Color accent;
  final VoidCallback onTap;
  final Widget? footerTrailing;

  static Color accentForIndex(int index) {
    return switch (index % 3) {
      0 => AppColors.brandPurple,
      1 => AppColors.deepGreen,
      _ => AppColors.sage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveOptica2AssetUrl(dish.imageUrl);
    final subtitle = dish.subtitle?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E7EC)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.brandPurple.withValues(alpha: 0.06),
          highlightColor: AppColors.brandPurple.withValues(alpha: 0.03),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        headers: const {
                          'User-Agent': 'MadeByMaa-Customer/1.0',
                          'Accept': 'image/*',
                        },
                        errorBuilder: (_, _, _) => _imageFallback(accent),
                      )
                    else
                      _imageFallback(accent),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0, 0.5, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: _DishVegBadge(isVeg: dish.isVeg),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _DishPriceTag(
                        price: dish.price,
                        effectivePrice: dish.effectivePrice,
                        accent: accent,
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withValues(alpha: 0.04),
                      accent.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.style(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepGreen,
                          height: 1.2,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            context,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.deepGreen.withValues(
                              alpha: 0.52,
                            ),
                            height: 1.1,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DishMetaPill(
                              label: dish.metaLabel,
                              color: accent,
                            ),
                          ),
                          footerTrailing ??
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: AppColors.deepGreen.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.3),
            accent.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
      ),
      child: Icon(
        Icons.restaurant_rounded,
        color: accent.withValues(alpha: 0.55),
        size: 42,
      ),
    );
  }
}

class _DishPriceTag extends StatelessWidget {
  const _DishPriceTag({
    required this.price,
    required this.effectivePrice,
    required this.accent,
  });

  final double price;
  final double effectivePrice;
  final Color accent;

  static const _paper = Color(0xFFFFFBF5);
  static const _cornerCut = 9.0;

  bool get _hasDiscount => effectivePrice < price - 0.01;

  @override
  Widget build(BuildContext context) {
    final priceText = effectivePrice.toStringAsFixed(0);
    final content = _tagContent(context, priceText);

    return Transform.rotate(
      angle: -0.05,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Transform.translate(
            offset: const Offset(2, 3),
            child: _tagShell(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: content,
              ),
              fillColor: Colors.black.withValues(alpha: 0.14),
            ),
          ),
          _tagShell(
            child: content,
            fillColor: _paper,
            borderColor: accent.withValues(alpha: 0.42),
          ),
          Positioned(
            top: 5,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.18),
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: 1.2,
              height: 6,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagShell({
    required Widget child,
    required Color fillColor,
    Color? borderColor,
  }) {
    return ClipPath(
      clipper: const _ShelfPriceTagClipper(),
      child: CustomPaint(
        painter: _ShelfPriceTagBorderPainter(
          color: borderColor ?? Colors.transparent,
          cut: _cornerCut,
        ),
        child: ColoredBox(
          color: fillColor,
          child: child,
        ),
      ),
    );
  }

  Widget _tagContent(BuildContext context, String priceText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 13, 14, 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: AppFonts.style(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  height: 1,
                ),
              ),
              Text(
                priceText,
                style: AppFonts.style(
                  context,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepGreen,
                  height: 1,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          if (_hasDiscount) ...[
            const SizedBox(height: 2),
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: AppFonts.style(
                context,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.deepGreen.withValues(alpha: 0.42),
                height: 1,
              ).copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.deepGreen.withValues(alpha: 0.42),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shelf-style tag with a diagonal snip on the bottom-right corner.
class _ShelfPriceTagClipper extends CustomClipper<Path> {
  const _ShelfPriceTagClipper();

  static const _cut = _DishPriceTag._cornerCut;
  static const _radius = 3.5;

  @override
  Path getClip(Size size) => _tagPath(size);

  static Path _tagPath(Size size) {
    final r = _radius;
    return Path()
      ..moveTo(r, 0)
      ..lineTo(size.width - r, 0)
      ..quadraticBezierTo(size.width, 0, size.width, r)
      ..lineTo(size.width, size.height - _cut)
      ..lineTo(size.width - _cut, size.height)
      ..lineTo(r, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ShelfPriceTagBorderPainter extends CustomPainter {
  const _ShelfPriceTagBorderPainter({
    required this.color,
    required this.cut,
  });

  final Color color;
  final double cut;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;

    final path = _ShelfPriceTagClipper._tagPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final dash = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width * 0.18, 12),
      Offset(size.width * 0.82, 12),
      dash,
    );
  }

  @override
  bool shouldRepaint(covariant _ShelfPriceTagBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.cut != cut;
}

class _DishVegBadge extends StatelessWidget {
  const _DishVegBadge({required this.isVeg});

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? AppColors.brandPurple : const Color(0xFFC2410C);
    final label = isVeg ? 'Veg' : 'Non-veg';
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 9, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              isVeg ? Icons.eco_rounded : Icons.local_fire_department_rounded,
              size: 9,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.style(
              context,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DishMetaPill extends StatelessWidget {
  const _DishMetaPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.style(
                context,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen.withValues(alpha: 0.72),
                height: 1,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
