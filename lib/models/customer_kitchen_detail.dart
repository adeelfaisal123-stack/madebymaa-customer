import 'customer_dish.dart';
import 'customer_featured_kitchen.dart';
import 'customer_review.dart';

class CustomerKitchenDetail {
  const CustomerKitchenDetail({
    required this.kitchen,
    required this.dishes,
    this.reviews = const [],
    this.rating = const CustomerRatingSummary.empty(),
  });

  final CustomerFeaturedKitchen kitchen;
  final List<CustomerDish> dishes;
  final List<CustomerReview> reviews;
  final CustomerRatingSummary rating;

  factory CustomerKitchenDetail.fromJson(Map<String, dynamic> json) {
    final kitchenRaw = json['kitchen'];
    final dishesRaw = json['dishes'];
    final reviewsRaw = json['reviews'];

    final reviews = <CustomerReview>[];
    if (reviewsRaw is List) {
      for (final raw in reviewsRaw) {
        if (raw is Map<String, dynamic>) {
          reviews.add(CustomerReview.fromJson(raw));
        }
      }
    }

    final kitchen = kitchenRaw is Map<String, dynamic>
        ? CustomerFeaturedKitchen.fromJson(kitchenRaw)
        : const CustomerFeaturedKitchen(id: 0, name: 'Kitchen');

    return CustomerKitchenDetail(
      kitchen: kitchen,
      dishes: dishesRaw is List
          ? dishesRaw
              .whereType<Map<String, dynamic>>()
              .map(CustomerDish.fromJson)
              .toList()
          : const [],
      reviews: reviews,
      rating: kitchen.rating,
    );
  }
}
