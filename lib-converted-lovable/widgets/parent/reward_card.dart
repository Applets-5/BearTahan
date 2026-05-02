import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.title,
    required this.description,
    required this.cost,
    this.status = 'available',
    this.onPrimary,
    this.primaryLabel,
  });

  final String title;
  final String description;
  final int cost;
  final String status;
  final VoidCallback? onPrimary;
  final String? primaryLabel;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final redeemed = status == 'redeemed';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: redeemed
            ? AppColors.muted
            : pending
            ? AppColors.secondaryLight
            : AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        border: Border.all(
          color: pending ? AppColors.secondary : AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.bodyBold)),
              if (status != 'available') _StatusPill(label: status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.sm),
          Text('Cost: $cost stars', style: AppTextStyles.tiny),
          if (onPrimary != null && primaryLabel != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Text(label, style: AppTextStyles.tiny),
    );
  }
}
