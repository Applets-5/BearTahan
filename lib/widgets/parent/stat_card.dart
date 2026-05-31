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
    const Color titleColor = Color(0xFF333333); // Dark Charcoal
    const Color subtitleColor = Color(0xFF666666); // Medium Slate Grey

    return Container(
      padding: const EdgeInsets.all(20.0), // Generous padding
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
        children: [
          Icon(icon, color: color, size: AppSpacing.xxl),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(color: titleColor),
          ),
          Text(
            label,
            style: AppTextStyles.tiny.copyWith(color: subtitleColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
