import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LevelTile extends StatelessWidget {
  const LevelTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stars,
    required this.onTap,
    this.isBoss = false,
  });

  final String title;
  final String subtitle;
  final int stars;
  final VoidCallback onTap;
  final bool isBoss;

  @override
  Widget build(BuildContext context) {
    final color = isBoss ? AppColors.secondary : AppColors.card;
    return Material(
      color: color,
      borderRadius: AppRadius.r(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isBoss
                    ? AppColors.secondaryText
                    : AppColors.primaryLight,
                child: Icon(
                  isBoss ? Icons.emoji_events : Icons.play_arrow,
                  color: isBoss ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyBold),
                    Text(subtitle, style: AppTextStyles.small),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.star,
                    size: AppSpacing.lg,
                    color: i < stars ? AppColors.star : AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
