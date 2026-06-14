import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import '../../models/reward_claim.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.notification});
  final ParentNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForType(notification.type)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: switch (notification.type) {
          'reward' ||
          'reward_claimed' => _RewardDetail(notification: notification),
          'goal_complete' => _GoalDetail(notification: notification),
          'streak_risk' => _StreakDetail(notification: notification),
          _ => _GenericDetail(notification: notification),
        },
      ),
    );
  }

  String _titleForType(String type) => switch (type) {
    'reward' || 'reward_claimed' => 'Reward request',
    'goal_complete' => 'Goal completed',
    'streak_risk' => 'Streak at risk',
    _ => 'Notification',
  };
}

// ── Reward detail ─────────────────────────────────────────────────────────────

class _RewardDetail extends ConsumerWidget {
  const _RewardDetail({required this.notification});
  final ParentNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(parentIdProvider);
    final childId = notification.childId ?? '';
    final claimsAsync = ref.watch(
      rewardClaimsProvider((parentId: parentId, childId: childId)),
    );

    return claimsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (claims) {
        // Find the specific pending claim from the notification payload
        final claim = claims
            .where((c) => c.isPending)
            .cast<RewardClaim?>()
            .firstWhere(
              (c) =>
                  c?.rewardName ==
                  notification.title.split(' wants to redeem ').last,
              orElse: () => claims
                  .where((c) => c.isPending)
                  .cast<RewardClaim?>()
                  .firstOrNull,
            );

        if (claim == null) {
          return const Center(
            child: Text('This claim has already been resolved.'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _HeroCard(
              icon: Icons.card_giftcard_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: '${claim.childName} wants to redeem ${claim.rewardName}',
              subtitle:
                  'Claimed on ${DateFormat('dd MMM yyyy, hh:mm a').format(claim.claimedAt)}',
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailCard(
              label: 'Reward details',
              rows: [
                _DetailRow(
                  icon: Icons.label_outline,
                  label: 'Reward',
                  value: claim.rewardName,
                ),
                _DetailRow(
                  icon: Icons.star_outline,
                  label: 'Cost',
                  value: '${claim.starCost} stars',
                ),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Status',
                  value: claim.status,
                  valueWidget: const _Pill(
                    label: 'Pending',
                    color: Color(0xFFFEF3C7),
                    textColor: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Approve',
                    onPressed: () async {
                      await ref
                          .read(firestoreServiceProvider)
                          .approveRewardClaim(parentId, claim);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Decline',
                    backgroundColor: AppColors.muted,
                    foregroundColor: AppColors.foreground,
                    onPressed: () async {
                      await ref
                          .read(firestoreServiceProvider)
                          .rejectRewardClaim(parentId, claim);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Goal detail ───────────────────────────────────────────────────────────────

class _GoalDetail extends ConsumerWidget {
  const _GoalDetail({required this.notification});
  final ParentNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = notification.childId ?? '';
    final profileAsync = ref.watch(userProfileProvider(childId));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profile) {
        final goal = profile.dailyGoal;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _HeroCard(
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFD1FAE5),
              title: '${profile.name} completed today\'s learning goal',
              subtitle:
                  '${goal?.todayProgress ?? 0} of ${goal?.target ?? 0} ${goal?.unitLabel ?? 'lessons'}',
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailCard(
              label: 'Today\'s stats',
              rows: [
                _DetailRow(
                  icon: Icons.flag_outlined,
                  label: 'Daily goal',
                  value:
                      '${goal?.target ?? 0} ${goal?.unitLabel ?? 'lessons'} / day',
                ),
                _DetailRow(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Streak',
                  value: '${profile.streakCount} days',
                ),
                _DetailRow(
                  icon: Icons.star_outline,
                  label: 'Available stars',
                  value: '${profile.availableStars}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'View ${profile.name}\'s dashboard',
              onPressed: () {
                ref.read(childIdProvider.notifier).update(childId);
                context.go(AppRouter.parentDashboard);
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Streak detail ─────────────────────────────────────────────────────────────

class _StreakDetail extends ConsumerWidget {
  const _StreakDetail({required this.notification});
  final ParentNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childId = notification.childId ?? '';
    final profileAsync = ref.watch(userProfileProvider(childId));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (profile) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _HeroCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title:
                '${profile.name}\'s ${profile.streakCount}-day streak ends at midnight',
            subtitle: 'No activity recorded today yet',
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailCard(
            label: 'Streak status',
            rows: [
              _DetailRow(
                icon: Icons.local_fire_department_outlined,
                label: 'Current streak',
                value: '${profile.streakCount} days',
              ),
              _DetailRow(
                icon: Icons.schedule_outlined,
                label: 'Time remaining',
                value: 'Ends at midnight',
                valueColor: const Color(0xFFD97706),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Switch to ${profile.name}',
            onPressed: () {
              ref.read(childIdProvider.notifier).update(childId);
              context.go(AppRouter.childHomeFor(childId));
            },
          ),
        ],
      ),
    );
  }
}

// ── Shared components ─────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: AppRadius.r(AppRadius.xl),
      boxShadow: AppShadows.card,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyBold),
              const SizedBox(height: 3),
              Text(subtitle, style: AppTextStyles.small),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.label, required this.rows});
  final String label;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: AppRadius.r(AppRadius.xl),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.tiny.copyWith(letterSpacing: 0.05),
        ),
        const SizedBox(height: AppSpacing.md),
        ...rows,
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
    this.valueColor,
  });
  final IconData icon;
  final String label, value;
  final Widget? valueWidget;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.small),
        const Spacer(),
        valueWidget ??
            Text(
              value,
              style: AppTextStyles.bodyBold.copyWith(color: valueColor),
            ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
  });
  final String label;
  final Color color, textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.r(20)),
    child: Text(label, style: AppTextStyles.tiny.copyWith(color: textColor)),
  );
}

class _GenericDetail extends StatelessWidget {
  const _GenericDetail({required this.notification});
  final ParentNotification notification;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text(notification.title, style: AppTextStyles.body),
  );
}
