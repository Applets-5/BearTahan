import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Text('Notifications', style: AppTextStyles.screenTitle),
          Text('2 unread', style: AppTextStyles.small),
          SizedBox(height: AppSpacing.lg),
          _NotificationTile(
            icon: Icons.card_giftcard,
            title: 'Aina wants to redeem Extra Screen Time',
            time: 'Just now',
            unread: true,
          ),
          SizedBox(height: AppSpacing.md),
          _NotificationTile(
            icon: Icons.flag,
            title: 'Aina met today\'s daily goal',
            time: '2h ago',
            unread: true,
          ),
          SizedBox(height: AppSpacing.md),
          _NotificationTile(
            icon: Icons.emoji_events,
            title: 'Chapter completed in Bahasa Melayu',
            time: 'Yesterday',
            unread: false,
          ),
        ],
      ),
    );
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.muted,
            child: Icon(
              icon,
              color: unread ? AppColors.primary : AppColors.mutedText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyBold),
                Text(time, style: AppTextStyles.tiny),
              ],
            ),
          ),
          if (unread) const Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }
}
