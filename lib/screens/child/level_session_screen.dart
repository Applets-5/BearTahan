import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/question.dart';
import '../../repositories/question_repository.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class LevelSessionScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String chapterId;
  final String levelTitle;

  const LevelSessionScreen({
    super.key,
    required this.levelId,
    required this.chapterId,
    required this.levelTitle,
  });

  @override
  ConsumerState<LevelSessionScreen> createState() => _LevelSessionScreenState();
}

class _LevelSessionScreenState extends ConsumerState<LevelSessionScreen> {
  int? selected;
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(
      questionsByChapterProvider((
        levelId: widget.levelId,
        chapterId: widget.chapterId,
      )),
    );

    return questionsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading questions: $e')),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('No questions found.')),
          );
        }

        final question = questions[currentIndex];
        final progress = (currentIndex + 1) / questions.length;
        final correctIndex = question.options
            .indexWhere((o) => o.id == question.correctAnswerId);

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: AppColors.mutedText),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: AppSpacing.md,
                          color: AppColors.subjectBm,
                          backgroundColor: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Icon(Icons.star, color: AppColors.star),
                      Text(
                        '${currentIndex + 1}/${questions.length}',
                        style: AppTextStyles.bodyBold,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    question.prompt,
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...List.generate(
                    question.options.length,
                    (index) => _option(index, question, correctIndex),
                  ),
                  const Spacer(),
                  if (selected != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: selected == correctIndex
                            ? AppColors.accentLight
                            : AppColors.destructiveLight,
                        borderRadius: AppRadius.r(AppRadius.lg),
                      ),
                      child: Text(
                        selected == correctIndex
                            ? 'Correct! Well done!'
                            : 'Not quite! The answer is "${question.options[correctIndex].text}".',
                        style: AppTextStyles.bodyBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: currentIndex < questions.length - 1
                          ? 'Next'
                          : 'Finish',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        if (currentIndex < questions.length - 1) {
                          setState(() {
                            currentIndex++;
                            selected = null;
                          });
                        } else {
                          context.go(AppRouter.completion);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _option(int index, Question question, int correctIndex) {
    final picked = selected == index;
    final correct = selected != null && index == correctIndex;
    final color = correct
        ? AppColors.accentLight
        : picked
        ? AppColors.destructiveLight
        : AppColors.card;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: selected == null ? () => setState(() => selected = index) : null,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(
              color: correct
                  ? AppColors.accent
                  : picked
                  ? AppColors.destructive
                  : AppColors.border,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.muted,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(question.options[index].text, style: AppTextStyles.bodyBold),
            ],
          ),
        ),
      ),
    );
  }
}