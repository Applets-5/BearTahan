import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({
    super.key,
    this.childId,
    this.subjectId,
    this.chapterId,
  });

  final String? childId;
  final String? subjectId;
  final String? chapterId;

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  @override
  Widget build(BuildContext context) {
    final effectiveChildId = widget.childId ?? '';
    final effectiveSubjectId = widget.subjectId ?? 'bm';
    final effectiveChapterId = widget.chapterId ?? 'c1';
    final levelId = '${effectiveChapterId}_summary';

    final starsAsync = ref.watch(
      levelStarsProvider((
        childId: effectiveChildId,
        subjectId: effectiveSubjectId,
      )),
    );
    final progressAsync = ref.watch(
      levelProgressProvider((
        childId: effectiveChildId,
        subjectId: effectiveSubjectId,
        levelId: levelId,
      )),
    );

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
          child: starsAsync.when(
            data: (starMap) {
              return progressAsync.when(
                data: (data) {
                  final threshold = (data['summaryThreshold'] ?? 0) as int;

                  String goalText = "Goal: 80% to earn a star";
                  if (threshold == 1) {
                    goalText = "Goal: 90% to earn a star";
                  }
                  if (threshold == 2) {
                    goalText = "Goal: 100% to earn a star";
                  }
                  if (threshold >= 3) {
                    goalText = "Goal: 100% for a Daily Bonus!";
                  }

                  return Column(
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
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 64,
                              color: AppColors.star,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Ready for the boss challenge?',
                              style: AppTextStyles.cardTitle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            const Text(
                              'Answer mixed questions from this chapter and earn a summary badge.',
                              style: AppTextStyles.small,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.r(AppRadius.lg),
                              ),
                              child: Text(
                                goalText,
                                style: AppTextStyles.whiteBodyBold,
                              ),
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
                      const _TopicRow(
                        icon: Icons.spellcheck,
                        label: 'Word spelling',
                      ),
                      const _TopicRow(
                        icon: Icons.check_circle,
                        label: 'Multiple choice recall',
                      ),
                      const Spacer(),
                      PrimaryButton(
                        label: 'Start Summary',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => context.push(
                          AppRouter.levelSessionFor(
                            widget.childId,
                            levelPrefix:
                                '${effectiveSubjectId}_${effectiveChapterId}_',
                            subjectId: effectiveSubjectId,
                            levelId: levelId,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Error loading chapter progress: $err')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
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
