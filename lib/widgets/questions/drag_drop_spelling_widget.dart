import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../theme/app_theme.dart';

class DragDropSpellingWidget extends StatefulWidget {
  final Question question;
  final Function(bool isCorrect) onCompleted;
  final VoidCallback? onCorrectAttempt;
  final VoidCallback? onWrongAttempt;

  const DragDropSpellingWidget({
    super.key,
    required this.question,
    required this.onCompleted,
    this.onCorrectAttempt,
    this.onWrongAttempt,
  });

  @override
  State<DragDropSpellingWidget> createState() => _DragDropSpellingWidgetState();
}

class _DragDropSpellingWidgetState extends State<DragDropSpellingWidget>
    with SingleTickerProviderStateMixin {
  static const int maxAttempts = 3;
  late List<String> _promptParts;
  late List<int> _blankIndices;
  late List<QuestionOption?> _filledOptions;
  late List<QuestionOption> _availableOptions;
  bool _isSubmitted = false;
  bool _isWrong = false;
  int _attemptsUsed = 0;

  late final AnimationController _feedbackController;
  late final Animation<double> _shakeAnimation;

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
    _initGame();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _initGame() {
    // Parse prompt: e.g., "_ot__ook"
    // We want every single letter and underscore to be its own block.
    // Replace all spaces to ensure clean splitting of actual content.
    final prompt = widget.question.text.replaceAll(' ', '');
    _promptParts = prompt.split('');

    _blankIndices = [];
    for (int i = 0; i < _promptParts.length; i++) {
      if (_promptParts[i] == '_') {
        _blankIndices.add(i);
      }
    }

    _filledOptions = List.filled(_blankIndices.length, null);
    _availableOptions = List.from(widget.question.options)..shuffle();
    _isSubmitted = false;
    _isWrong = false;
    _attemptsUsed = 0;
  }

  void _checkAnswer() {
    if (_filledOptions.contains(null)) return;

    final filledOrder = _filledOptions.map((e) => e?.text ?? '').toList();

    bool isCorrect = true;
    if (widget.question.correctOrder != null) {
      if (filledOrder.length != widget.question.correctOrder!.length) {
        isCorrect = false;
      } else {
        for (int i = 0; i < filledOrder.length; i++) {
          if (filledOrder[i].toLowerCase() !=
              widget.question.correctOrder![i].toLowerCase()) {
            isCorrect = false;
            break;
          }
        }
      }
    } else {
      isCorrect = false;
    }

    if (isCorrect) {
      widget.onCorrectAttempt?.call();
      setState(() {
        _isSubmitted = true;
      });
      widget.onCompleted(true);
    } else {
      _attemptsUsed++;
      widget.onWrongAttempt?.call();
      _feedbackController.forward(from: 0);

      if (_attemptsUsed >= maxAttempts) {
        setState(() {
          _isSubmitted = true;
          _isWrong = true;
        });
        widget.onCompleted(false);
        return;
      }

      setState(() {
        _isSubmitted = true;
        _isWrong = true;
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _isWrong = false;
            _isSubmitted = false;
            // Return all to tray for retry
            for (var opt in _filledOptions) {
              if (opt != null) _availableOptions.add(opt);
            }
            _filledOptions = List.filled(_blankIndices.length, null);
          });
        }
      });
    }
  }

  void _onDrop(int blankIndex, QuestionOption option) {
    if (_isSubmitted) return;

    setState(() {
      // If slot already has an option, return it to tray
      if (_filledOptions[blankIndex] != null) {
        _availableOptions.add(_filledOptions[blankIndex]!);
      }

      _filledOptions[blankIndex] = option;
      _availableOptions.remove(option);
    });

    if (!_filledOptions.contains(null)) {
      _checkAnswer();
    }
  }

  void _onTapFilled(int blankIndex) {
    if (_isSubmitted) return;

    final option = _filledOptions[blankIndex];
    if (option != null) {
      setState(() {
        _availableOptions.add(option);
        _filledOptions[blankIndex] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAttemptProgress(),
        const SizedBox(height: AppSpacing.md),
        // Prompt Row
        AnimatedBuilder(
          animation: _feedbackController,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.sm,
            children: List.generate(_promptParts.length, (i) {
              final part = _promptParts[i];
              if (part != '_') {
                return _buildStaticLetter(part);
              } else {
                final blankIdx = _blankIndices.indexOf(i);
                return _buildDropSlot(blankIdx);
              }
            }),
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),

        // Options Tray
        if (!_isSubmitted || !_isWrong) ...[
          const Text(
            'Drag letters to fill the blanks!',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: _availableOptions.map((option) {
              return Draggable<QuestionOption>(
                data: option,
                feedback: _buildLetterTile(option.text, isDragging: true),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _buildLetterTile(option.text),
                ),
                child: _buildLetterTile(option.text),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildAttemptProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Attempts', style: AppTextStyles.tiny),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxAttempts, (index) {
            final failed = index < _attemptsUsed;
            final current =
                !_isSubmitted &&
                !failed &&
                index == _attemptsUsed.clamp(0, maxAttempts - 1);
            final successful =
                _isSubmitted && !_isWrong && index == _attemptsUsed;

            final color = failed
                ? AppColors.destructive
                : successful
                ? AppColors.accent
                : current
                ? AppColors.primary
                : AppColors.border;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
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
                  size: failed || successful ? 12 : 6,
                  color: failed || successful
                      ? Colors.white
                      : current
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStaticLetter(String letter) {
    return Container(
      width: 40,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.r(AppRadius.sm),
      ),
      child: Text(
        letter,
        style: AppTextStyles.title.copyWith(
          color: AppColors.foreground.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildDropSlot(int blankIndex) {
    final filledOption = _filledOptions[blankIndex];

    return DragTarget<QuestionOption>(
      onWillAcceptWithDetails: (details) => !_isSubmitted,
      onAcceptWithDetails: (details) => _onDrop(blankIndex, details.data),
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _onTapFilled(blankIndex),
          child: Container(
            width: 40,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isWrong ? AppColors.destructiveLight : AppColors.card,
              borderRadius: AppRadius.r(AppRadius.sm),
              border: Border.all(
                color: _isWrong
                    ? AppColors.destructive
                    : (candidateData.isNotEmpty
                          ? AppColors.primary
                          : AppColors.border),
                width: 2,
              ),
              boxShadow: AppShadows.card,
            ),
            child: filledOption != null
                ? Text(filledOption.text, style: AppTextStyles.title)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildLetterTile(String letter, {bool isDragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 45,
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.r(AppRadius.md),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: isDragging ? AppShadows.strong : AppShadows.card,
        ),
        child: letter.isNotEmpty
            ? Text(
                letter,
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
              )
            : null,
      ),
    );
  }
}
