import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../models/notification_item.dart';
import '../config/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, service, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('Notifications'),
                if (service.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${service.unreadCount}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (service.isPermissionGranted) ...[
                if (service.notifications.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.done_all, size: 20),
                    onPressed: service.markAllRead,
                    tooltip: 'Tout marquer comme lu',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: service.recheckPermission,
                  tooltip: 'Actualiser',
                ),
              ],
            ],
          ),
          body: !service.isPermissionGranted
              ? _PermissionRequest(service: service)
              : service.notifications.isEmpty
                  ? const _EmptyState()
                  : _NotificationList(notifications: service.notifications),
        );
      },
    );
  }
}

class _PermissionRequest extends StatelessWidget {
  final NotificationService service;
  const _PermissionRequest({required this.service});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.notifications_active,
                  color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accès aux notifications',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Pour que Tina te prévienne de tes messages WhatsApp, Facebook, Instagram et TikTok, elle a besoin d\'accéder à tes notifications.',
              style: TextStyle(
                  color: Colors.white54, fontSize: 14, height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tes messages restent privés, Tina ne lit que le nom de l\'expéditeur et la notification.',
              style: TextStyle(
                  color: Colors.white38, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Activer les notifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: service.recheckPermission,
              child: const Text(
                'J\'ai déjà activé, vérifier',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              color: Colors.white12, size: 48),
          SizedBox(height: 12),
          Text('Aucune notification pour l\'instant',
              style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<NotificationItem> notifications;
  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notifications.length,
      itemBuilder: (ctx, i) => _NotifCard(notif: notifications[i]),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationItem notif;
  const _NotifCard({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notif.isRead ? AppTheme.surface : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: notif.isRead
            ? null
            : Border.all(color: AppTheme.primary.withOpacity(0.18)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Text(notif.appIcon,
            style: const TextStyle(fontSize: 26)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notif.title.isNotEmpty ? notif.title : notif.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      notif.isRead ? FontWeight.normal : FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(notif.timestamp),
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ],
        ),
        subtitle: notif.body.isNotEmpty
            ? Text(
                notif.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
              )
            : null,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'maintenant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}
