import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/star_utils.dart';
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
    this.stars,
  });

  final String? childId;
  final int score;
  final int total;
  final String levelId;
  final String subjectId;
  final int? stars;

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  @override
  Widget build(BuildContext context) {
    final earnedStars =
        widget.stars ??
        StarUtils.calculateStars(
          score: widget.score,
          total: widget.total,
          levelId: widget.levelId,
        );
    final passed = earnedStars > 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActiveMascotWidget(childId: widget.childId, size: 100),
              const SizedBox(height: AppSpacing.lg),
              Icon(
                passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                size: 56,
                color: passed ? AppColors.star : AppColors.mutedText,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                passed ? 'Stage Clear!' : 'Try Again!',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              Text(
                'You got ${widget.score} out of ${widget.total} correct!',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Icon(
                    Icons.star,
                    size: 40,
                    color: index < earnedStars
                        ? AppColors.star
                        : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: passed ? AppColors.secondaryLight : AppColors.muted,
                  borderRadius: AppRadius.r(AppRadius.lg),
                ),
                child: Text(
                  passed
                      ? '+$earnedStars stars added to your wallet!'
                      : 'You need at least 50% to earn a star. Don\'t give up!',
                  style: AppTextStyles.bodyBold,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (passed)
                PrimaryButton(
                  label: 'Continue',
                  onPressed: () => context.go(
                    AppRouter.subjectFor(
                      widget.childId,
                      subjectId: widget.subjectId,
                    ),
                  ),
                )
              else
                PrimaryButton(
                  label: 'Try Again',
                  onPressed: () => context.go(
                    AppRouter.levelSessionFor(
                      widget.childId,
                      levelPrefix: '${widget.subjectId}_c1_${widget.levelId}_',
                    ),
                  ),
                ),
              if (passed) ...[
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Replay',
                  backgroundColor: AppColors.muted,
                  foregroundColor: AppColors.mutedText,
                  onPressed: () => context.go(
                    AppRouter.levelSessionFor(
                      widget.childId,
                      levelPrefix: '${widget.subjectId}_c1_${widget.levelId}_',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
