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
                  // Progress bar
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

                  // Prompt image (promptImage mode only) 
                  if (question.imageMode == QuestionImageMode.promptImage &&
                      question.imageUrl != null) ...[
                    _QuestionImage(imageUrl: question.imageUrl!),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Question text 
                  Text(
                    question.prompt,
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Answer options 
                  // answerImage: 2x2 image grid
                  // none / promptImage: vertical text list
                  if (question.imageMode == QuestionImageMode.answerImage)
                    _ImageOptionGrid(
                      question: question,
                      selected: selected,
                      correctIndex: correctIndex,
                      onSelect: (i) => setState(() => selected = i),
                    )
                  else
                    ...List.generate(
                      question.options.length,
                      (i) => _TextOption(
                        index: i,
                        question: question,
                        selected: selected,
                        correctIndex: correctIndex,
                        onSelect: (i) => setState(() => selected = i),
                      ),
                    ),

                  const Spacer(),

                  // Feedback + Next button
                  if (selected != null) ...[
                    _FeedbackBanner(
                      isCorrect: selected == correctIndex,
                      correctText: question.options[correctIndex].text,
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
}

// Prompt image

class _QuestionImage extends StatelessWidget {
  final String imageUrl;
  const _QuestionImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.r(AppRadius.xl),
      child: Image.network(
        imageUrl,
        height: 180,
        width: 180,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: AppRadius.r(AppRadius.xl),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                color: AppColors.subjectBm,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 180,
          width: 180,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: AppRadius.r(AppRadius.xl),
          ),
          child: const Icon(Icons.broken_image,
              color: AppColors.mutedText, size: 48),
        ),
      ),
    );
  }
}

// Text answer option (none / promptImage mode)

class _TextOption extends StatelessWidget {
  final int index;
  final Question question;
  final int? selected;
  final int correctIndex;
  final ValueChanged<int> onSelect;

  const _TextOption({
    required this.index,
    required this.question,
    required this.selected,
    required this.correctIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final picked = selected == index;
    final correct = selected != null && index == correctIndex;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: selected == null ? () => onSelect(index) : null,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: correct
                ? AppColors.accentLight
                : picked
                ? AppColors.destructiveLight
                : AppColors.card,
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
              Expanded(
                child: Text(
                  question.options[index].text,
                  style: AppTextStyles.bodyBold,
                ),
              ),
              // Show tick or cross after answered
              if (selected != null)
                Icon(
                  correct ? Icons.check_circle : picked ? Icons.cancel : null,
                  color: correct ? AppColors.accent : AppColors.destructive,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Image answer grid (answerImage mode)

class _ImageOptionGrid extends StatelessWidget {
  final Question question;
  final int? selected;
  final int correctIndex;
  final ValueChanged<int> onSelect;

  const _ImageOptionGrid({
    required this.question,
    required this.selected,
    required this.correctIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final opt = question.options[index];
        final picked = selected == index;
        final correct = selected != null && index == correctIndex;

        return InkWell(
          onTap: selected == null ? () => onSelect(index) : null,
          borderRadius: AppRadius.r(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              color: correct
                  ? AppColors.accentLight
                  : picked
                  ? AppColors.destructiveLight
                  : AppColors.card,
              borderRadius: AppRadius.r(AppRadius.lg),
              border: Border.all(
                width: correct || picked ? 2 : 1,
                color: correct
                    ? AppColors.accent
                    : picked
                    ? AppColors.destructive
                    : AppColors.border,
              ),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                // Image fills top 3/4 of the card
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    child: opt.imageUrl != null
                        ? Image.network(
                            opt.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: AppColors.mutedText,
                            ),
                          )
                        : const Icon(Icons.image, color: AppColors.mutedText),
                  ),
                ),
                // Label + letter badge at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.muted,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: AppTextStyles.small,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          opt.text,
                          style: AppTextStyles.small,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected != null)
                        Icon(
                          correct
                              ? Icons.check_circle
                              : picked
                              ? Icons.cancel
                              : null,
                          size: 16,
                          color: correct
                              ? AppColors.accent
                              : AppColors.destructive,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Feedback banner

class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String correctText;

  const _FeedbackBanner({
    required this.isCorrect,
    required this.correctText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.accentLight : AppColors.destructiveLight,
        borderRadius: AppRadius.r(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: isCorrect ? AppColors.accent : AppColors.destructive,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isCorrect
                  ? 'Correct! Well done!'
                  : 'Not quite! The answer is "$correctText".',
              style: AppTextStyles.bodyBold,
            ),
          ),
        ],
      ),
    );
  }
}