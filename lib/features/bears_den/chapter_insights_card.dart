import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ChapterInsightsCard extends StatelessWidget {
  const ChapterInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text('Chapter Insights', style: AppTextStyles.cardTitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.subjectEnglish,
                  borderRadius: AppRadius.r(AppRadius.lg),
                ),
                child: const Text(
                  'English',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const _InsightRow(
            name: 'Chapter 0 - Foundation',
            stars: 3,
            badge: 'Strong',
            badgeColor: AppColors.accent,
            badgeTextColor: Colors.white,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const _InsightRow(
            name: 'Chapter 1',
            stars: 1,
            badge: 'Needs Work',
            badgeColor: AppColors.destructive,
            badgeTextColor: Colors.white,
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const _InsightRow(
            name: 'Chapter 2',
            stars: 2,
            badge: 'Average',
            badgeColor: AppColors.secondary,
            badgeTextColor: AppColors.foreground,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: AppRadius.r(AppRadius.md),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.pets_rounded, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    "Bear's Den questions are personalised to strengthen weaker chapters.",
                    style: AppTextStyles.small,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.name,
    required this.stars,
    required this.badge,
    required this.badgeColor,
    required this.badgeTextColor,
  });

  final String name;
  final int stars;
  final String badge;
  final Color badgeColor;
  final Color badgeTextColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTextStyles.bodyBold)),
          Row(
            children: List.generate(
              3,
              (index) => Icon(
                index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.star,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: AppRadius.r(AppRadius.sm),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
