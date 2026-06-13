import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DailyGoalRingCard extends StatelessWidget {
  const DailyGoalRingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.target,
    required this.current,
    required this.unit,
    this.icon = Icons.flag,
    this.color = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final double progress;
  final int target;
  final int current;
  final String unit;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final bool isComplete = current >= target;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isComplete ? Icons.stars_rounded : icon,
                      size: 20,
                      color: isComplete ? AppColors.star : color,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(title, style: AppTextStyles.bodyBold),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.small,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 8,
                  backgroundColor: AppColors.muted,
                  color: isComplete ? AppColors.star : color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(clamped * 100).toInt()}%',
                    style: AppTextStyles.tiny.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
