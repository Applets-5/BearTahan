import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import 'notification_detail_screen.dart';

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final parentId = ref.watch(parentIdProvider);

    return SafeArea(
      child: notificationsAsync.when(
        data: (notifications) {
          final unreadCount = notifications.where((n) => !n.isRead).length;

          if (notifications.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text('Notifications', style: AppTextStyles.screenTitle),
                const SizedBox(height: AppSpacing.xl),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: AppColors.mutedText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'No notifications yet',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: AppTextStyles.screenTitle,
                      ),
                      Text(
                        '$unreadCount unread',
                        style: AppTextStyles.small.copyWith(
                          color: unreadCount > 0 ? AppColors.primary : null,
                          fontWeight: unreadCount > 0 ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(firestoreServiceProvider)
                            .markAllNotificationsAsRead(parentId);
                      },
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text(
                        'Mark all as read',
                        style: AppTextStyles.tiny,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...notifications.map((n) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Dismissible(
                    key: Key('noti_${n.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: n.isRead ? AppColors.primary : Colors.grey,
                        borderRadius: AppRadius.r(AppRadius.lg),
                      ),
                      child: Icon(
                        n.isRead ? Icons.mark_as_unread : Icons.done,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      if (n.isRead) {
                        ref
                            .read(firestoreServiceProvider)
                            .markNotificationAsUnread(parentId, n.id);
                      } else {
                        ref
                            .read(firestoreServiceProvider)
                            .markNotificationAsRead(parentId, n.id);
                      }
                    },
                    child: InkWell(
                      onTap: () {
                        if (!n.isRead) {
                          ref
                              .read(firestoreServiceProvider)
                              .markNotificationAsRead(parentId, n.id);
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NotificationDetailScreen(notification: n),
                          ),
                        );
                      },
                      child: _NotificationTile(
                        icon: n.icon,
                        title: n.title,
                        time: _formatTime(n.timestamp),
                        unread: !n.isRead,
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM').format(timestamp);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.time,
    required this.unread,
  });
  final IconData icon;
  final String title;
  final String time;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: unread ? AppColors.primaryLight : AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
        border: unread
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: unread ? AppColors.primary : AppColors.muted,
            child: Icon(
              icon,
              color: unread ? Colors.white : AppColors.mutedText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: unread ? AppColors.primary : null,
                  ),
                ),
                Text(time, style: AppTextStyles.tiny),
              ],
            ),
          ),
          if (unread)
            const Icon(Icons.circle, size: 12, color: AppColors.primary),
        ],
      ),
    );
  }
}
