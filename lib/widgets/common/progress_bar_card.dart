import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ProgressBarCard extends StatelessWidget {
  const ProgressBarCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.icon = Icons.flag,
    this.color = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final double progress;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSpacing.xl, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.bodyBold)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadius.r(AppRadius.sm),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: AppSpacing.sm,
              color: color,
              backgroundColor: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
