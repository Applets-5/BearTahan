import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../theme/app_theme.dart';

class MatchingWidget extends StatefulWidget {
  final Question question;
  final Function(bool isCorrect) onCompleted;

  const MatchingWidget({
    super.key,
    required this.question,
    required this.onCompleted,
  });

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> {
  late List<QuestionOption> _leftOptions;
  late List<QuestionOption> _rightOptions;
  QuestionOption? _selectedLeft;
  QuestionOption? _selectedRight;
  final Set<QuestionOption> _matchedOptions = {};
  bool _isWrongFlash = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _leftOptions = List.from(widget.question.options)..shuffle();
    _rightOptions = List.from(widget.question.options)..shuffle();
    _selectedLeft = null;
    _selectedRight = null;
    _matchedOptions.clear();
    _isWrongFlash = false;
  }

  void _handleLeftTap(QuestionOption option) {
    if (_matchedOptions.contains(option) || _isWrongFlash) return;

    setState(() {
      if (_selectedLeft == option) {
        _selectedLeft = null;
      } else {
        _selectedLeft = option;
        _checkMatch();
      }
    });
  }

  void _handleRightTap(QuestionOption option) {
    if (_matchedOptions.contains(option) || _isWrongFlash) return;

    setState(() {
      if (_selectedRight == option) {
        _selectedRight = null;
      } else {
        _selectedRight = option;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (_selectedLeft != null && _selectedRight != null) {
      if (_selectedLeft == _selectedRight) {
        // Success
        setState(() {
          _matchedOptions.add(_selectedLeft!);
          _selectedLeft = null;
          _selectedRight = null;
        });

        if (_matchedOptions.length == widget.question.options.length) {
          widget.onCompleted(true);
        }
      } else {
        // Wrong
        setState(() {
          _isWrongFlash = true;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isWrongFlash = false;
              _selectedLeft = null;
              _selectedRight = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.question.text.isNotEmpty) ...[
          Text(widget.question.text, style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSpacing.lg),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Texts
            Expanded(
              child: Column(
                children: _leftOptions.map((option) {
                  return _buildMatchCard(
                    text: option.text,
                    isSelected: _selectedLeft == option,
                    isMatched: _matchedOptions.contains(option),
                    isWrong: _isWrongFlash && _selectedLeft == option,
                    onTap: () => _handleLeftTap(option),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Right Column: Images
            Expanded(
              child: Column(
                children: _rightOptions.map((option) {
                  return _buildMatchCard(
                    imageUrl: option.imageUrl,
                    isSelected: _selectedRight == option,
                    isMatched: _matchedOptions.contains(option),
                    isWrong: _isWrongFlash && _selectedRight == option,
                    onTap: () => _handleRightTap(option),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchCard({
    String? text,
    String? imageUrl,
    required bool isSelected,
    required bool isMatched,
    required bool isWrong,
    required VoidCallback onTap,
  }) {
    final Color borderColor = isMatched
        ? AppColors.accent
        : isWrong
        ? AppColors.destructive
        : isSelected
        ? AppColors.primary
        : AppColors.border;

    final Color bgColor = isMatched
        ? AppColors.accentLight
        : isWrong
        ? AppColors.destructiveLight
        : isSelected
        ? AppColors.primaryLight
        : AppColors.card;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.sm),
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.r(AppRadius.md),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isSelected ? AppShadows.strong : AppShadows.card,
        ),
        child: Stack(
          children: [
            Center(
              child: (text != null && text.isNotEmpty)
                  ? Text(
                      text,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isMatched ? AppColors.accent : null,
                      ),
                    )
                  : imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const SizedBox.shrink(),
            ),
            if (isMatched)
              const Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
