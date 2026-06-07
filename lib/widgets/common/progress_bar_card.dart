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
    const Color titleColor = Color(0xFF333333); // Dark Charcoal
    const Color subtitleColor = Color(0xFF666666); // Medium Slate Grey
    const Color trackPurple = Color(0xFF8A2BE2); // Vibrant Purple

    final clamped = progress.clamp(0.0, 1.0);
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
              Icon(icon, size: AppSpacing.xl, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyBold.copyWith(color: titleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.small.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: 16.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 12,
              color: trackPurple,
              backgroundColor: const Color(0xFFE6E6E6),
            ),
          ),
        ],
      ),
    );
  }
}
