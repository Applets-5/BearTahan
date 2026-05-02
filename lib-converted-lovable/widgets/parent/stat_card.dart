import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSpacing.xxl),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.cardTitle),
          Text(label, style: AppTextStyles.tiny, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
