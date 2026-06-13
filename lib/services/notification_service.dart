import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import 'storage_service.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationItem> _notifications = [];
  bool _isPermissionGranted = false;

  List<NotificationItem> get notifications => _notifications;
  bool get isPermissionGranted => _isPermissionGranted;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationService() {
    _init();
  }

  void _init() {
    _notifications = StorageService.getNotifications();
    notifyListeners();
  }

  Future<void> requestPermission() async {
    _isPermissionGranted = true;
    notifyListeners();
  }

  Future<void> recheckPermission() async {
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
