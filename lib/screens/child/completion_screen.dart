import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/primary_button.dart';

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({
    super.key,
    this.childId,
    this.score = 0,
    this.total = 0,
    this.levelId = 'l1',
    this.subjectId = 'bm',
  });

  final String? childId;
  final int score;
  final int total;
  final String levelId;
  final String subjectId;

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  bool _saved = false;

  int _calculateStars() {
    if (widget.total == 0) return 0;
    final percentage = widget.score / widget.total;
    if (percentage == 1.0) return 3;
    if (percentage >= 0.8) return 2;
    if (percentage >= 0.5) return 1;
    return 0;
  }

  Future<void> _saveProgress() async {
    if (_saved) return;
    final stars = _calculateStars();
    final uid = ref.read(userIdProvider);
    
    try {
      await ref.read(firestoreServiceProvider).updateLevelProgress(
        uid, 
        widget.subjectId, 
        widget.levelId, 
        stars
      );
      setState(() => _saved = true);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _saveProgress();
  }

  @override
  Widget build(BuildContext context) {
    final stars = _calculateStars();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActiveMascotWidget(childId: widget.childId, size: 100),
              const SizedBox(height: AppSpacing.lg),
              const Icon(
                Icons.emoji_events_rounded,
                size: 56,
                color: AppColors.star,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Stage Clear!',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              Text('You got ${widget.score} out of ${widget.total} correct!',
                  style: AppTextStyles.small),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    Icons.star,
                    size: 40,
                    color: index < stars ? AppColors.star : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: AppRadius.r(AppRadius.lg),
                ),
                child: Text(
                  stars > 0
                      ? '+$stars stars added to your wallet!'
                      : 'Keep practicing to earn stars!',
                  style: AppTextStyles.bodyBold,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Continue',
                onPressed: () => context.go(AppRouter.subjectFor(widget.childId)),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Try Again',
                backgroundColor: AppColors.muted,
                foregroundColor: AppColors.mutedText,
                onPressed: () => context.go(AppRouter.levelSessionFor(widget.childId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
