class CustomerCuisine {
  const CustomerCuisine({
    required this.id,
    required this.name,
    this.imageUrl,
    this.assetPath,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String? assetPath;

  factory CustomerCuisine.fromJson(Map<String, dynamic> json) {
    return CustomerCuisine(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String? ?? '').trim(),
      imageUrl: json['image_url'] as String?,
    );
  }
}
