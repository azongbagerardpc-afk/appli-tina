import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/notification_item.dart';
import '../config/constants.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getGroqApiKey() => _prefs.getString(AppConstants.groqApiKeyKey);

  static Future<void> saveGroqApiKey(String key) async {
    await _prefs.setString(AppConstants.groqApiKeyKey, key);
  }

  static List<ChatMessage> getMessages() {
    final jsonStr = _prefs.getString(AppConstants.messagesKey);
    if (jsonStr == null) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => ChatMessage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveMessages(List<ChatMessage> messages) async {
    final toSave = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    await _prefs.setString(
      AppConstants.messagesKey,
      json.encode(toSave.map((m) => m.toJson()).toList()),
    );
  }

  static List<NotificationItem> getNotifications() {
    final jsonStr = _prefs.getString(AppConstants.notificationsKey);
    if (jsonStr == null) return [];
    try {
      final List list = json.decode(jsonStr);
      return list.map((e) => NotificationItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveNotifications(List<NotificationItem> notifications) async {
    final toSave = notifications.length > 100 ? notifications.sublist(0, 100) : notifications;
    await _prefs.setString(
      AppConstants.notificationsKey,
      json.encode(toSave.map((n) => n.toJson()).toList()),
    );
  }
}
