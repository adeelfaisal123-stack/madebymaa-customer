import 'customer_dish_subcategory.dart';

class CustomerDishCategory {
  const CustomerDishCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.subcategories = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final List<CustomerDishSubcategory> subcategories;

  factory CustomerDishCategory.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subcategories'];
    final subs = rawSubs is List
        ? rawSubs
            .whereType<Map<String, dynamic>>()
            .map(CustomerDishSubcategory.fromJson)
            .where((s) => s.name.isNotEmpty)
            .toList()
        : const <CustomerDishSubcategory>[];

    return CustomerDishCategory(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String? ?? '').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      imageUrl: json['image_url'] as String?,
      subcategories: subs,
    );
  }
}
