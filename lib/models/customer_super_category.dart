class CustomerSuperCategory {
  const CustomerSuperCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.timeRange,
    this.startTime,
    this.endTime,
    this.imageUrl,
    this.assetPath,
  });

  final int id;
  final String name;
  final String slug;
  final String timeRange;
  final String? startTime;
  final String? endTime;
  final String? imageUrl;
  final String? assetPath;

  factory CustomerSuperCategory.fromJson(Map<String, dynamic> json) {
    return CustomerSuperCategory(
      id: json['id'] as int,
      name: (json['name'] as String? ?? '').trim(),
      slug: (json['slug'] as String? ?? '').trim(),
      timeRange: (json['time_range'] as String? ?? '').trim(),
      startTime: (json['start_time'] as String?)?.trim(),
      endTime: (json['end_time'] as String?)?.trim(),
      imageUrl: json['image_url'] as String?,
    );
  }
}
