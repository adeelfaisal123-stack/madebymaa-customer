class CustomerStartupPopup {
  const CustomerStartupPopup({
    required this.enabled,
    required this.title,
    required this.content,
  });

  final bool enabled;
  final String title;
  final String content;

  factory CustomerStartupPopup.fromJson(Map<String, dynamic> json) {
    return CustomerStartupPopup(
      enabled: json['enabled'] == true,
      title: (json['title'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
    );
  }
}
