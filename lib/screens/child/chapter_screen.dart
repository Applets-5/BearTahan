import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/level.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

class ChapterScreen extends StatelessWidget {
  final String chapterId;
  final String chapterTitle;

  const ChapterScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
  });

  static const _levels = [
    Level(
      id: 'l1',
      chapterId: 'BM_C1',
      levelId: 'STD1',
      title: 'Level 1 — Huruf Vokal',
      isLocked: false,
      totalQuestions: 5,
    ),
    Level(
      id: 'l2',
      chapterId: 'BM_C1',
      levelId: 'STD1',
      title: 'Level 2 — Suku Kata',
      isLocked: true,
      totalQuestions: 5,
    ),
    Level(
      id: 'l3',
      chapterId: 'BM_C1',
      levelId: 'STD1',
      title: 'Level 3 — Ejaan & Ayat',
      isLocked: true,
      totalQuestions: 5,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(chapterTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: AppRadius.r(AppRadius.xl),
                  boxShadow: AppShadows.card,
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Bab 1 — Huruf & Suku Kata',
                      style: AppTextStyles.cardTitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complete each level to unlock the next one.',
                      style: AppTextStyles.small,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Levels', style: AppTextStyles.bodyBold),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: _levels.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _LevelTile(level: _levels[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final Level level;

  const _LevelTile({required this.level});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: level.isLocked
          ? null
          : () => context.push(
                AppRouter.levelSession,
                extra: {
                  'levelId': level.levelId,
                  'chapterId': level.chapterId,
                  'levelTitle': level.title,
                },
              ),
      borderRadius: AppRadius.r(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: level.isLocked ? AppColors.muted : AppColors.card,
          borderRadius: AppRadius.r(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: level.isLocked ? null : AppShadows.card,
        ),
        child: Row(
          children: [
            // Level icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: level.isLocked
                    ? AppColors.mutedText
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                level.isLocked ? Icons.lock_rounded : Icons.star_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + question count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: level.isLocked
                        ? AppTextStyles.body.copyWith(
                            color: AppColors.mutedText,
                          )
                        : AppTextStyles.bodyBold,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${level.totalQuestions} questions',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ),
            // Arrow or lock
            Icon(
              level.isLocked
                  ? Icons.lock_outline_rounded
                  : Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}