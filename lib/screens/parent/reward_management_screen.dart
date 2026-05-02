import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/parent/reward_card.dart';

class RewardManagementScreen extends StatefulWidget {
  const RewardManagementScreen({super.key});

  @override
  State<RewardManagementScreen> createState() => _RewardManagementScreenState();
}

class _RewardManagementScreenState extends State<RewardManagementScreen> {
  bool showForm = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Manage Rewards', style: AppTextStyles.screenTitle),
              ),
              FilledButton.icon(
                onPressed: () => setState(() => showForm = !showForm),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          const Text('Set goals for your child', style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.md),
          if (showForm) const _RewardForm(),
          const Text('Pending claims (1)', style: AppTextStyles.tiny),
          const SizedBox(height: AppSpacing.sm),
          const RewardCard(
            title: 'Extra Screen Time',
            description: 'Aina wants to redeem this reward',
            cost: 40,
            status: 'pending',
            primaryLabel: 'Approve',
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Available rewards', style: AppTextStyles.tiny),
          const SizedBox(height: AppSpacing.sm),
          const RewardCard(
            title: 'Pizza Night',
            description: 'Family pizza dinner this weekend',
            cost: 80,
          ),
          const SizedBox(height: AppSpacing.md),
          const RewardCard(
            title: 'Park Trip',
            description: 'Sunday morning playground visit',
            cost: 150,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Redeemed', style: AppTextStyles.tiny),
          const SizedBox(height: AppSpacing.sm),
          const RewardCard(
            title: 'Ice Cream',
            description: 'Redeemed last week',
            cost: 30,
            status: 'redeemed',
          ),
        ],
      ),
    );
  }
}

class _RewardForm extends StatelessWidget {
  const _RewardForm();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Reward', style: AppTextStyles.bodyBold),
          SizedBox(height: AppSpacing.md),
          TextField(decoration: InputDecoration(hintText: 'Reward name')),
          SizedBox(height: AppSpacing.sm),
          TextField(decoration: InputDecoration(hintText: 'Description')),
          SizedBox(height: AppSpacing.sm),
          TextField(
            decoration: InputDecoration(hintText: 'Star cost'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
