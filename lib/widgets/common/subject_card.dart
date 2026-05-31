import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.progress,
    this.completedLevels = 0,
    this.totalStars = 0,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int progress;
  final int completedLevels;
  final int totalStars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: AppRadius.r(AppRadius.xl),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.r(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.r(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: AppRadius.r(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: AppSpacing.xxxl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: AppTextStyles.whiteTitle),
                        Text(subtitle, style: AppTextStyles.whiteSmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.r(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: AppSpacing.sm,
                  color: Colors.white70,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '$completedLevels pelajaran',
                        style: AppTextStyles.whiteSmall,
                      ),
                      const Text(' • ', style: AppTextStyles.whiteSmall),
                      Text('$totalStars ', style: AppTextStyles.whiteSmall),
                      const Icon(Icons.star, size: 12, color: Colors.white70),
                    ],
                  ),
                  Text(
                    '$progress% selesai',
                    style: AppTextStyles.whiteSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
