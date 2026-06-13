class NotificationItem {
  final String id;
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  String get appIcon {
    switch (appName.toLowerCase()) {
      case 'whatsapp':
        return '💬';
      case 'facebook':
        return '👤';
      case 'messenger':
        return '💙';
      case 'instagram':
        return '📸';
      case 'tiktok':
        return '🎵';
      case 'telegram':
        return '✈️';
      default:
        return '🔔';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'appName': appName,
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    appName: json['appName'],
    title: json['title'],
    body: json['body'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
  );
}
