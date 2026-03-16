import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/app_empty_state.dart';

class CitizenNotificationsScreen extends StatefulWidget {
  const CitizenNotificationsScreen({super.key});

  @override
  State<CitizenNotificationsScreen> createState() =>
      _CitizenNotificationsScreenState();
}

class _CitizenNotificationsScreenState extends State<CitizenNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  final List<Map<String, dynamic>> _localNotifications = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'n1',
      'title': 'Ration Collection Reminder',
      'message':
          'Your next ration collection is on 20/03/2026 at Shyam Ration Store.',
      'time': 'Today',
      'category': 'distribution',
      'icon': Icons.calendar_today,
    },
    <String, dynamic>{
      'id': 'n2',
      'title': 'Distribution Status Updated',
      'message': 'March distribution list has been published for your category.',
      'time': 'Yesterday',
      'category': 'distribution',
      'icon': Icons.local_shipping,
    },
    <String, dynamic>{
      'id': 'n3',
      'title': 'Grievance Update',
      'message': 'Your grievance #2 is now in progress.',
      'time': '2 days ago',
      'category': 'grievance',
      'icon': Icons.feedback_outlined,
    },
    <String, dynamic>{
      'id': 'n4',
      'title': 'Profile Verified',
      'message': 'Your profile details are verified successfully.',
      'time': '3 days ago',
      'category': 'account',
      'icon': Icons.verified_user,
    },
  ];

  String _filter = 'all';

  Future<void> _markAllAsRead(List<Map<String, dynamic>> allNotifications) async {
    final provider = context.read<NotificationProvider>();
    await provider.markAllAsReadForAudience(NotificationAudience.citizen);
    for (final item in allNotifications) {
      final id = (item['id'] as String?) ?? '';
      if (id.isNotEmpty) {
        await provider.markAsRead(id);
      }
    }
  }

  void _clearRead() {
    setState(() {
      final provider = context.read<NotificationProvider>();
      _localNotifications.removeWhere((item) {
        final id = (item['id'] as String?) ?? '';
        return id.isNotEmpty && provider.isRead(id);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    final dynamicItems = notificationProvider
        .notificationsForAudience(NotificationAudience.citizen)
        .map((notice) => <String, dynamic>{
              'id': notice.id,
              'title': notice.title,
              'message': notice.message,
              'time': _formatDynamicTime(notice.createdAt),
              'category': 'admin',
              'unread': !notice.isRead,
              'icon': Icons.campaign_outlined,
            })
        .toList();
    final localItems = _localNotifications.map((notice) {
      final id = (notice['id'] as String?) ?? '';
      return <String, dynamic>{
        ...notice,
        'unread': id.isNotEmpty ? !notificationProvider.isRead(id) : false,
      };
    }).toList();
    final allNotifications = <Map<String, dynamic>>[
      ...dynamicItems,
      ...localItems,
    ];
    final unreadCount = allNotifications
        .where((item) => (item['unread'] as bool?) ?? false)
        .length;
    final filtered = allNotifications.where((item) {
      if (_filter == 'unread') {
        return (item['unread'] as bool?) ?? false;
      }
      if (_filter == 'distribution') {
        return item['category'] == 'distribution';
      }
      if (_filter == 'grievance') {
        return item['category'] == 'grievance';
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark') {
                _markAllAsRead(allNotifications);
              } else if (value == 'clear') {
                _clearRead();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'mark',
                child: Text('Mark all as read'),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Text('Clear read notifications'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.saffron.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.saffron.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: AppColors.saffron),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    unreadCount == 0
                        ? 'All notifications are read'
                        : '$unreadCount unread notifications',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('all', 'All'),
                _filterChip('unread', 'Unread'),
                _filterChip('distribution', 'Distribution'),
                _filterChip('grievance', 'Grievance'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const AppEmptyState(
                    icon: Icons.notifications_none,
                    title: 'No notifications',
                    message: 'You will see updates here when they arrive.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isUnread = (item['unread'] as bool?) ?? false;
                      return Card(
                        elevation: isUnread ? 2 : 0.5,
                        color: isUnread
                            ? AppColors.saffron.withValues(alpha: 0.08)
                            : null,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final id = (item['id'] as String?) ?? '';
                            if (id.isNotEmpty) {
                              await context.read<NotificationProvider>().markAsRead(id);
                            }
                            _openNotificationDetail(item);
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.saffron.withValues(alpha: 0.14),
                              child: Icon(
                                item['icon'] as IconData? ?? Icons.notifications,
                                color: AppColors.saffron,
                              ),
                            ),
                            title: Text(
                              item['title'] as String? ?? '',
                              style: TextStyle(
                                fontWeight:
                                    isUnread ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(item['message'] as String? ?? ''),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  item['time'] as String? ?? '',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                if (isUnread)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.saffron,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  void _openNotificationDetail(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] as String? ?? '',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                item['message'] as String? ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 14),
              Text(
                'Received: ${item['time']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDynamicTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }
}
