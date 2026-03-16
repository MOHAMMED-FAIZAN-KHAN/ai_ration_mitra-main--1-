enum NotificationAudience { citizen, dealer, all }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationAudience audience;
  final DateTime createdAt;
  final String? createdBy;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.createdAt,
    this.createdBy,
    this.isRead = false,
  });

  String get audienceKey {
    switch (audience) {
      case NotificationAudience.citizen:
        return 'citizen';
      case NotificationAudience.dealer:
        return 'dealer';
      case NotificationAudience.all:
        return 'all';
    }
  }

  static NotificationAudience parseAudience(String? value) {
    switch (value) {
      case 'citizen':
        return NotificationAudience.citizen;
      case 'dealer':
        return NotificationAudience.dealer;
      case 'all':
      default:
        return NotificationAudience.all;
    }
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationAudience? audience,
    DateTime? createdAt,
    String? createdBy,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      audience: audience ?? this.audience,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isRead: isRead ?? this.isRead,
    );
  }
}
