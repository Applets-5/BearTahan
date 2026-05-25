import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/question.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/star_utils.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionTimer();
    });
  }

  void _playFeedback(bool isCorrect) async {
    if (isCorrect) {
      await _audioPlayer.play(AssetSource('audio/correctAns.mp3'));
    } else {
      await _audioPlayer.play(AssetSource('audio/wrongAns.mp3'));
    }
  }

  @override
  void dispose() {
    _stopSessionTimer();
    _audioPlayer.dispose();
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

  Future<void> _completeSession(int totalQuestions) async {
    _stopSessionTimer();

    // Calculate stars based on score
    final stars = StarUtils.calculateStars(
      score: score,
      total: totalQuestions,
      levelId: widget.levelId,
    );

    // Play appropriate audio
    final String audioPath = stars > 0
        ? 'audio/levelPassed.mp3'
        : 'audio/levelFailed.mp3';
    final playFuture = _audioPlayer
        .play(AssetSource(audioPath))
        .then((_) => _audioPlayer.onPlayerComplete.first);

    try {
      final parentId = ref.read(parentIdProvider);
      if (widget.childId != null && parentId.isNotEmpty) {
        await ref
            .read(firestoreServiceProvider)
            .updateLevelProgress(
              parentId,
              widget.childId!,
              widget.subjectId,
              widget.levelId,
              stars,
            );
      }
    } catch (e) {
      debugPrint('Error saving attempt: $e');
    }

    // Wait for the audio to finish before navigating
    await playFuture;

    if (mounted) {
      final params = {
        'childId': widget.childId ?? '',
        'score': score.toString(),
        'total': totalQuestions.toString(),
        'levelId': widget.levelId,
        'subjectId': widget.subjectId,
        'stars': stars.toString(),
      };
      context.go(
        Uri(path: AppRouter.completion, queryParameters: params).toString(),
      );
    }
  }

  Future<void> _handleExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          AppRouter.subjectFor(widget.childId, subjectId: widget.subjectId),
        );
      }
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
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(
                            AppRouter.subjectFor(
                              widget.childId,
                              subjectId: widget.subjectId,
                            ),
                          );
                        }
                      },
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
                        onPressed: _handleExit,
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
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.timer, color: AppColors.mutedText),
                      Text(_formatElapsedTime(), style: AppTextStyles.bodyBold),
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
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
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
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PrimaryButton(
                      label: isLastQuestion ? 'Finish' : 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        if (isLastQuestion) {
                          _completeSession(questions.length);
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
                final isCorrect = index == question.correctAnswerIndex;
                if (isCorrect) {
                  HapticFeedback.mediumImpact();
                  _playFeedback(true);
                } else {
                  HapticFeedback.vibrate();
                  _playFeedback(false);
                }
                setState(() {
                  selected = index;
                  if (isCorrect) {
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
