import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StarBalanceChip extends StatelessWidget {
  const StarBalanceChip({
    super.key,
    required this.count,
    this.showPulse = false,
  });

  final int count;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: AppSpacing.xl, color: AppColors.star),
          const SizedBox(width: AppSpacing.xs),
          Text('$count', style: AppTextStyles.cardTitle),
        ],
      ),
    );
  }
}
