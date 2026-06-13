import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/outfit_quest.dart';
import '../../providers/sound_effects_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/audio_contexts.dart';
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
    this.bestStars,
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
  final int? bestStars;
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
  final AudioPlayer _resultAudioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_playResultAudio());
      _showUnlockDialogIfNeeded();
    });
  }

  int get _performanceStars {
    return widget.performanceStars ??
        StarUtils.calculateStars(
          score: widget.score,
          total: widget.total,
          levelId: widget.levelId,
        );
  }

  Future<void> _playResultAudio() async {
    try {
      final soundEnabled = await ref.read(soundEffectsProvider.future);
      if (!mounted || !soundEnabled) return;

      await _resultAudioPlayer.setAudioContext(soundEffectAudioContext());
      await _resultAudioPlayer.play(
        AssetSource(
          levelResultAudioPath(
            isReviewSession: widget.levelId == 'review_session',
            performanceStars: _performanceStars,
          ),
        ),
        volume: levelResultVolume,
      );
    } catch (error) {
      debugPrint('Unable to play level result sound: $error');
    }
  }

  @override
  void dispose() {
    unawaited(_resultAudioPlayer.dispose());
    super.dispose();
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

  String _getFeedbackMessage({
    required bool isReview,
    required bool passed,
    required int totalAwarded,
    required bool isSummaryOrRevision,
    required int performanceStars,
    required int bestStars,
    required bool isEscalated,
  }) {
    if (isReview) {
      return 'Each question you reviewed helps you earn stars and master subjects!';
    }

    if (isSummaryOrRevision) {
      if (bestStars == 3 && !isEscalated) {
        return "Well done for doing revision! You've already mastered this stage!";
      }

      if (isEscalated) {
        if (bestStars == 1) {
          return "Yey, you got your 1st star! Get 90% next time for the 2nd star!";
        }
        if (bestStars == 2) {
          return "Hooray, you got your 2nd star! Get 100% next time for the 3rd star!";
        }
        if (bestStars == 3) {
          return "Fantastic! You've mastered this stage with 3 stars!";
        }
      } else {
        // Didn't reach a NEW star or was a reattempt
        if (bestStars == 0) {
          return "Keep going, superstar! Get 80% to win your first shiny star. Keep practicing!";
        }
        if (bestStars == 1) {
          return "Nice job! Get 90% to collect another star. Keep practicing!";
        }
        if (bestStars == 2) {
          return "Almost a star champion! Score 100% to collect all 3 stars. Keep practicing!";
        }
        if (bestStars == 3) {
          return "Fantastic! You've already mastered this stage with 3 stars!";
        }
      }
    }

    // Fallback for regular stages or if logic above didn't return
    if (passed) {
      return totalAwarded > 0
          ? '+$totalAwarded stars added to your wallet!'
          : 'Stage complete. No new wallet stars this time.';
    } else {
      return 'You need at least 50% to earn a star. Don\'t give up!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final performanceStars = _performanceStars;
    final bestStars = widget.bestStars ?? performanceStars;
    final passed = performanceStars > 0;
    final totalAwarded = widget.newStarsAwarded + widget.dailyBonusStars;
    final isReview = widget.levelId == 'review_session';
    final isSummaryOrRevision =
        widget.levelId.toLowerCase().contains('summary') ||
        widget.levelId.toLowerCase().contains('revision');
    final replayPrefix =
        widget.levelPrefix ??
        DataContracts.levelPrefix(widget.subjectId, widget.levelId);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Top Left Home Button
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: IconButton(
                onPressed: () =>
                    context.go(AppRouter.childHomeFor(widget.childId)),
                icon: const Icon(
                  Icons.home_rounded,
                  color: AppColors.mutedText,
                  size: 28,
                ),
                tooltip: 'Go to Home',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CompletionMascotStage(
                    childId: widget.childId,
                    passed: passed,
                    stars: performanceStars,
                    isReview: isReview,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Icon(
                    isReview || passed
                        ? Icons.emoji_events_rounded
                        : Icons.refresh_rounded,
                    size: 56,
                    color: isReview || passed
                        ? AppColors.star
                        : AppColors.mutedText,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isReview
                        ? 'Review Complete!'
                        : (isSummaryOrRevision &&
                              bestStars == 3 &&
                              !widget.isEscalated)
                        ? 'Mastery Revision!'
                        : passed
                        ? 'Stage Clear!'
                        : 'Try Again!',
                    style: AppTextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'You got ${widget.score} out of ${widget.total} correct!',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!isReview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.isDailyBonus ? 4 : 3,
                        (index) => Icon(
                          Icons.star,
                          size: 40,
                          color:
                              index <
                                  (widget.isDailyBonus ? 4 : performanceStars)
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
                      color: isReview || passed
                          ? AppColors.secondaryLight
                          : AppColors.muted,
                      borderRadius: AppRadius.r(AppRadius.lg),
                    ),
                    child: Text(
                      _getFeedbackMessage(
                        isReview: isReview,
                        passed: passed,
                        totalAwarded: totalAwarded,
                        isSummaryOrRevision: isSummaryOrRevision,
                        performanceStars: performanceStars,
                        bestStars: bestStars,
                        isEscalated: widget.isEscalated,
                      ),
                      style: AppTextStyles.bodyBold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (isReview || passed)
                    PrimaryButton(
                      label: 'Continue',
                      onPressed: () => context.go(
                        isReview
                            ? AppRouter.childHomeFor(widget.childId)
                            : AppRouter.subjectFor(
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
                  if (!isReview && passed) ...[
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
          ],
        ),
      ),
    );
  }
}
