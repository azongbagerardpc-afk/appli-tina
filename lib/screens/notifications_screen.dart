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
                const Text('Alertes'),
                if (service.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${service.unreadCount}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (service.isPermissionGranted) ...[
                if (service.notifications.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.done_all_rounded, size: 20),
                    onPressed: service.markAllRead,
                    tooltip: 'Tout marquer comme lu',
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
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
                  : _NotificationList(
                      notifications: service.notifications),
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
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    AppTheme.accent.withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.35), width: 1.5),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: AppTheme.primary, size: 34),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accès aux notifications',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Pour que Tina te prévienne de tes messages WhatsApp, Facebook, Instagram et TikTok, elle a besoin d\'accéder à tes notifications.',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.55),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tes messages restent privés. Tina ne lit que le nom de l\'expéditeur et le résumé.',
              style: TextStyle(
                  color: AppTheme.textTertiary, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: service.requestPermission,
                child: const Text('Activer les alertes'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: service.recheckPermission,
              child: const Text(
                'J\'ai déjà activé, vérifier',
                style: TextStyle(
                    color: AppTheme.textTertiary, fontSize: 13),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceVariant,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.notifications_off_outlined,
                color: AppTheme.textTertiary, size: 28),
          ),
          const SizedBox(height: 16),
          const Text('Aucune alerte pour l\'instant',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Les nouvelles notifications apparaîtront ici',
              style: TextStyle(
                  color: AppTheme.textTertiary, fontSize: 12)),
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
        border: Border.all(
          color: notif.isRead
              ? AppTheme.border
              : AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.background,
            border: Border.all(color: AppTheme.border),
          ),
          child: Center(
            child: Text(notif.appIcon,
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notif.title.isNotEmpty ? notif.title : notif.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: notif.isRead
                      ? FontWeight.w400
                      : FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(notif.timestamp),
              style: const TextStyle(
                  color: AppTheme.textTertiary, fontSize: 11),
            ),
          ],
        ),
        subtitle: notif.body.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  notif.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              )
            : null,
        trailing: notif.isRead
            ? null
            : Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
              ),
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
