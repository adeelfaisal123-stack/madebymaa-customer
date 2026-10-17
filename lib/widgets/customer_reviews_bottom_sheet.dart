import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/customer_review.dart';
import '../theme/app_colors.dart';
import 'customer_reviews_section.dart';

/// Opens a bottom sheet with the full rating summary and review list.
class CustomerReviewsBottomSheet {
  CustomerReviewsBottomSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Future<CustomerReviewsPayload> Function() loadReviews,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CustomerReviewsBottomSheetBody(
        title: title,
        loadReviews: loadReviews,
      ),
    );
  }
}

class ShowReviewsButton extends StatelessWidget {
  const ShowReviewsButton({
    super.key,
    required this.rating,
    required this.onTap,
  });

  final CustomerRatingSummary rating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brandPurple.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: AppColors.brandPurple.withValues(alpha: 0.06),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amberGlow.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.amberGlow,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show reviews',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (rating.hasReviews)
                      RatingSummaryRow(
                        average: rating.average,
                        count: rating.count,
                        compact: true,
                      )
                    else
                      Text(
                        'No reviews yet',
                        style: GoogleFonts.exo2(
                          fontSize: 12,
                          color: AppColors.deepGreen.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.deepGreen.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerReviewsBottomSheetBody extends StatefulWidget {
  const _CustomerReviewsBottomSheetBody({
    required this.title,
    required this.loadReviews,
  });

  final String title;
  final Future<CustomerReviewsPayload> Function() loadReviews;

  @override
  State<_CustomerReviewsBottomSheetBody> createState() =>
      _CustomerReviewsBottomSheetBodyState();
}

class _CustomerReviewsBottomSheetBodyState
    extends State<_CustomerReviewsBottomSheetBody> {
  CustomerReviewsPayload? _payload;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    try {
      final payload = await widget.loadReviews();
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load reviews.';
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _load(showLoading: false);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final payload = _payload;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.exo2(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.brandPurple),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: GoogleFonts.exo2(color: AppColors.terracotta),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: Text('Retry', style: GoogleFonts.exo2()),
                      ),
                    ],
                  ),
                )
              else if (payload != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _RatingHeader(rating: payload.rating),
                ),
                Flexible(
                  child: RefreshIndicator(
                    color: AppColors.brandPurple,
                    onRefresh: _refresh,
                    child: payload.reviews.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.all(24),
                            children: [
                              Text(
                                'No reviews yet. Order and share your experience!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.exo2(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: AppColors.deepGreen
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: payload.reviews.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => CustomerReviewCard(
                              review: payload.reviews[index],
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingHeader extends StatelessWidget {
  const _RatingHeader({required this.rating});

  final CustomerRatingSummary rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.1)),
      ),
      child: rating.hasReviews
          ? Row(
              children: [
                Text(
                  rating.average.toStringAsFixed(1),
                  style: GoogleFonts.exo2(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppColors.deepGreen,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RatingStars(rating: rating.average, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        rating.countLabel,
                        style: GoogleFonts.exo2(
                          fontSize: 13,
                          color: AppColors.deepGreen.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Text(
              'No ratings yet',
              style: GoogleFonts.exo2(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen.withValues(alpha: 0.6),
              ),
            ),
    );
  }
}
