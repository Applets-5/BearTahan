import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/reward_claim.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/missing_child_profile.dart';
import '../../widgets/parent/reward_card.dart';

class RewardListScreen extends ConsumerWidget {
  const RewardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final routeChildId = GoRouterState.of(
      context,
    ).uri.queryParameters['childId'];
    final providerChildId = ref.watch(childIdProvider);
    final childId = routeChildId?.isNotEmpty == true
        ? routeChildId!
        : providerChildId ?? '';

    if (childId.isEmpty) {
      return const MissingChildProfile(
        message: 'Select a child profile to view rewards.',
      );
    }

    final userProfileAsync = ref.watch(userProfileProvider(childId));
    final parentId = ref.watch(parentIdProvider);
    final rewardClaimsAsync = ref.watch(
      rewardClaimsProvider((parentId: parentId, childId: childId)),
    );

    return SafeArea(
      child: rewardsAsync.when(
        data: (rewards) {
          final claims = rewardClaimsAsync.value ?? [];
          final pendingClaims = claims.where((c) => c.isPending).toList();
          final resolvedClaims = claims.where((c) => !c.isPending).toList();
          final pendingRewardIds = pendingClaims.map((c) => c.rewardId).toSet();
          final availableRewards = rewards
              .where(
                (r) =>
                    r.status == 'available' && !pendingRewardIds.contains(r.id),
              )
              .toList();

          final int currentBalance =
              userProfileAsync.value?.availableStars ?? 0;

          // Sort: Enough stars first, then not enough
          availableRewards.sort((a, b) {
            final aEnough = currentBalance >= a.cost;
            final bEnough = currentBalance >= b.cost;
            if (aEnough && !bEnough) return -1;
            if (!aEnough && bEnough) return 1;
            return a.cost.compareTo(b.cost); // Within groups, sort by cost
          });

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My Rewards', style: AppTextStyles.screenTitle),
                      Text(
                        'Spend stars on real-world treats!',
                        style: AppTextStyles.small,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: AppColors.primary),
                    onPressed: () {
                      context.push(
                        Uri(
                          path: AppRouter.starHistory,
                          queryParameters: {'childId': childId},
                        ).toString(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: userProfileAsync.when(
                      data: (profile) => _StarSummary(
                        label: 'Available',
                        value: profile.availableStars.toString(),
                        icon: Icons.star,
                        color: AppColors.star,
                      ),
                      loading: () => _StarSummary(
                        label: 'Available',
                        value: '0',
                        icon: Icons.star,
                        color: AppColors.star,
                      ),
                      error: (err, stack) => _StarSummary(
                        label: 'Available',
                        value: '0',
                        icon: Icons.star,
                        color: AppColors.star,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: userProfileAsync.when(
                      data: (profile) => _StarSummary(
                        label: 'Total Earned',
                        value: profile.lifetimeStarsEarned.toString(),
                        icon: Icons.auto_awesome,
                        color: AppColors.star,
                      ),
                      loading: () => _StarSummary(
                        label: 'Total Earned',
                        value: '0',
                        icon: Icons.auto_awesome,
                        color: AppColors.star,
                      ),
                      error: (err, stack) => _StarSummary(
                        label: 'Total Earned',
                        value: '0',
                        icon: Icons.auto_awesome,
                        color: AppColors.star,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (pendingClaims.isNotEmpty) ...[
                const Text('Pending Approval', style: AppTextStyles.tiny),
                const SizedBox(height: AppSpacing.sm),
                ...pendingClaims.map(
                  (claim) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: RewardCard(
                      title: claim.rewardName,
                      description: 'Pending — waiting for parent approval',
                      cost: claim.starCost,
                      status: claim.status,
                      currentStars: userProfileAsync.value?.availableStars,
                      showBorder: false,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const Text('Available', style: AppTextStyles.tiny),
              const SizedBox(height: AppSpacing.sm),
              if (availableRewards.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No rewards available yet. Ask your parent to add some!',
                      style: AppTextStyles.small,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ...availableRewards.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: RewardCard(
                    title: r.title,
                    description: r.description,
                    cost: r.cost,
                    status: r.status,
                    currentStars: userProfileAsync.value?.availableStars,
                    showBorder: false,
                    primaryLabel: 'Claim',
                    onPrimary: () async {
                      final profile = userProfileAsync.value;
                      if (profile == null) return;

                      if (profile.availableStars < r.cost) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not enough stars!')),
                        );
                        return;
                      }

                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Claim Reward'),
                          content: Text(
                            'This will use ${r.cost} stars. Are you sure?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Claim'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      try {
                        final parentId = ref.read(parentIdProvider);
                        await ref
                            .read(firestoreServiceProvider)
                            .claimReward(
                              parentId,
                              profile.uid,
                              r,
                              profile.name,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Requested ${r.title}!'),
                              backgroundColor: AppColors.accent,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  ),
                ),
              ),
              if (resolvedClaims.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text('Claim History', style: AppTextStyles.tiny),
                const SizedBox(height: AppSpacing.sm),
                ...resolvedClaims
                    .take(5)
                    .map(
                      (claim) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ClaimHistoryTile(claim: claim),
                      ),
                    ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ClaimHistoryTile extends StatelessWidget {
  const _ClaimHistoryTile({required this.claim});

  final RewardClaim claim;

  Color _statusColor() {
    switch (claim.status) {
      case 'approved':
        return AppColors.accent;
      case 'rejected':
        return AppColors.destructive;
      case 'expired':
        return AppColors.mutedText;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon() {
    switch (claim.status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  String _message() {
    switch (claim.status) {
      case 'approved':
        return 'Approved - ${claim.starCost} stars used';
      case 'rejected':
        return 'Rejected - stars unchanged';
      case 'expired':
        return 'Expired - stars unchanged';
      default:
        return claim.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final date = claim.resolvedAt ?? claim.claimedAt;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(), color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claim.rewardName, style: AppTextStyles.bodyBold),
                Text(
                  '${_message()} - ${DateFormat('dd MMM yyyy').format(date)}',
                  style: AppTextStyles.tiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarSummary extends StatelessWidget {
  const _StarSummary({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const Color titleColor = Color(0xFF333333); // Dark Charcoal
    const Color subtitleColor = Color(0xFF666666); // Medium Slate Grey

    return Container(
      padding: const EdgeInsets.all(24.0), // Generous padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0), // Highly rounded
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.cardTitle.copyWith(color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.tiny.copyWith(color: subtitleColor)),
        ],
      ),
    );
  }
}
