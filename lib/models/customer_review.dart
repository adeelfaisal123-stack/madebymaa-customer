class CustomerRatingSummary {
  const CustomerRatingSummary({
    required this.average,
    required this.count,
  });

  const CustomerRatingSummary.empty()
      : average = 0,
        count = 0;

  final double average;
  final int count;

  bool get hasReviews => count > 0;

  String get averageLabel => hasReviews ? average.toStringAsFixed(1) : '—';

  String get countLabel =>
      count == 1 ? '1 review' : '$count reviews';

  factory CustomerRatingSummary.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const CustomerRatingSummary.empty();
    }

    return CustomerRatingSummary(
      average: (json['average'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomerReview {
  const CustomerReview({
    required this.id,
    required this.rating,
    this.comment,
    required this.customerName,
    this.dishId,
    this.dishName,
    this.createdAt,
  });

  final int id;
  final int rating;
  final String? comment;
  final String customerName;
  final int? dishId;
  final String? dishName;
  final DateTime? createdAt;

  factory CustomerReview.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'] as String?;

    return CustomerReview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      customerName: json['customer_name'] as String? ?? 'Customer',
      dishId: (json['dish_id'] as num?)?.toInt(),
      dishName: json['dish_name'] as String?,
      createdAt: createdRaw != null ? DateTime.tryParse(createdRaw) : null,
    );
  }
}

class CustomerReviewsPayload {
  const CustomerReviewsPayload({
    required this.rating,
    required this.reviews,
  });

  const CustomerReviewsPayload.empty()
      : rating = const CustomerRatingSummary.empty(),
        reviews = const [];

  final CustomerRatingSummary rating;
  final List<CustomerReview> reviews;

  factory CustomerReviewsPayload.fromJson(Map<String, dynamic> json) {
    final reviewsRaw = json['reviews'];
    final reviews = <CustomerReview>[];
    if (reviewsRaw is List) {
      for (final raw in reviewsRaw) {
        if (raw is Map<String, dynamic>) {
          reviews.add(CustomerReview.fromJson(raw));
        }
      }
    }

    return CustomerReviewsPayload(
      rating: CustomerRatingSummary.fromJson(json['rating']),
      reviews: reviews,
    );
  }
}

class CustomerOrderReviewInfo {
  const CustomerOrderReviewInfo({
    required this.submitted,
    required this.canSubmit,
  });

  const CustomerOrderReviewInfo.ineligible()
      : submitted = false,
        canSubmit = false;

  final bool submitted;
  final bool canSubmit;

  factory CustomerOrderReviewInfo.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const CustomerOrderReviewInfo.ineligible();
    }

    return CustomerOrderReviewInfo(
      submitted: json['submitted'] as bool? ?? false,
      canSubmit: json['can_submit'] as bool? ?? false,
    );
  }
}
