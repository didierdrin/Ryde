import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/models/notification.dart' as notification_model;
import 'package:ryde_rw/service/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class Notifications extends ConsumerWidget {
  final VoidCallback? onDelete;
  
  const Notifications({super.key, this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(NotificationService.userNotificationStream);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  notificationsAsync.when(
                    data: (notifications) => notifications.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.delete_sweep),
                            onPressed: () => _deleteAll(context, notifications),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No notifications', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNotification(notification),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notification.isRead ? Colors.grey : Colors.blue,
                            child: Icon(
                              _getIcon(notification.data['type']),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.body),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(notification.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => _markAsRead(notification),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'trip_request':
        return Icons.directions_car;
      case 'trip_accepted':
        return Icons.check_circle;
      case 'trip_rejected':
        return Icons.cancel;
      case 'driver_offer':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAsRead(notification_model.UserNotification notification) async {
    if (!notification.isRead) {
      await NotificationService.readNotifications([notification.id]);
    }
  }

  Future<void> _deleteNotification(notification_model.UserNotification notification) async {
    await NotificationService.deleteAllNotifications([notification]);
  }

  Future<void> _deleteAll(BuildContext context, List<notification_model.UserNotification> notifications) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService.deleteAllNotifications(notifications);
      if (onDelete != null) onDelete!();
    }
  }
}
