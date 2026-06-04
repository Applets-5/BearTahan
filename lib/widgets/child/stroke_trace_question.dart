import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

import '../../models/question.dart';
import '../../theme/app_theme.dart';

class StrokeTraceQuestion extends StatefulWidget {
  const StrokeTraceQuestion({
    super.key,
    required this.question,
    required this.onComplete,
    required this.onWrongAttempt,
  });

  final Question question;
  final ValueChanged<bool> onComplete;
  final VoidCallback onWrongAttempt;

  @override
  State<StrokeTraceQuestion> createState() => _StrokeTraceQuestionState();
}

class _StrokeTraceQuestionState extends State<StrokeTraceQuestion>
    with TickerProviderStateMixin {
  static const int maxAttempts = 3;
  static const Duration _resetDelay = Duration(milliseconds: 650);

  StrokeOrderAnimationController? _controller;
  Future<void>? _loadFuture;
  int _attemptsUsed = 0;
  bool _inputLocked = false;
  bool _completed = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadController();
  }

  @override
  void didUpdateWidget(covariant StrokeTraceQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _controller?.dispose();
      _controller = null;
      _attemptsUsed = 0;
      _inputLocked = false;
      _completed = false;
      _feedback = null;
      _loadFuture = _loadController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadController() async {
    final strokeJson = await _loadStrokeJson();
    final controller = StrokeOrderAnimationController(
      StrokeOrder(strokeJson),
      this,
      showStroke: false,
      showOutline: true,
      showBackground: false,
      showMedian: false,
      showUserStroke: true,
      strokeColor: AppColors.primary,
      outlineColor: AppColors.primary.withValues(alpha: 0.35),
      brushColor: AppColors.accent,
      hintColor: AppColors.star,
      brushWidth: 16,
      hintAfterStrokes: 1,
      onWrongStrokeCallback: _handleWrongStroke,
      onQuizCompleteCallback: (_) => _handleQuizComplete(),
    );

    _controller = controller;
    controller.startQuiz();
  }

  Future<String> _loadStrokeJson() async {
    final inlineJson = widget.question.strokeOrderDataJson;
    if (inlineJson != null && inlineJson.isNotEmpty) {
      return inlineJson;
    }

    final character = widget.question.characterUnicode;
    if (character == null || character.isEmpty) {
      throw const FormatException('Missing characterUnicode for tracing');
    }

    return rootBundle.loadString('assets/hanzi/$character.json');
  }

  void _handleWrongStroke(int strokeIndex) {
    if (_inputLocked || _completed) return;

    _inputLocked = true;
    _attemptsUsed++;
    widget.onWrongAttempt();

    if (_attemptsUsed >= maxAttempts) {
      _controller?.stopQuiz();
      _controller?.showFullCharacter();
      setState(() {
        _completed = true;
        _feedback = 'Watch the correct stroke order, then try again later.';
      });
      widget.onComplete(false);
      return;
    }

    _controller?.stopQuiz();
    setState(() {
      _feedback =
          'Not quite. Start again from stroke 1. ${maxAttempts - _attemptsUsed} attempts left.';
    });

    Future.delayed(_resetDelay, () {
      if (!mounted || _completed) return;
      _controller?.reset();
      _controller?.startQuiz();
      setState(() {
        _inputLocked = false;
      });
    });
  }

  void _handleQuizComplete() {
    if (_inputLocked || _completed) return;

    setState(() {
      _completed = true;
      _feedback = 'Correct stroke order!';
    });
    widget.onComplete(true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || _controller == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.destructiveLight,
              borderRadius: AppRadius.r(AppRadius.lg),
            ),
            child: const Text(
              'Tracing data unavailable for this character.',
              style: AppTextStyles.bodyBold,
              textAlign: TextAlign.center,
            ),
          );
        }

        final controller = _controller!;
        final remainingAttempts = maxAttempts - _attemptsUsed;

        return Column(
          children: [
            Text(
              'Trace ${widget.question.characterUnicode ?? widget.question.text} in the correct stroke order',
              style: AppTextStyles.small,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_rounded, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  _completed
                      ? 'Complete'
                      : 'Stroke ${controller.currentStroke + 1}/${controller.strokeOrder.nStrokes}',
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.replay_rounded, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$remainingAttempts attempts left',
                  style: AppTextStyles.bodyBold,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.r(AppRadius.xl),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.card,
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: IgnorePointer(
                  ignoring: _inputLocked || _completed,
                  child: StrokeOrderAnimator(
                    controller,
                    key: ValueKey('stroke_animator_${widget.question.id}'),
                  ),
                ),
              ),
            ),
            if (_feedback != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _feedback!,
                style: AppTextStyles.bodyBold.copyWith(
                  color: _completed && remainingAttempts > 0
                      ? AppColors.accent
                      : AppColors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}
