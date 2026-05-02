import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class ChapterScreen extends StatelessWidget {
  const ChapterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Chapter Summary'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: AppRadius.r(AppRadius.xl),
                  boxShadow: AppShadows.card,
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: AppColors.star,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Ready for the boss challenge?',
                      style: AppTextStyles.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Answer mixed questions from this chapter and earn a summary badge.',
                      style: AppTextStyles.small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'What you will practise',
                style: AppTextStyles.bodyBold,
              ),
              const SizedBox(height: AppSpacing.md),
              const _TopicRow(
                icon: Icons.volume_up,
                label: 'Listening and pronunciation',
              ),
              const _TopicRow(icon: Icons.spellcheck, label: 'Word spelling'),
              const _TopicRow(
                icon: Icons.check_circle,
                label: 'Multiple choice recall',
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Start Summary',
                icon: Icons.play_arrow_rounded,
                onPressed: () => context.push(AppRouter.levelSession),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
