import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LockedLevelTile extends StatelessWidget {
  const LockedLevelTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.r(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.border,
            child: Icon(Icons.lock, color: AppColors.mutedText),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
