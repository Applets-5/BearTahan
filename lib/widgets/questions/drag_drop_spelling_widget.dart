import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../theme/app_theme.dart';

class DragDropSpellingWidget extends StatefulWidget {
  final Question question;
  final Function(bool isCorrect) onCompleted;
  final VoidCallback? onWrongAttempt;

  const DragDropSpellingWidget({
    super.key,
    required this.question,
    required this.onCompleted,
    this.onWrongAttempt,
  });

  @override
  State<DragDropSpellingWidget> createState() => _DragDropSpellingWidgetState();
}

class _DragDropSpellingWidgetState extends State<DragDropSpellingWidget> {
  late List<String> _promptParts;
  late List<int> _blankIndices;
  late List<QuestionOption?> _filledOptions;
  late List<QuestionOption> _availableOptions;
  bool _isSubmitted = false;
  bool _isWrong = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    // Parse prompt: e.g., "d _ _ m _ n _" or "d__m_n_"
    final prompt = widget.question.text;

    if (prompt.contains(' ')) {
      _promptParts = prompt.split(' ').where((s) => s.isNotEmpty).toList();
    } else {
      _promptParts = prompt.split('');
    }

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
  }

  void _checkAnswer() {
    if (_filledOptions.contains(null)) return;

    // The user example had comma-separated string in prompt, but model has List<String>?
    // Let's handle both or check how it's actually parsed.
    // In lib/models/question.dart:
    // List<String>? correctOrder;
    // if (data['correctOrder'] is List) {
    //   correctOrder = (data['correctOrder'] as List).map((e) => e.toString()).toList();
    // }

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
      // If no correctOrder provided, we might be in trouble, but let's assume it's there.
      isCorrect = false;
    }

    setState(() {
      _isSubmitted = true;
      if (!isCorrect) {
        _isWrong = true;
        widget.onWrongAttempt?.call();
        // Shake effect or similar could be added here
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _isWrong = false;
              _isSubmitted = false;
              // Return all to tray? Or let them swap?
              // Requirements: "If wrong, shake the incorrect slots and let the student retry."
            });
          }
        });
      }
    });

    if (isCorrect) {
      widget.onCompleted(true);
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
    final showImage = widget.question.imageUrl != null;

    return Column(
      children: [
        if (showImage) ...[
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: AppRadius.r(AppRadius.lg),
              image: DecorationImage(
                image: NetworkImage(widget.question.imageUrl!),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Prompt Row
        Wrap(
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

        const SizedBox(height: AppSpacing.xxl),

        // Options Tray
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
