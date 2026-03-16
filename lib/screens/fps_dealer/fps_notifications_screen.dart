import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../models/fps_operations.dart';
import '../../providers/fps_operations_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';

class FPSNotificationsScreen extends StatefulWidget {
  const FPSNotificationsScreen({super.key});

  @override
  State<FPSNotificationsScreen> createState() => _FPSNotificationsScreenState();
}

class _FPSNotificationsScreenState extends State<FPSNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ops = context.watch<FPSOperationsProvider>();
    final adminNotifications = context
        .watch<NotificationProvider>()
        .notificationsForAudience(NotificationAudience.dealer);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dealer Notifications'),
        actions: [
          if (ops.unreadNotificationCount > 0)
            TextButton(
              onPressed: () =>
                  context.read<FPSOperationsProvider>().markAllNotificationsAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: ops.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (ops.notifications.isEmpty && adminNotifications.isEmpty)
              ? const AppEmptyState(
                  icon: Icons.notifications_none,
                  title: 'No notifications',
                  message: 'You will see updates here when they arrive.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (adminNotifications.isNotEmpty) ...[
                      const SectionHeader(
                        title: 'Admin Broadcasts',
                        icon: Icons.campaign_outlined,
                      ),
                      ...adminNotifications.map((notice) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.purple.withValues(alpha: 0.07),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple.withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.campaign_outlined,
                                color: Colors.purple,
                              ),
                            ),
                            title: Text(
                              notice.title,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(notice.message),
                            trailing: Text(
                              _formatTime(notice.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      const Divider(),
                      const SizedBox(height: 6),
                    ],
                    if (ops.notifications.isNotEmpty)
                      const SectionHeader(
                        title: 'System Notifications',
                        icon: Icons.notifications_active_outlined,
                      ),
                    ...ops.notifications.map((notification) {
                      final color = _levelColor(notification.level);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: notification.isRead ? null : color.withValues(alpha: 0.08),
                        child: ListTile(
                          onTap: () => context
                              .read<FPSOperationsProvider>()
                              .markNotificationAsRead(notification.id),
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.16),
                            child: Icon(_levelIcon(notification.level), color: color),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(notification.message),
                          trailing: Text(
                            _formatTime(notification.createdAt),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }

  Color _levelColor(DealerNotificationLevel level) {
    switch (level) {
      case DealerNotificationLevel.critical:
        return Colors.red;
      case DealerNotificationLevel.warning:
        return Colors.orange;
      case DealerNotificationLevel.info:
        return Colors.blue;
    }
  }

  IconData _levelIcon(DealerNotificationLevel level) {
    switch (level) {
      case DealerNotificationLevel.critical:
        return Icons.priority_high;
      case DealerNotificationLevel.warning:
        return Icons.warning_amber_rounded;
      case DealerNotificationLevel.info:
        return Icons.notifications_active_outlined;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}
