import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../theme/themed_background.dart';

class NotificationListScreen extends StatelessWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final notificationService = NotificationService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: notificationService.streamUserNotifications(user.id),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final hasUnread = notifications.any((n) => !n.read);
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton(
                onPressed: () async {
                  await notificationService.markAllAsRead(user.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Mark All Read'),
              );
            },
          ),
        ],
      ),
      body: ThemedBackground(
        child: StreamBuilder<List<NotificationModel>>(
          stream: notificationService.streamUserNotifications(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All caught up!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No new notifications for you right now.',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationItem(
                  notification: notification,
                  onTap: () {
                    if (!notification.read) {
                      notificationService.markAsRead(notification.id);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.read
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: notification.read
              ? null
              : Border.all(color: color.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.read
                                ? FontWeight.w600
                                : FontWeight.bold,
                            fontSize: 15,
                            color: notification.read
                                ? Colors.grey[800]
                                : Colors.black,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: notification.read
                          ? Colors.grey[600]
                          : Colors.grey[800],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatDate(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.verificationApproved:
        return Icons.verified_user;
      case NotificationType.verificationRejected:
        return Icons.gpp_bad;
      case NotificationType.bookingConfirmed:
        return Icons.check_circle;
      case NotificationType.bookingCancelled:
        return Icons.cancel;
      case NotificationType.messageReceived:
        return Icons.chat_bubble;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.verificationApproved:
        return Colors.green;
      case NotificationType.verificationRejected:
        return Colors.red;
      case NotificationType.bookingConfirmed:
        return Colors.blue;
      case NotificationType.bookingCancelled:
        return Colors.orange;
      case NotificationType.messageReceived:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
