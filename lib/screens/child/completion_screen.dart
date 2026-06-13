import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/outfit_quest.dart';
import '../../models/bears_den_result.dart';
import '../../models/session_mode.dart';
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
    this.sessionMode = SessionMode.standard,
    this.bearsDenAwardStatus = BearsDenAwardStatus.notEarned,
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
  final SessionMode sessionMode;
  final BearsDenAwardStatus bearsDenAwardStatus;

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
    final isBearsDen = widget.sessionMode == SessionMode.bearsDen;

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
                    successMessage: isBearsDen
                        ? 'You tackled all 3 chapters!'
                        : null,
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
                    isBearsDen
                        ? "Bear's Den Complete!"
                        : isReview
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
                    Column(
                      children: [
                        if (isBearsDen) ...[
                          Text(
                            "Today's reward",
                            style: AppTextStyles.small.copyWith(
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            isBearsDen
                                ? 2
                                : widget.isDailyBonus
                                ? 4
                                : 3,
                            (index) => Icon(
                              Icons.star,
                              size: 40,
                              color:
                                  index <
                                      (widget.isDailyBonus && !isBearsDen
                                          ? 4
                                          : performanceStars)
                                  ? AppColors.star
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
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
                  if (isBearsDen)
                    _BearsDenWalletPanel(
                      status: widget.bearsDenAwardStatus,
                      awardedStars: widget.newStarsAwarded,
                    )
                  else
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

class _BearsDenWalletPanel extends StatelessWidget {
  const _BearsDenWalletPanel({
    required this.status,
    required this.awardedStars,
  });

  final BearsDenAwardStatus status;
  final int awardedStars;

  @override
  Widget build(BuildContext context) {
    final isFailure = status == BearsDenAwardStatus.saveFailed;
    final (icon, message) = switch (status) {
      BearsDenAwardStatus.awarded => (
        Icons.star_rounded,
        '+$awardedStars ${awardedStars == 1 ? 'star' : 'stars'} added to your wallet!',
      ),
      BearsDenAwardStatus.dailyCap => (
        Icons.schedule_rounded,
        "You already earned today's stars. Come back tomorrow!",
      ),
      BearsDenAwardStatus.saveFailed => (
        Icons.warning_amber_rounded,
        "Wallet stars couldn't be saved right now.",
      ),
      BearsDenAwardStatus.notEarned => (
        Icons.auto_awesome_rounded,
        'Score at least 70% to earn a star.',
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isFailure ? const Color(0xFFF5F5F5) : const Color(0xFFFFF8E1),
          borderRadius: AppRadius.r(AppRadius.md),
          border: Border(
            left: BorderSide(
              color: isFailure
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFF59E0B),
              width: 4,
            ),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isFailure
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFFF59E0B),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyBold.copyWith(
                  color: isFailure
                      ? const Color(0xFF737373)
                      : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
