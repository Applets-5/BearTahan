import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/outfit_quest.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/star_utils.dart';
import '../../utils/data_contracts.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/child/completion_mascot_stage.dart';

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({
    super.key,
    this.childId,
    this.score = 0,
    this.total = 0,
    this.levelId = 'l1',
    this.subjectId = 'bm',
    this.performanceStars,
    this.newStarsAwarded = 0,
    this.dailyBonusStars = 0,
    this.levelPrefix,
    this.isEscalated = false,
    this.isDailyBonus = false,
    this.unlockedOutfits = const [],
  });

  final String? childId;
  final int score;
  final int total;
  final String levelId;
  final String subjectId;
  final int? performanceStars;
  final int newStarsAwarded;
  final int dailyBonusStars;
  final String? levelPrefix;
  final bool isEscalated;
  final bool isDailyBonus;
  final List<String> unlockedOutfits;

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  bool _unlockDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUnlockDialogIfNeeded();
    });
  }

  Future<void> _showUnlockDialogIfNeeded() async {
    if (_unlockDialogShown || widget.unlockedOutfits.isEmpty || !mounted) {
      return;
    }
    _unlockDialogShown = true;

    final unlockedQuests = widget.unlockedOutfits
        .map(OutfitQuest.byId)
        .toList();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.r(AppRadius.xl),
          ),
          title: const Text('New outfit unlocked!'),
          content: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final quest in unlockedQuests) ...[
                  MascotWidget(size: 96, outfitId: quest.id),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    quest.name,
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    quest.description,
                    style: AppTextStyles.small,
                    textAlign: TextAlign.center,
                  ),
                  if (quest != unlockedQuests.last)
                    const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(
                  AppRouter.withChildId(AppRouter.quests, widget.childId),
                );
              },
              child: const Text('View outfits'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final performanceStars =
        widget.performanceStars ??
        StarUtils.calculateStars(
          score: widget.score,
          total: widget.total,
          levelId: widget.levelId,
        );
    final passed = performanceStars > 0;
    final totalAwarded = widget.newStarsAwarded + widget.dailyBonusStars;
    final replayPrefix =
        widget.levelPrefix ??
        DataContracts.levelPrefix(widget.subjectId, widget.levelId);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CompletionMascotStage(
                childId: widget.childId,
                passed: passed,
                stars: performanceStars,
              ),
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
                  widget.isDailyBonus ? 4 : 3,
                  (index) => Icon(
                    Icons.star,
                    size: 40,
                    color: index < (widget.isDailyBonus ? 4 : performanceStars)
                        ? AppColors.star
                        : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.isEscalated)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.r(AppRadius.lg),
                    ),
                    child: Text(
                      'Goal Increased! Next time try for more!',
                      style: AppTextStyles.whiteBodyBold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: passed ? AppColors.secondaryLight : AppColors.muted,
                  borderRadius: AppRadius.r(AppRadius.lg),
                ),
                child: Text(
                  passed
                      ? totalAwarded > 0
                            ? '+$totalAwarded stars added to your wallet!'
                            : 'Stage complete. No new wallet stars this time.'
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
                      levelPrefix: replayPrefix,
                      subjectId: widget.subjectId,
                      levelId: widget.levelId,
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
                      levelPrefix: replayPrefix,
                      subjectId: widget.subjectId,
                      levelId: widget.levelId,
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
