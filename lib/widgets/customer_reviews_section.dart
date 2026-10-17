import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_review.dart';
import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.activeColor = AppColors.amberGlow,
    this.inactiveColor,
  });

  final double rating;
  final double size;
  final Color activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final inactive = inactiveColor ?? AppColors.deepGreen.withValues(alpha: 0.18);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = rating >= index + 1;
        final half = !filled && rating > index && rating < index + 1;

        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: size,
          color: filled || half ? activeColor : inactive,
        );
      }),
    );
  }
}

class InteractiveRatingStars extends StatelessWidget {
  const InteractiveRatingStars({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 32,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final star = index + 1;
        final selected = value >= star;

        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: size + 4, minHeight: size + 4),
          onPressed: () => onChanged(star),
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: selected ? AppColors.amberGlow : AppColors.deepGreen.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

class RatingSummaryRow extends StatelessWidget {
  const RatingSummaryRow({
    super.key,
    required this.average,
    required this.count,
    this.compact = false,
    this.light = false,
  });

  final double average;
  final int count;
  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Text(
        'No reviews yet',
        style: GoogleFonts.exo2(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: light
              ? Colors.white.withValues(alpha: 0.75)
              : AppColors.deepGreen.withValues(alpha: 0.5),
        ),
      );
    }

    final textColor = light ? Colors.white : AppColors.deepGreen;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingStars(
          rating: average,
          size: compact ? 14 : 16,
          activeColor: AppColors.amberGlow,
          inactiveColor: light
              ? Colors.white.withValues(alpha: 0.35)
              : AppColors.deepGreen.withValues(alpha: 0.18),
        ),
        const SizedBox(width: 6),
        Text(
          average.toStringAsFixed(1),
          style: GoogleFonts.exo2(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: GoogleFonts.exo2(
            fontSize: compact ? 11 : 12,
            color: light
                ? Colors.white.withValues(alpha: 0.75)
                : AppColors.deepGreen.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class CustomerReviewsSection extends StatelessWidget {
  const CustomerReviewsSection({
    super.key,
    required this.title,
    required this.rating,
    required this.reviews,
  });

  final String title;
  final CustomerRatingSummary rating;
  final List<CustomerReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (!rating.hasReviews && reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.exo2(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.deepGreen,
              ),
            ),
            const Spacer(),
            RatingSummaryRow(
              average: rating.average,
              count: rating.count,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Text(
            'Be the first to leave a review.',
            style: GoogleFonts.exo2(
              fontSize: 13,
              color: AppColors.deepGreen.withValues(alpha: 0.55),
            ),
          )
        else
          ...reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CustomerReviewCard(review: review),
            ),
          ),
      ],
    );
  }
}

class CustomerReviewCard extends StatelessWidget {
  const CustomerReviewCard({super.key, required this.review});

  final CustomerReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.customerName,
                  style: GoogleFonts.exo2(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                  ),
                ),
              ),
              RatingStars(rating: review.rating.toDouble(), size: 14),
            ],
          ),
          if (review.dishName != null && review.dishName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              review.dishName!,
              style: GoogleFonts.exo2(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPurple,
              ),
            ),
          ],
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!.trim(),
              style: GoogleFonts.exo2(
                fontSize: 13,
                height: 1.45,
                color: AppColors.deepGreen.withValues(alpha: 0.72),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
