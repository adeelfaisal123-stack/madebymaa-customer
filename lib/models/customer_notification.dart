import '../utils/optica2_asset_url.dart';

/// In-app notification from the backend inbox.
class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.isRead,
    this.createdAt,
    this.createdAtHuman = '',
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final String? imageUrl;
  final bool isRead;
  final String? createdAt;
  final String createdAtHuman;

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      imageUrl: resolveOptica2AssetUrl(json['image_url'] as String?),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String?,
      createdAtHuman: json['created_at_human'] as String? ?? '',
    );
  }
}

class CustomerNotificationsResult {
  const CustomerNotificationsResult({
    required this.notifications,
    required this.unreadCount,
  });

  final List<CustomerNotification> notifications;
  final int unreadCount;

  factory CustomerNotificationsResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['notifications'];
    final list = rawList is List
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(CustomerNotification.fromJson)
            .toList()
        : <CustomerNotification>[];

    return CustomerNotificationsResult(
      notifications: list,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
