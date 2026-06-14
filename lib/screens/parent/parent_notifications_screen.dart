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
                final tile = InkWell(
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
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: n.isRead
                      ? _SwipeableNotificationWrapper(
                          onToggleRead: () {
                            ref
                                .read(firestoreServiceProvider)
                                .markNotificationAsUnread(parentId, n.id);
                          },
                          child: tile,
                        )
                      : tile,
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

class _SwipeableNotificationWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onToggleRead;

  const _SwipeableNotificationWrapper({
    required this.child,
    required this.onToggleRead,
  });

  @override
  State<_SwipeableNotificationWrapper> createState() =>
      _SwipeableNotificationWrapperState();
}

class _SwipeableNotificationWrapperState
    extends State<_SwipeableNotificationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0;
  static const double _actionWidth = 100;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      if (_dragExtent > 0) _dragExtent = 0;
      if (_dragExtent < -_actionWidth - 20) _dragExtent = -_actionWidth - 20;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragExtent < -_actionWidth / 2) {
      _open();
    } else {
      _close();
    }
  }

  void _open() {
    _controller.animateTo(1.0, curve: Curves.easeOut);
    setState(() => _dragExtent = -_actionWidth);
  }

  void _close() {
    _controller.animateTo(0.0, curve: Curves.easeOut);
    setState(() => _dragExtent = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.r(AppRadius.lg),
              color: AppColors.primary,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    _close();
                    widget.onToggleRead();
                  },
                  child: Container(
                    width: _actionWidth,
                    color: Colors.transparent,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_as_unread, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'Unread',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double offset = _dragExtent;
            if (_controller.isAnimating) {
              offset = -_controller.value * _actionWidth;
            }
            return Transform.translate(offset: Offset(offset, 0), child: child);
          },
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.opaque,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
