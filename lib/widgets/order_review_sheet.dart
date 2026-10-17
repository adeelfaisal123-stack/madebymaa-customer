import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../customer_review_prefs.dart';
import '../models/customer_order.dart';
import '../services/customer_orders_store.dart';
import '../services/optica2_api.dart';
import '../theme/app_colors.dart';
import '../widgets/app_toast.dart';
import 'customer_reviews_section.dart';

class OrderReviewSheet extends StatefulWidget {
  const OrderReviewSheet({
    super.key,
    required this.order,
    this.api,
  });

  final CustomerOrder order;
  final Optica2Api? api;

  static Future<void> show(
    BuildContext context, {
    required CustomerOrder order,
    Optica2Api? api,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderReviewSheet(order: order, api: api),
    );
  }

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  late final Map<int, _KitchenDraft> _kitchens;
  late final Map<int, _DishDraft> _dishes;
  final _kitchenComments = <int, TextEditingController>{};
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _kitchens = {};
    _dishes = {};

    for (final line in widget.order.lines) {
      _kitchens.putIfAbsent(
        line.kitchenId,
        () => _KitchenDraft(id: line.kitchenId, name: line.kitchenName),
      );
      _dishes.putIfAbsent(
        line.dishId,
        () => _DishDraft(
          id: line.dishId,
          restaurantId: line.kitchenId,
          name: line.dishName,
        ),
      );
    }

    for (final kitchen in _kitchens.values) {
      _kitchenComments[kitchen.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _kitchenComments.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _canSubmit =>
      _kitchens.values.every((kitchen) => kitchen.rating > 0) && !_submitting;

  Future<void> _skip() async {
    await CustomerReviewPrefs.markSkipped(widget.order.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _submitting = true);
    final client = widget.api ?? Optica2Api();
    final ownsClient = widget.api == null;

    try {
      await CustomerOrdersStore.instance.submitReview(
        api: client,
        order: widget.order,
        kitchenRatings: _kitchens.values
            .map(
              (kitchen) => {
                'restaurant_id': kitchen.id,
                'rating': kitchen.rating,
                'comment': _kitchenComments[kitchen.id]?.text.trim(),
              },
            )
            .toList(),
        dishRatings: _dishes.values
            .where((dish) => dish.rating > 0)
            .map(
              (dish) => {
                'dish_id': dish.id,
                'restaurant_id': dish.restaurantId,
                'rating': dish.rating,
              },
            )
            .toList(),
      );

      await CustomerReviewPrefs.clearSkipped(widget.order.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      AppToast.success(context, 'Thanks for your review!');
    } on Optica2ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not submit review.');
    } finally {
      if (ownsClient) client.close();
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate your order',
                            style: GoogleFonts.exo2(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.deepGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.order.id} · How was your meal?',
                            style: GoogleFonts.exo2(
                              fontSize: 13,
                              color: AppColors.deepGreen.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _submitting ? null : _skip,
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.deepGreen.withValues(alpha: 0.45),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  children: [
                    Text(
                      'Kitchen',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final kitchen in _kitchens.values) ...[
                      _KitchenReviewBlock(
                        kitchen: kitchen,
                        commentController: _kitchenComments[kitchen.id]!,
                        onRatingChanged: (rating) {
                          setState(() => kitchen.rating = rating);
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      'Dishes (optional)',
                      style: GoogleFonts.exo2(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final dish in _dishes.values) ...[
                      _DishReviewBlock(
                        dish: dish,
                        onRatingChanged: (rating) {
                          setState(() => dish.rating = rating);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : _skip,
                      child: Text(
                        'Not now',
                        style: GoogleFonts.exo2(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit review',
                                style: GoogleFonts.exo2(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenDraft {
  _KitchenDraft({required this.id, required this.name});

  final int id;
  final String name;
  int rating = 0;
}

class _DishDraft {
  _DishDraft({
    required this.id,
    required this.restaurantId,
    required this.name,
  });

  final int id;
  final int restaurantId;
  final String name;
  int rating = 0;
}

class _KitchenReviewBlock extends StatelessWidget {
  const _KitchenReviewBlock({
    required this.kitchen,
    required this.commentController,
    required this.onRatingChanged,
  });

  final _KitchenDraft kitchen;
  final TextEditingController commentController;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kitchen.name,
            style: GoogleFonts.exo2(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
            ),
          ),
          const SizedBox(height: 8),
          InteractiveRatingStars(
            value: kitchen.rating,
            onChanged: onRatingChanged,
            size: 30,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              hintStyle: GoogleFonts.exo2(
                fontSize: 13,
                color: AppColors.deepGreen.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishReviewBlock extends StatelessWidget {
  const _DishReviewBlock({
    required this.dish,
    required this.onRatingChanged,
  });

  final _DishDraft dish;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandPurple.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dish.name,
              style: GoogleFonts.exo2(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.deepGreen,
              ),
            ),
          ),
          InteractiveRatingStars(
            value: dish.rating,
            onChanged: onRatingChanged,
            size: 24,
          ),
        ],
      ),
    );
  }
}
