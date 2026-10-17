class CustomerDishSubcategory {
  const CustomerDishSubcategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
  });

  final int id;
  final String name;
  final String slug;
  final String? imageUrl;

  factory CustomerDishSubcategory.fromJson(Map<String, dynamic> json) {
    return CustomerDishSubcategory(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String? ?? '').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      imageUrl: json['image_url'] as String?,
    );
  }
}
