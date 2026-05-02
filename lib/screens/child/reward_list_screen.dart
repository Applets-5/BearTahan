import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/star_balance_chip.dart';
import '../../widgets/parent/reward_card.dart';

class RewardListScreen extends StatelessWidget {
  const RewardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          Text('My Rewards', style: AppTextStyles.screenTitle),
          Text('Spend stars on real-world treats!', style: AppTextStyles.small),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StarSummary(label: 'Available', value: '120'),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StarSummary(label: 'Lifetime', value: '340'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          RewardCard(
            title: 'Pizza Night',
            description: 'Family pizza dinner this weekend',
            cost: 80,
            status: 'available',
          ),
          SizedBox(height: AppSpacing.md),
          RewardCard(
            title: 'Extra Screen Time',
            description: '20 minutes after homework',
            cost: 40,
            status: 'pending',
          ),
          SizedBox(height: AppSpacing.md),
          RewardCard(
            title: 'Park Trip',
            description: 'Sunday morning playground visit',
            cost: 150,
            status: 'available',
          ),
        ],
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
