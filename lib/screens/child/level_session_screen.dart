import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/question.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class LevelSessionScreen extends ConsumerStatefulWidget {
  const LevelSessionScreen({
    super.key,
    this.childId,
    this.levelPrefix = 'bm_c1_l1_',
    this.subjectId = 'bm',
    this.levelId = 'l1',
  });

  final String? childId;
  final String levelPrefix;
  final String subjectId;
  final String levelId;

  @override
  ConsumerState<LevelSessionScreen> createState() => _LevelSessionScreenState();
}

class _LevelSessionScreenState extends ConsumerState<LevelSessionScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;

  int? selected;
  List<Question>? shuffledQuestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionTimer();
    });
  }

  @override
  void dispose() {
    _stopSessionTimer();
    super.dispose();
  }

  void _startSessionTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _completeSession() async {
    _stopSessionTimer();

    try {
      if (widget.childId != null) {
        await FirebaseFirestore.instance
            .collection('children')
            .doc(widget.childId)
            .collection('attempts')
            .add({
              'levelId': 'example_level', // Hardcoded for mockup
              'score': 100, // Hardcoded for mockup
              'stars': 3, // Hardcoded for mockup
              'elapsedTimeSeconds': _elapsedSeconds,
              'completedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      debugPrint('Error saving attempt: $e');
    }

    if (mounted) {
      context.go(AppRouter.completionFor(widget.childId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(questionsProvider(widget.levelPrefix));

    return Scaffold(
      body: SafeArea(
        child: questionsAsync.when(
          data: (rawQuestions) {
            if (rawQuestions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No questions found for this level.'),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: 'Go Back',
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              );
            }

            // Shuffle and pick 10 questions once per session
            if (shuffledQuestions == null) {
              final List<Question> temp = List.from(rawQuestions)..shuffle();
              shuffledQuestions = temp.take(10).toList();
            }

            final questions = shuffledQuestions!;
            final question = questions[currentQuestionIndex];
            final isLastQuestion = currentQuestionIndex == questions.length - 1;
            final progress = (currentQuestionIndex + 1) / questions.length;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.mutedText,
                        ),
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
                        '${currentQuestionIndex + 1}/${questions.length}',
                        style: AppTextStyles.bodyBold,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    question.text,
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (question.imageUrl != null &&
                      question.imageUrl!.isNotEmpty)
                    Container(
                      height: 104,
                      width: 104,
                      decoration: BoxDecoration(
                        color: AppColors.imagePlaceholder,
                        borderRadius: AppRadius.r(AppRadius.xl),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.r(AppRadius.xl),
                        child: Image.network(
                          question.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image,
                                color: AppColors.mutedText,
                                size: 48,
                              ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  ...List.generate(
                    question.options.length,
                    (index) => _option(index, question),
                  ),
                  const Spacer(),
                  if (selected != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: selected == question.correctAnswerIndex
                            ? AppColors.accentLight
                            : AppColors.destructiveLight,
                        borderRadius: AppRadius.r(AppRadius.lg),
                      ),
                      child: Text(
                        selected == question.correctAnswerIndex
                            ? 'Correct! Well done!'
                            : 'Not quite! The answer is "${question.options[question.correctAnswerIndex]}".',
                        style: AppTextStyles.bodyBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: isLastQuestion ? 'Finish' : 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        if (isLastQuestion) {
                          final params = {
                            'childId': widget.childId ?? '',
                            'score': score.toString(),
                            'total': questions.length.toString(),
                            'levelId': widget.levelId,
                            'subjectId': widget.subjectId,
                          };
                          context.go(
                            Uri(
                              path: AppRouter.completion,
                              queryParameters: params,
                            ).toString(),
                          );
                        } else {
                          setState(() {
                            currentQuestionIndex++;
                            selected = null;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _option(int index, Question question) {
    final picked = selected == index;
    final isCorrect = index == question.correctAnswerIndex;
    final showCorrect = selected != null && isCorrect;
    final showWrong = picked && !isCorrect;

    final color = showCorrect
        ? AppColors.accentLight
        : showWrong
        ? AppColors.destructiveLight
        : AppColors.card;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: selected == null
            ? () {
                setState(() {
                  selected = index;
                  if (index == question.correctAnswerIndex) {
                    score++;
                  }
                });
              }
            : null,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(
              color: showCorrect
                  ? AppColors.accent
                  : showWrong
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
                  question.options[index],
                  style: AppTextStyles.bodyBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
