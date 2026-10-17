enum CustomerHomeSliderLinkType {
  none,
  url,
  kitchen,
  dish;

  static CustomerHomeSliderLinkType fromApi(String? raw) {
    return switch (raw) {
      'url' => CustomerHomeSliderLinkType.url,
      'kitchen' => CustomerHomeSliderLinkType.kitchen,
      'dish' => CustomerHomeSliderLinkType.dish,
      _ => CustomerHomeSliderLinkType.none,
    };
  }
}

class CustomerHomeSlider {
  const CustomerHomeSlider({
    required this.id,
    this.title,
    required this.imageUrl,
    this.linkType = CustomerHomeSliderLinkType.none,
    this.linkUrl,
    this.linkKitchenId,
    this.linkDishId,
  });

  final int id;
  final String? title;
  final String imageUrl;
  final CustomerHomeSliderLinkType linkType;
  final String? linkUrl;
  final int? linkKitchenId;
  final int? linkDishId;

  bool get hasLink => linkType != CustomerHomeSliderLinkType.none;

  factory CustomerHomeSlider.fromJson(Map<String, dynamic> json) {
    return CustomerHomeSlider(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      linkType: CustomerHomeSliderLinkType.fromApi(json['link_type'] as String?),
      linkUrl: json['link_url'] as String?,
      linkKitchenId: (json['link_kitchen_id'] as num?)?.toInt(),
      linkDishId: (json['link_dish_id'] as num?)?.toInt(),
    );
  }
}

class CustomerHomeSlidersPayload {
  const CustomerHomeSlidersPayload({
    required this.hero,
    required this.mid,
  });

  final List<CustomerHomeSlider> hero;
  final List<CustomerHomeSlider> mid;
}
