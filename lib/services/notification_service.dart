import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_item.dart';
import 'storage_service.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isPermissionGranted = false;
  bool _isListening = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isPermissionGranted => _isPermissionGranted;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  static const Map<String, String> _appNames = {
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Messenger',
    'com.instagram.android': 'Instagram',
    'com.zhiliaoapp.musically': 'TikTok',
    'org.telegram.messenger': 'Telegram',
    'com.twitter.android': 'Twitter',
  };

  NotificationService() {
    _init();
  }

  Future<void> _init() async {
    _notifications = StorageService.getNotifications();
    _isPermissionGranted = await NotificationListenerService.isPermissionGranted();
    notifyListeners();
    if (_isPermissionGranted) _startListening();
  }

  void _startListening() {
    if (_isListening) return;
    _isListening = true;

    NotificationListenerService.notificationsStream.listen((ServiceNotificationEvent event) {
      final packageName = event.packageName ?? '';
      if (!_appNames.containsKey(packageName)) return;

      final notification = NotificationItem(
        id: const Uuid().v4(),
        appName: _appNames[packageName]!,
        title: event.title ?? '',
        body: event.content ?? '',
        timestamp: event.createAt ?? DateTime.now(),
      );

      _notifications.insert(0, notification);
      if (_notifications.length > 100) {
        _notifications = _notifications.sublist(0, 100);
      }

      StorageService.saveNotifications(_notifications);
      notifyListeners();
    });
  }

  Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
    await Future.delayed(const Duration(seconds: 1));
    _isPermissionGranted = await NotificationListenerService.isPermissionGranted();
    if (_isPermissionGranted) _startListening();
    notifyListeners();
  }

  Future<void> recheckPermission() async {
    _isPermissionGranted = await NotificationListenerService.isPermissionGranted();
    if (_isPermissionGranted && !_isListening) _startListening();
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    StorageService.saveNotifications(_notifications);
    notifyListeners();
  }

  void clearAll() {
    _notifications = [];
    StorageService.saveNotifications([]);
    notifyListeners();
  }
}
