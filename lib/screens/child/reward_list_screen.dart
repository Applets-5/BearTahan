import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/star_balance_chip.dart';
import '../../widgets/parent/reward_card.dart';

class RewardListScreen extends ConsumerWidget {
  const RewardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsAsync = ref.watch(rewardsProvider);
    final childId = ref.watch(childIdProvider);
    final userProfileAsync = ref.watch(userProfileProvider(childId ?? ''));

    return SafeArea(
      child: rewardsAsync.when(
        data: (rewards) {
          final availableRewards = rewards
              .where((r) => r.status == 'available')
              .toList();
          final pendingRewards = rewards
              .where((r) => r.status == 'pending')
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text('My Rewards', style: AppTextStyles.screenTitle),
              const Text(
                'Spend stars on real-world treats!',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: userProfileAsync.when(
                      data: (profile) => _StarSummary(
                        label: 'Available',
                        value: profile.starBalance.toString(),
                      ),
                      loading: () =>
                          const _StarSummary(label: 'Available', value: '0'),
                      error: (err, stack) =>
                          const _StarSummary(label: 'Available', value: '0'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: _StarSummary(
                      label: 'Lifetime',
                      value: '340',
                    ), // Placeholder for lifetime stars
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
  const _StarSummary({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarBalanceChip(count: int.parse(value)),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: AppTextStyles.tiny),
        ],
      ),
    );
  }
}
