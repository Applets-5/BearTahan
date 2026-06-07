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
    this.onCorrectStroke,
  });

  final Question question;
  final ValueChanged<bool> onComplete;
  final VoidCallback onWrongAttempt;
  final ValueChanged<int>? onCorrectStroke;

  @override
  StrokeTraceQuestionState createState() => StrokeTraceQuestionState();
}

class StrokeTraceQuestionState extends State<StrokeTraceQuestion>
    with TickerProviderStateMixin {
  static const int maxAttempts = 3;
  static const Duration _resetDelay = Duration(milliseconds: 650);
  static const Color _activeStrokeColor = Color(0xBF22B8CF);
  static const Color _acceptedStrokeColor = Color(0xFF087F8C);
  static const Color _outlineColor = Color(0xFFCBDDE2);

  StrokeOrderAnimationController? _controller;
  late final AnimationController _feedbackController;
  late final Animation<double> _shakeAnimation;
  Future<void>? _loadFuture;
  int _attemptsUsed = 0;
  bool _isFeedbackPlaying = false;
  bool _completed = false;
  bool _wasSuccessful = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
        );
    _loadFuture = _loadController();
  }

  @override
  void didUpdateWidget(covariant StrokeTraceQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _controller?.dispose();
      _controller = null;
      _attemptsUsed = 0;
      _isFeedbackPlaying = false;
      _completed = false;
      _wasSuccessful = false;
      _feedback = null;
      _feedbackController.reset();
      _loadFuture = _loadController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadController() async {
    final strokeJson = await _loadStrokeJson();
    final controller = StrokeOrderAnimationController(
      StrokeOrder(strokeJson),
      this,
      showStroke: true,
      showOutline: true,
      showBackground: false,
      showMedian: false,
      showUserStroke: false,
      strokeColor: _acceptedStrokeColor,
      outlineColor: _outlineColor,
      brushColor: _activeStrokeColor,
      hintColor: _acceptedStrokeColor,
      brushWidth: 24,
      hintAfterStrokes: 1,
      onWrongStrokeCallback: _handleWrongStroke,
      onCorrectStrokeCallback: _handleCorrectStroke,
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
    if (_isFeedbackPlaying || _completed) return;

    _isFeedbackPlaying = true;
    _attemptsUsed++;
    widget.onWrongAttempt();
    HapticFeedback.mediumImpact();
    _feedbackController.forward(from: 0);

    if (_attemptsUsed >= maxAttempts) {
      _controller?.stopQuiz();
      _controller?.showFullCharacter();
      setState(() {
        _completed = true;
        _wasSuccessful = false;
        _feedback = 'The correct character is shown. Try again later.';
      });
      widget.onComplete(false);
      return;
    }

    _controller?.stopQuiz();
    setState(() {
      _feedback = 'Try again from stroke 1!';
    });

    Future.delayed(_resetDelay, () {
      if (!mounted || _completed) return;
      _controller?.reset();
      _controller?.startQuiz();
      setState(() {
        _isFeedbackPlaying = false;
      });
    });
  }

  @visibleForTesting
  void simulateWrongStroke() {
    _handleWrongStroke(_controller?.currentStroke ?? 0);
  }

  void _handleCorrectStroke(int strokeIndex) {
    widget.onCorrectStroke?.call(strokeIndex);
  }

  @visibleForTesting
  void simulateCorrectStroke(int strokeIndex) {
    _handleCorrectStroke(strokeIndex);
  }

  @visibleForTesting
  static bool usesStrokeMarkers(int strokeCount) => strokeCount <= 6;

  void _handleQuizComplete() {
    if (_isFeedbackPlaying || _completed) return;

    setState(() {
      _completed = true;
      _wasSuccessful = true;
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
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: [
                _buildProgressGroup(
                  label: 'Strokes',
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _buildStrokeProgress(controller),
                  ),
                ),
                _buildProgressGroup(
                  label: 'Attempts',
                  child: _buildAttemptProgress(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedBuilder(
              animation: _feedbackController,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              ),
              child: AnimatedContainer(
                key: const ValueKey('stroke_canvas_feedback'),
                duration: const Duration(milliseconds: 120),
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _isFeedbackPlaying
                      ? AppColors.destructiveLight
                      : AppColors.card,
                  borderRadius: AppRadius.r(AppRadius.xl),
                  border: Border.all(
                    color: _isFeedbackPlaying
                        ? AppColors.destructive
                        : AppColors.border,
                    width: _isFeedbackPlaying ? 2 : 1,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = constraints.biggest.shortestSide;
                      return IgnorePointer(
                        key: const ValueKey('stroke_input_blocker'),
                        ignoring: _isFeedbackPlaying || _completed,
                        child: StrokeOrderAnimator(
                          controller,
                          size: Size.square(canvasSize),
                          key: ValueKey(
                            'stroke_animator_${widget.question.id}',
                          ),
                        ),
                      );
                    },
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

  Widget _buildProgressGroup({required String label, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          key: ValueKey('progress_label_${label.toLowerCase()}'),
          style: AppTextStyles.tiny,
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

  Widget _buildStrokeProgress(StrokeOrderAnimationController controller) {
    final strokeCount = controller.strokeOrder.nStrokes;
    final completedStrokes = controller.currentStroke.clamp(0, strokeCount);

    if (!usesStrokeMarkers(strokeCount)) {
      final displayedStroke = _completed
          ? strokeCount
          : (completedStrokes + 1).clamp(1, strokeCount);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_rounded, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Stroke $displayedStroke of $strokeCount',
            key: const ValueKey('stroke_progress_text'),
            style: AppTextStyles.bodyBold,
          ),
        ],
      );
    }

    return Semantics(
      label: '$completedStrokes of $strokeCount strokes complete',
      child: Row(
        key: const ValueKey('stroke_progress_markers'),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(strokeCount, (index) {
          final complete = index < completedStrokes;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: complete ? _acceptedStrokeColor : AppColors.muted,
                shape: BoxShape.circle,
                border: Border.all(
                  color: complete ? _acceptedStrokeColor : AppColors.border,
                ),
              ),
              child: Icon(
                complete ? Icons.check_rounded : Icons.edit_rounded,
                size: 15,
                color: complete ? Colors.white : AppColors.mutedText,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAttemptProgress() {
    return Semantics(
      label: '${maxAttempts - _attemptsUsed} attempts remaining',
      child: Row(
        key: const ValueKey('attempt_progress_markers'),
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxAttempts, (index) {
          final failed = index < _attemptsUsed;
          final successful =
              _wasSuccessful &&
              index == _attemptsUsed.clamp(0, maxAttempts - 1);
          final current =
              !_completed && !failed && index == _attemptsUsed.clamp(0, 2);

          final color = failed
              ? AppColors.destructive
              : successful
              ? AppColors.accent
              : current
              ? _activeStrokeColor
              : AppColors.border;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: AnimatedContainer(
              key: ValueKey('attempt_marker_$index'),
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: failed || successful ? color : AppColors.card,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: current ? 2 : 1),
              ),
              child: Icon(
                failed
                    ? Icons.close_rounded
                    : successful
                    ? Icons.check_rounded
                    : Icons.circle,
                size: failed || successful ? 15 : 8,
                color: failed || successful
                    ? Colors.white
                    : current
                    ? _activeStrokeColor
                    : AppColors.border,
              ),
            ),
          );
        }),
      ),
    );
  }
}
