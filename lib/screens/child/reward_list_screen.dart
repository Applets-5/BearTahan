import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/missing_child_profile.dart';
import '../../widgets/parent/reward_card.dart';
import 'star_history_screen.dart';

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
    final subjectProgressAsync = ref.watch(subjectProgressProvider(childId));

    return SafeArea(
      child: rewardsAsync.when(
        data: (rewards) {
          final availableRewards = rewards
              .where((r) => r.status == 'available')
              .toList();

          final int currentBalance = userProfileAsync.value?.starBalance ?? 0;

          // Sort: Enough stars first, then not enough
          availableRewards.sort((a, b) {
            final aEnough = currentBalance >= a.cost;
            final bEnough = currentBalance >= b.cost;
            if (aEnough && !bEnough) return -1;
            if (!aEnough && bEnough) return 1;
            return a.cost.compareTo(b.cost); // Within groups, sort by cost
          });

          final pendingRewards = rewards
              .where((r) => r.status == 'pending')
              .toList();

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
                        value: profile.starBalance.toString(),
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
                    child: subjectProgressAsync.when(
                      data: (subjects) {
                        final totalLifetime = subjects.fold(0, (sum, s) {
                          // Self-healing: if the subject exists but is missing aggregation, trigger a sync
                          if (s.totalStars == 0 && s.progress > 0) {
                            debugPrint(
                              'DEBUG: Self-healing triggered for ${s.id} on reward screen',
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final parentId = ref.read(parentIdProvider);
                              ref
                                  .read(firestoreServiceProvider)
                                  .syncSubjectAggregation(
                                    parentId,
                                    childId,
                                    s.id,
                                  );
                            });
                          }
                          return sum + s.totalStars;
                        });
                        return _StarSummary(
                          label: 'Lifetime',
                          value: totalLifetime.toString(),
                          icon: Icons.auto_awesome,
                          color: AppColors.star,
                        );
                      },
                      loading: () => _StarSummary(
                        label: 'Lifetime',
                        value: '0',
                        icon: Icons.auto_awesome,
                        color: AppColors.star,
                      ),
                      error: (err, stack) => _StarSummary(
                        label: 'Lifetime',
                        value: '0',
                        icon: Icons.auto_awesome,
                        color: AppColors.star,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (pendingRewards.isNotEmpty) ...[
                const Text('Pending Approval', style: AppTextStyles.tiny),
                const SizedBox(height: AppSpacing.sm),
                ...pendingRewards.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: RewardCard(
                      title: r.title,
                      description: r.description,
                      cost: r.cost,
                      status: r.status,
                      currentStars: userProfileAsync.value?.starBalance,
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
                    currentStars: userProfileAsync.value?.starBalance,
                    showBorder: false,
                    primaryLabel: 'Claim',
                    onPrimary: () async {
                      final profile = userProfileAsync.value;
                      if (profile == null) return;

                      if (profile.starBalance < r.cost) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Not enough stars!')),
                        );
                        return;
                      }

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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
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
