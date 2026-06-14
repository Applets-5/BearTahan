import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/question.dart';
import '../../models/bears_den_result.dart';
import '../../models/session_mode.dart';
import '../../features/bears_den/bears_den_demo_data.dart';
import '../../providers/data_providers.dart';
import '../../providers/sound_effects_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/audio_contexts.dart';
import '../../utils/question_session_selector.dart';
import '../../utils/sound_effects.dart';
import '../../utils/star_utils.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/audio_prompt_player.dart';
import '../../widgets/questions/drag_drop_spelling_widget.dart';
import '../../widgets/questions/matching_widget.dart';
import '../../widgets/child/stroke_trace_question.dart';
import '../../widgets/common/mascot_widget.dart';

class LevelSessionScreen extends ConsumerStatefulWidget {
  const LevelSessionScreen({
    super.key,
    this.childId,
    this.levelPrefix = 'bm_c1_l1_',
    this.subjectId = 'bm',
    this.levelId = 'l1',
    this.showFeedbackMascot = true,
    this.reviewQuestions,
    this.sessionMode = SessionMode.standard,
  });

  final String? childId;
  final String levelPrefix;
  final String subjectId;
  final String levelId;
  final bool showFeedbackMascot;
  final List<Question>? reviewQuestions;
  final SessionMode sessionMode;

  @override
  ConsumerState<LevelSessionScreen> createState() => _LevelSessionScreenState();
}

class _LevelSessionScreenState extends ConsumerState<LevelSessionScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  Timer? _sessionTimer;
  Timer? _loadingQuoteTimer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;
  bool _isSaving = false;
  bool _assetsPrepared = false;
  int _preparedAssetCount = 0;
  int _totalAssetCount = 0;
  int _loadingQuoteIndex = 0;

  int? selected;
  final TextEditingController _numberController = TextEditingController();
  bool _numberSubmitted = false;
  List<Question>? shuffledQuestions;
  List<Question>? _lastRawQuestions;
  final Set<String> _reviewQuestionIds = {};
  AudioPool? _correctAnswerPool;
  AudioPool? _wrongAnswerPool;
  AudioPool? _correctStrokePool;
  AudioPool? _wrongStrokePool;
  StopFunction? _stopCorrectAnswer;
  StopFunction? _stopWrongAnswer;
  StopFunction? _stopCorrectStroke;
  StopFunction? _stopWrongStroke;

  @override
  void initState() {
    super.initState();
    _startLoadingQuotes();
    unawaited(_initializeSoundEffectAudio());
  }

  static const _loadingQuotes = [
    'Hunting for the best questions...',
    'Packing a basket of brainy challenges...',
    'Building a den full of bright ideas...',
    'Putting every question in paw-fect order...',
  ];

  void _startLoadingQuotes() {
    _loadingQuoteTimer?.cancel();
    _loadingQuoteTimer = Timer.periodic(const Duration(milliseconds: 1800), (
      _,
    ) {
      if (!mounted || _assetsPrepared) return;
      setState(() {
        _loadingQuoteIndex = (_loadingQuoteIndex + 1) % _loadingQuotes.length;
      });
    });
  }

  bool get _soundEffectsEnabled {
    return ref.read(soundEffectsProvider).value ?? true;
  }

  Future<void> _initializeSoundEffectAudio() async {
    try {
      final context = soundEffectAudioContext();
      final pools = await Future.wait([
        AudioPool.create(
          source: AssetSource('audio/correctAns.mp3'),
          minPlayers: 1,
          maxPlayers: 1,
          playerMode: PlayerMode.lowLatency,
          audioContext: context,
        ),
        AudioPool.create(
          source: AssetSource('audio/wrongAns.mp3'),
          minPlayers: 1,
          maxPlayers: 1,
          playerMode: PlayerMode.lowLatency,
          audioContext: context,
        ),
        AudioPool.create(
          source: AssetSource('audio/stroke_correct.wav'),
          minPlayers: 1,
          maxPlayers: 1,
          playerMode: PlayerMode.lowLatency,
          audioContext: context,
        ),
        AudioPool.create(
          source: AssetSource('audio/stroke_wrong.wav'),
          minPlayers: 1,
          maxPlayers: 1,
          playerMode: PlayerMode.lowLatency,
          audioContext: context,
        ),
      ]);

      if (!mounted) {
        await Future.wait(pools.map((pool) => pool.dispose()));
        return;
      }

      _correctAnswerPool = pools[0];
      _wrongAnswerPool = pools[1];
      _correctStrokePool = pools[2];
      _wrongStrokePool = pools[3];
    } catch (error) {
      debugPrint('Unable to initialize sound effects: $error');
    }
  }

  Future<void> _playSound(Future<void> Function() play) async {
    if (!_soundEffectsEnabled) return;
    try {
      await play();
    } catch (error) {
      debugPrint('Unable to play sound effect: $error');
    }
  }

  Future<void> _playQuestionFeedback(
    Question question,
    bool isCorrect, {
    bool allowStrokeTrace = false,
  }) {
    if (!shouldPlayQuestionFeedback(
      question.type,
      allowStrokeTrace: allowStrokeTrace,
    )) {
      return Future.value();
    }

    return _playSound(() {
      return _playAnswerFeedback(isCorrect);
    });
  }

  Future<void> _playAnswerFeedback(bool isCorrect) async {
    final pool = isCorrect ? _correctAnswerPool : _wrongAnswerPool;
    if (pool == null) return;

    if (isCorrect) {
      await _stopCorrectAnswer?.call();
      _stopCorrectAnswer = await pool.start(volume: answerFeedbackVolume);
    } else {
      await _stopWrongAnswer?.call();
      _stopWrongAnswer = await pool.start(volume: answerFeedbackVolume);
    }
  }

  Future<void> _playTracingCompletionFeedback(
    Question question,
    bool isCorrect,
  ) async {
    await Future<void>.delayed(Duration(milliseconds: isCorrect ? 120 : 160));
    if (!mounted) return;
    await _playQuestionFeedback(question, isCorrect, allowStrokeTrace: true);
  }

  Future<void> _playStrokeCorrect(int strokeIndex) {
    return _playSound(() async {
      final pool = _correctStrokePool;
      if (pool == null) return;
      await _stopCorrectStroke?.call();
      _stopCorrectStroke = await pool.start(volume: 1.0);
    });
  }

  Future<void> _playStrokeWrong() {
    return _playSound(() async {
      final pool = _wrongStrokePool;
      if (pool == null) return;
      await _stopWrongStroke?.call();
      _stopWrongStroke = await pool.start(volume: 1.0);
    });
  }

  Future<void> _recordQuestionResult(Question question, bool isCorrect) async {
    if (widget.sessionMode == SessionMode.bearsDen) return;
    final parentId = ref.read(parentIdProvider);
    final childId = widget.childId;
    if (parentId.isEmpty || childId == null || childId.isEmpty) return;

    final firestore = ref.read(firestoreServiceProvider);
    try {
      await firestore.updateQuestionStats(
        parentId,
        childId,
        question.id,
        isCorrect,
      );

      if (_reviewQuestionIds.contains(question.id)) {
        await firestore.recordReviewQuestionAnswered(
          parentId,
          childId,
          question.id,
        );
      } else if (!isCorrect) {
        await firestore.flagWrongAnswer(
          parentId,
          childId,
          questionId: question.id,
          subjectId: _subjectIdForQuestion(question),
          levelId: widget.levelId,
          questionText: question.text,
        );
      }
    } catch (error) {
      debugPrint('Unable to record question result: $error');
    }
  }

  Future<void> _disposeSoundEffectAudio() async {
    await _stopCorrectAnswer?.call();
    await _stopWrongAnswer?.call();
    await _stopCorrectStroke?.call();
    await _stopWrongStroke?.call();
    await _correctAnswerPool?.dispose();
    await _wrongAnswerPool?.dispose();
    await _correctStrokePool?.dispose();
    await _wrongStrokePool?.dispose();
  }

  @override
  void dispose() {
    _stopSessionTimer();
    _loadingQuoteTimer?.cancel();
    unawaited(_disposeSoundEffectAudio());
    _numberController.dispose();
    for (final c in _fillBlankListControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startSessionTimer() {
    if (_timerStarted) return;
    _timerStarted = true;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _completeSession(int totalQuestions) async {
    if (_isSaving) return;
    _stopSessionTimer();
    setState(() => _isSaving = true);

    int performanceStars = 0;
    int bestStars = 0;
    int newStarsAwarded = 0;
    int dailyBonusStars = 0;
    bool isEscalated = false;
    bool isDailyBonus = false;
    final newlyUnlockedOutfits = <String>[];

    final isReviewSession = _isDedicatedReviewSession;
    BearsDenAwardStatus? bearsDenAwardStatus;

    try {
      final parentId = ref.read(parentIdProvider);
      if (widget.sessionMode == SessionMode.bearsDen) {
        performanceStars = score == totalQuestions
            ? 2
            : score / totalQuestions >= 0.7
            ? 1
            : 0;
        bestStars = performanceStars;

        if (widget.childId != null && parentId.isNotEmpty) {
          try {
            final result = await ref
                .read(firestoreServiceProvider)
                .completeBearsDenSession(
                  parentId,
                  widget.childId!,
                  score: score,
                  total: totalQuestions,
                );
            performanceStars = result.performanceStars;
            bestStars = performanceStars;
            newStarsAwarded = result.awardedStars;
            bearsDenAwardStatus = result.status;
          } catch (error) {
            debugPrint('Unable to save Bear\'s Den stars: $error');
            bearsDenAwardStatus = BearsDenAwardStatus.saveFailed;
          }
        } else {
          bearsDenAwardStatus = BearsDenAwardStatus.saveFailed;
        }
      } else if (!isReviewSession &&
          widget.childId != null &&
          parentId.isNotEmpty) {
        final firestore = ref.read(firestoreServiceProvider);

        final progressResult = await firestore.updateLevelProgress(
          parentId,
          widget.childId!,
          widget.subjectId,
          widget.levelId,
          score,
          totalQuestions,
        );
        performanceStars = progressResult.performanceStars;
        bestStars = progressResult.bestStars;
        newStarsAwarded = progressResult.newStarsAwarded;
        dailyBonusStars = progressResult.dailyBonusStars;
        isEscalated = progressResult.didEscalate;
        isDailyBonus = progressResult.dailyBonusStars > 0;

        try {
          await firestore.recordAttempt(
            parentId,
            widget.childId!,
            subjectId: widget.subjectId,
            levelId: widget.levelId,
            score: score,
            total: totalQuestions,
            stars: performanceStars,
            timeInSeconds: _elapsedSeconds,
          );
        } catch (error) {
          debugPrint('Progress saved but attempt logging failed: $error');
        }

        try {
          newlyUnlockedOutfits.addAll(
            await firestore.evaluateAndUpdateQuestProgress(
              parentId,
              widget.childId!,
            ),
          );
        } catch (error) {
          debugPrint('Progress saved but quest evaluation failed: $error');
        }
      } else if (!isReviewSession) {
        performanceStars = StarUtils.calculateStars(
          score: score,
          total: totalQuestions,
          levelId: widget.levelId,
        );
        bestStars = performanceStars;
      }
    } catch (e) {
      debugPrint('Unable to save level progress: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Progress could not be saved. Check your connection and try again.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final params = {
        'childId': widget.childId ?? '',
        'score': score.toString(),
        'total': totalQuestions.toString(),
        'levelId': widget.levelId,
        'subjectId': widget.subjectId,
        'performanceStars': performanceStars.toString(),
        'bestStars': bestStars.toString(),
        'newStarsAwarded': newStarsAwarded.toString(),
        'dailyBonusStars': dailyBonusStars.toString(),
        'levelPrefix': widget.levelPrefix,
        'isEscalated': isEscalated.toString(),
        'isDailyBonus': isDailyBonus.toString(),
        'sessionMode': widget.sessionMode.name,
        if (bearsDenAwardStatus != null)
          'bearsDenAwardStatus': bearsDenAwardStatus.name,
        if (newlyUnlockedOutfits.isNotEmpty)
          'unlockedOutfits': newlyUnlockedOutfits.join(','),
      };
      context.go(
        Uri(path: AppRouter.completion, queryParameters: params).toString(),
      );
    }
  }

  Future<void> _handleExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text(
          'Are you sure you want to exit? Your progress will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(
          AppRouter.subjectFor(widget.childId, subjectId: widget.subjectId),
        );
      }
    }
  }

  Future<void>? _initializationFuture;

  bool get _isDedicatedReviewSession =>
      widget.reviewQuestions != null || widget.levelId == 'review_session';

  String _subjectIdForQuestion(Question question) {
    final prefix = question.id.split('_').first.toLowerCase();
    const knownSubjects = {'bm', 'bi', 'bc', 'math', 'sci'};
    return knownSubjects.contains(prefix) ? prefix : widget.subjectId;
  }

  String _languageForQuestion(Question question) {
    switch (_subjectIdForQuestion(question)) {
      case 'bm':
        return 'ms-MY';
      case 'bi':
        return 'en-GB';
      case 'bc':
        return 'zh-CN';
      default:
        return 'en-GB';
    }
  }

  void _resetPreparation() {
    shuffledQuestions = null;
    _assetsPrepared = false;
    _preparedAssetCount = 0;
    _totalAssetCount = 0;
    _loadingQuoteIndex = 0;
    _startLoadingQuotes();
  }

  Future<void> _prepareSelectedQuestions() async {
    final questions = shuffledQuestions;
    if (questions == null || questions.isEmpty) return;

    await ref
        .read(sessionAssetPreloaderProvider)
        .preload(
          context: context,
          questions: questions,
          languageForQuestion: _languageForQuestion,
          onProgress: (completed, total) {
            if (!mounted) return;
            setState(() {
              _preparedAssetCount = completed;
              _totalAssetCount = total;
            });
          },
        );

    if (!mounted) return;
    _loadingQuoteTimer?.cancel();
    _assetsPrepared = true;
    _startSessionTimer();
    setState(() {});
  }

  Future<void> _initializeQuestions(List<Question> rawQuestions) async {
    if (widget.reviewQuestions != null) {
      final questionsById = <String, Question>{
        for (final question in rawQuestions) question.id: question,
      };
      _reviewQuestionIds
        ..clear()
        ..addAll(questionsById.keys);
      shuffledQuestions = questionsById.values.toList()..shuffle();
      await _prepareSelectedQuestions();
      return;
    }

    if (widget.sessionMode == SessionMode.bearsDen) {
      final questions = List<Question>.from(rawQuestions)..shuffle();
      shuffledQuestions = questions;
      await _prepareSelectedQuestions();
      return;
    }
    final isSummary = widget.levelId.toLowerCase().contains('summary');
    final isRevision = widget.levelId.toLowerCase().contains('revision');
    final needsPrioritization = isSummary || isRevision;

    try {
      if (needsPrioritization) {
        final stats = await ref
            .read(firestoreServiceProvider)
            .getQuestionStatsForUser(
              ref.read(parentIdProvider),
              widget.childId ?? '',
              rawQuestions.map((q) => q.id).toList(),
            );
        shuffledQuestions = _prioritizeQuestions(
          rawQuestions,
          stats,
          15,
          isRevision,
        );
      } else {
        final reviewQuestions = await ref
            .read(firestoreServiceProvider)
            .getReviewQuestions(
              ref.read(parentIdProvider),
              widget.childId ?? '',
              subjectId: widget.subjectId,
              limit: 2,
            );
        final reviewById = <String, Question>{
          for (final question in reviewQuestions) question.id: question,
        };
        _reviewQuestionIds
          ..clear()
          ..addAll(reviewById.keys);

        final List<Question> pool = rawQuestions
            .where((question) => !reviewById.containsKey(question.id))
            .toList();
        final mainQuestionCount = (10 - reviewById.length).clamp(0, 10);
        final mainQuestions = _isMandarinChapterOneLevelFour
            ? selectBalancedMandarinL4Questions(pool, count: mainQuestionCount)
            : (pool..shuffle()).take(mainQuestionCount).toList();
        shuffledQuestions = [...mainQuestions, ...reviewById.values]..shuffle();
      }
    } catch (error) {
      debugPrint('Unable to prepare personalized questions: $error');
      _reviewQuestionIds.clear();
      if (_isMandarinChapterOneLevelFour && !needsPrioritization) {
        shuffledQuestions = selectBalancedMandarinL4Questions(
          rawQuestions,
          count: 10,
        );
      } else {
        final fallback = List<Question>.from(rawQuestions)..shuffle();
        shuffledQuestions = fallback
            .take(needsPrioritization ? 15 : 10)
            .toList();
      }
    }
    await _prepareSelectedQuestions();
  }

  bool get _isMandarinChapterOneLevelFour {
    final subject = widget.subjectId.toLowerCase();
    final level = widget.levelId.toLowerCase().replaceAll('-', '_');
    return subject == 'bc' &&
        (level == 'l4' || level == 'c1_l4' || level == 'bc_c1_l4');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(soundEffectsProvider);

    if (widget.reviewQuestions != null) {
      final rawQuestions = widget.reviewQuestions!;
      if (_lastRawQuestions != rawQuestions) {
        _lastRawQuestions = rawQuestions;
        _resetPreparation();
        _initializationFuture = Future<void>.microtask(
          () => _initializeQuestions(rawQuestions),
        );
      }
      return Scaffold(
        body: SafeArea(
          child: rawQuestions.isEmpty
              ? _buildNoQuestionsPlaceholder(context)
              : FutureBuilder<void>(
                  future: _initializationFuture,
                  builder: (context, snapshot) {
                    if (!_assetsPrepared || shuffledQuestions == null) {
                      return _buildPreparationScreen();
                    }
                    return _buildSession(shuffledQuestions!);
                  },
                ),
        ),
      );
    }

    if (widget.sessionMode == SessionMode.bearsDen) {
      final questionsAsync = ref.watch(bearsDenQuestionsProvider);
      ref.watch(parentSettingsProvider);
      return Scaffold(
        body: SafeArea(
          child: questionsAsync.when(
            data: (rawQuestions) {
              if (!BearsDenDemoData.isValidSession(rawQuestions)) {
                return _buildNoQuestionsPlaceholder(
                  context,
                  message:
                      "Bear's Den questions are still loading. Please try again.",
                );
              }
              if (_lastRawQuestions != rawQuestions) {
                _lastRawQuestions = rawQuestions;
                _resetPreparation();
                _initializationFuture = Future<void>.microtask(
                  () => _initializeQuestions(rawQuestions),
                );
              }
              if (!_assetsPrepared || shuffledQuestions == null) {
                return FutureBuilder<void>(
                  future: _initializationFuture,
                  builder: (context, snapshot) {
                    if (!_assetsPrepared || shuffledQuestions == null) {
                      return _buildPreparationScreen();
                    }
                    return _buildSession(shuffledQuestions!);
                  },
                );
              }
              return _buildSession(shuffledQuestions!);
            },
            loading: () => _buildPreparationScreen(animateMascot: false),
            error: (error, stack) => _buildNoQuestionsPlaceholder(
              context,
              message: "Bear's Den could not load. Check your connection.",
            ),
          ),
        ),
      );
    }

    // If it's a revision stage, we fetch ALL questions for the subject
    final isRevision = widget.levelId.toLowerCase().contains('revision');
    final queryPrefix = isRevision
        ? '${widget.subjectId}_'
        : widget.levelPrefix;
    final questionsAsync = ref.watch(questionsProvider(queryPrefix));
    ref.watch(parentSettingsProvider);

    return Scaffold(
      body: SafeArea(
        child: questionsAsync.when(
          data: (rawQuestions) {
            if (rawQuestions.isEmpty) {
              return _buildNoQuestionsPlaceholder(context);
            }

            // Check if raw questions changed to trigger re-initialization
            if (_lastRawQuestions != rawQuestions) {
              _lastRawQuestions = rawQuestions;
              _resetPreparation();
              _initializationFuture = Future<void>.microtask(
                () => _initializeQuestions(rawQuestions),
              );
            }

            if (!_assetsPrepared || shuffledQuestions == null) {
              return FutureBuilder<void>(
                future: _initializationFuture,
                builder: (context, snapshot) {
                  if (!_assetsPrepared || shuffledQuestions == null) {
                    return _buildPreparationScreen();
                  }
                  return _buildSession(shuffledQuestions!);
                },
              );
            }

            return _buildSession(shuffledQuestions!);
          },
          loading: () => _buildPreparationScreen(animateMascot: false),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  List<Question> _prioritizeQuestions(
    List<Question> pool,
    Map<String, Map<String, int>> stats,
    int count,
    bool isRevision,
  ) {
    // Priority Groups:
    // 1. New (timesSeen == 0)
    // 2. Wrong (timesWrong > 0)
    // 3. Correct (timesSeen > 0 && timesWrong == 0)

    final List<Question> selected = [];

    if (isRevision) {
      // For revision, we must ensure at least 1 question from each chapter if possible.
      // Group pool by chapterId (assuming IDs like 'bm_c1_l1_q01')
      final Map<String, List<Question>> chapterGroups = {};
      for (var q in pool) {
        final parts = q.id.split('_');
        final chapterKey = (parts.length >= 2) ? parts[1] : 'unknown';
        chapterGroups.putIfAbsent(chapterKey, () => []).add(q);
      }

      // Pick 1 random question from each chapter first
      for (var chapterKey in chapterGroups.keys) {
        if (selected.length >= count) break;
        final group = chapterGroups[chapterKey]!;
        group.shuffle();
        selected.add(group.removeAt(0));
      }
    }

    // Now fill the rest using normal prioritization
    final List<Question> remainingPool = pool
        .where((q) => !selected.contains(q))
        .toList();
    final List<Question> newQuestions = [];
    final List<Question> wrongQuestions = [];
    final List<Question> correctQuestions = [];

    for (var q in remainingPool) {
      final s = stats[q.id];
      if (s == null || (s['timesSeen'] ?? 0) == 0) {
        newQuestions.add(q);
      } else if ((s['timesWrong'] ?? 0) > 0) {
        wrongQuestions.add(q);
      } else {
        correctQuestions.add(q);
      }
    }

    newQuestions.shuffle();
    wrongQuestions.shuffle();
    correctQuestions.shuffle();

    selected.addAll(newQuestions);
    if (selected.length < count) selected.addAll(wrongQuestions);
    if (selected.length < count) selected.addAll(correctQuestions);

    return selected.take(count).toList();
  }

  Widget _buildNoQuestionsPlaceholder(
    BuildContext context, {
    String message =
        'No questions are ready for this level yet. Head back and explore another trail.',
  }) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showFeedbackMascot)
                ActiveMascotWidget(
                  childId: widget.childId,
                  size: 150,
                  showBackground: false,
                  mood: MascotMood.crying,
                  hideUntilLoaded: true,
                )
              else
                const MascotWidget(
                  size: 150,
                  showBackground: false,
                  mood: MascotMood.crying,
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'The question trail is quiet!',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.mutedText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 190,
                child: PrimaryButton(
                  label: 'Back to the Trail',
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(
                        AppRouter.subjectFor(
                          widget.childId,
                          subjectId: widget.subjectId,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreparationScreen({bool animateMascot = true}) {
    final hasProgress = _totalAssetCount > 0;
    final progress = hasProgress
        ? (_preparedAssetCount / _totalAssetCount).clamp(0.0, 1.0)
        : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WalkingMascotStage(
              mascotSize: 120,
              height: 155,
              isWalking: animateMascot,
              child: widget.showFeedbackMascot
                  ? ActiveMascotWidget(
                      childId: widget.childId,
                      size: 120,
                      showBackground: false,
                      mood: MascotMood.idle,
                      hideUntilLoaded: true,
                    )
                  : const MascotWidget(
                      size: 120,
                      showBackground: false,
                      mood: MascotMood.idle,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Preparing your adventure',
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _loadingQuotes[_loadingQuoteIndex],
                key: ValueKey(_loadingQuoteIndex),
                style: AppTextStyles.body.copyWith(color: AppColors.mutedText),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppSpacing.sm,
                borderRadius: AppRadius.r(AppRadius.sm),
                color: AppColors.primary,
                backgroundColor: AppColors.muted,
              ),
            ),
            if (hasProgress) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$_preparedAssetCount of $_totalAssetCount ready',
                style: AppTextStyles.small,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSession(List<Question> questions) {
    final question = questions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;
    final progress = (currentQuestionIndex + 1) / questions.length;
    final isQuestionComplete =
        selected != null || _isQuestionComplete(question);

    final language = _languageForQuestion(question);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _handleExit,
                icon: const Icon(Icons.close, color: AppColors.mutedText),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: AppSpacing.md,
                  color: AppColors.subjectBm,
                  backgroundColor: AppColors.muted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.star, color: AppColors.star),
              Text(
                '${currentQuestionIndex + 1}/${questions.length}',
                style: AppTextStyles.bodyBold,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.timer, color: AppColors.mutedText),
              Text(_formatElapsedTime(), style: AppTextStyles.bodyBold),
            ],
          ),
        ),
        if (widget.sessionMode == SessionMode.bearsDen) ...[
          const SizedBox(height: AppSpacing.sm),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _BearsDenChip(label: "Bear's Den"),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      key: const ValueKey('level_session_scroll'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - (AppSpacing.md * 2),
                        ),
                        child: Column(
                          key: const ValueKey('question_content'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (question.imageUrl != null &&
                                question.imageUrl!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: Center(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 160,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.imagePlaceholder,
                                      borderRadius: AppRadius.r(AppRadius.xl),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: AppRadius.r(AppRadius.xl),
                                      child: Image.network(
                                        question.imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.image,
                                                  color: AppColors.mutedText,
                                                  size: 48,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            _buildQuestionText(question, language),
                            if (widget.sessionMode == SessionMode.bearsDen) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _BearsDenChip(
                                label: BearsDenDemoData.chapterLabelForQuestion(
                                  question,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            _buildQuestionBody(question),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isQuestionComplete) ...[
                _buildAnswerActions(
                  question,
                  isLastQuestion: isLastQuestion,
                  totalQuestions: questions.length,
                ),
              ] else if (_shouldShowCheckButton(question)) ...[
                _buildCheckAnswerAction(question),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerActions(
    Question question, {
    required bool isLastQuestion,
    required int totalQuestions,
  }) {
    final bool isCorrect = selected == question.correctAnswerIndex;
    final Color feedbackBg = isCorrect
        ? AppColors.accentLight
        : AppColors.destructiveLight;
    final Color feedbackAccent = isCorrect
        ? AppColors.accent
        : AppColors.destructive;
    final String title = isCorrect ? 'Correct!' : 'Incorrect!';
    final String subtitle = _answerFeedbackText(question);
    final String buttonLabel = isLastQuestion
        ? 'Finish'
        : (isCorrect ? 'Continue' : 'Got it');

    return TweenAnimationBuilder<double>(
      key: const ValueKey('answer_actions'),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
            );
          },
          child: Container(
            key: const ValueKey('answer_feedback'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected == question.correctAnswerIndex
                  ? AppColors.accentLight
                  : AppColors.destructiveLight,
              borderRadius: AppRadius.r(AppRadius.lg),
            ),
            child: Row(
              children: [
                if (widget.showFeedbackMascot) ...[
                  SizedBox(
                    width: 72,
                    height: 54,
                    child: OverflowBox(
                      maxWidth: 120,
                      maxHeight: 120,
                      child: ActiveMascotWidget(
                        childId: widget.childId,
                        size: selected == question.correctAnswerIndex ? 86 : 82,
                        showBackground: false,
                        mood: selected == question.correctAnswerIndex
                            ? MascotMood.cheering
                            : MascotMood.crying,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    _answerFeedbackText(question),
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: isLastQuestion ? 'Finish' : 'Next',
          isLoading: isLastQuestion && _isSaving,
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            if (isLastQuestion) {
              _completeSession(totalQuestions);
            } else {
              setState(() {
                currentQuestionIndex++;
                selected = null;
                _rearrangeOrder = null;
                _rearrangeSubmitted = false;
                _draggedOptionIndex = null;
                _fillBlankSubmitted = false;
                _dragDropSpellingSubmitted = false;
                _matchingSubmitted = false;
                _strokeTraceSubmitted = false;
                _strokeHadWrongAttempt = false;
                _numberSubmitted = false;
                _numberController.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuestionText(Question question, String language) {
    final type = question.type?.toLowerCase() ?? 'mcq';
    if (type == 'fillblank' || type == 'fillblanklistening') {
      return _buildFillBlankSentence(question, language);
    }

    // Prompt with blanks is rendered inside the body widget
    if (type == 'fillblanklist') return const SizedBox.shrink();

    final bool isDragDropSpelling = type == 'dragdropspelling';

    return Text.rich(
      TextSpan(
        children: [
          if (!isDragDropSpelling)
            TextSpan(
              text: question.text,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(
                left: isDragDropSpelling ? 0 : AppSpacing.sm,
              ),
              child: SizedBox(
                width: 28,
                height: 28,
                child: AudioPromptPlayer(
                  key: ValueKey('audio_${question.id}'),
                  url: question.promptAudioUrl,
                  textToSpeak: question.promptAudioText ?? question.text,
                  language: language,
                  autoPlay: true,
                  isSmall: true,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFillBlankSentence(Question question, String language) {
    // Regex for both half-width () and full-width （ ） parentheses with optional whitespace
    final RegExp bracketRegex = RegExp(r'[\(\（]\s*[\)\）]');
    final String text = question.text;

    List<String> parts;
    bool hasBrackets = bracketRegex.hasMatch(text);

    if (hasBrackets) {
      final match = bracketRegex.firstMatch(text)!;
      parts = [text.substring(0, match.start), text.substring(match.end)];
    } else if (text.contains('____')) {
      parts = text.split('____');
    } else {
      parts = [text, ''];
    }

    final sentenceStyle = AppTextStyles.cardTitle.copyWith(fontSize: 16);

    return DragTarget<int>(
      key: const ValueKey('fillblank_drop_target'),
      onAcceptWithDetails: (details) {
        if (_fillBlankSubmitted) return;
        setState(() {
          _draggedOptionIndex = details.data;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final bool isOccupied = _draggedOptionIndex != null;
        return Text.rich(
          TextSpan(
            style: sentenceStyle,
            children: [
              if (parts.isNotEmpty && parts[0].isNotEmpty)
                TextSpan(text: parts[0]),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  constraints: const BoxConstraints(
                    minWidth: 64,
                    maxWidth: 130,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? AppColors.primaryContainer
                        : isOccupied
                        ? AppColors.primaryLight
                        : AppColors.primaryLight,
                    borderRadius: AppRadius.r(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.primary,
                      width: candidateData.isNotEmpty ? 3 : 2,
                    ),
                    boxShadow: candidateData.isNotEmpty
                        ? AppShadows.strong
                        : AppShadows.card,
                  ),
                  child: Text(
                    isOccupied
                        ? question.options[_draggedOptionIndex!].text
                        : '？',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isOccupied
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (parts.length > 1 && parts[1].isNotEmpty)
                TextSpan(text: parts[1]),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: AudioPromptPlayer(
                      key: ValueKey('audio_${question.id}'),
                      url: question.promptAudioUrl,
                      textToSpeak: question.promptAudioText ?? question.text,
                      language: language,
                      autoPlay: true,
                      isSmall: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  bool _isQuestionComplete(Question question) {
    final type = question.type?.toLowerCase() ?? 'mcq';
    if (type == 'rearrange') return _rearrangeSubmitted;
    if (type == 'fillblank' || type == 'fillblanklistening') {
      return _fillBlankSubmitted;
    }
    if (type == 'fillblanklist') return _fillBlankListSubmitted;
    if (type == 'dragdropspelling') return _dragDropSpellingSubmitted;
    if (type == 'matching') return _matchingSubmitted;
    if (type == 'stroke_trace') return _strokeTraceSubmitted;
    if (type == 'keyinnumber') return _numberSubmitted;
    return selected != null;
  }

  Widget _buildQuestionBody(Question question) {
    final type = question.type?.toLowerCase() ?? 'mcq';

    switch (type) {
      case 'rearrange':
        return _buildRearrangeQuestion(
          question,
          key: ValueKey('rearrange_${question.id}'),
        );
      case 'fillblank':
      case 'fillblanklistening':
        return _buildFillBlankQuestion(
          question,
          key: ValueKey('fillblank_${question.id}'),
        );
      case 'fillblanklist':
        return _buildFillBlankListQuestion(
          question,
          key: ValueKey('fillblanklist_${question.id}'),
        );
      case 'dragdropspelling':
        return DragDropSpellingWidget(
          key: ValueKey('dragdrop_${question.id}'),
          question: question,
          onCorrectAttempt: () {
            unawaited(_playStrokeCorrect(0));
          },
          onWrongAttempt: () {
            unawaited(_playStrokeWrong());
            _strokeHadWrongAttempt = true;
          },
          onCompleted: (isCorrect) {
            setState(() {
              _dragDropSpellingSubmitted = true;
              selected = isCorrect ? question.correctAnswerIndex : -1;
              if (isCorrect) score++;
              _playQuestionFeedback(question, isCorrect);
            });
            unawaited(_recordQuestionResult(question, isCorrect));
          },
        );
      case 'matching':
        return MatchingWidget(
          key: ValueKey('matching_${question.id}'),
          question: question,
          showPrompt: false,
          onCorrectMatch: () {
            unawaited(
              _playStrokeCorrect(0),
            ); // Use stroke correct sound for individual matches
          },
          onWrongAttempt: () {
            unawaited(_playStrokeWrong());
            _strokeHadWrongAttempt =
                true; // Use same flag to track if any mistake happened
          },
          onCompleted: (isCorrect) {
            setState(() {
              _matchingSubmitted = true;
              selected = isCorrect ? question.correctAnswerIndex : -1;
              if (isCorrect) score++;
              _playQuestionFeedback(question, isCorrect);
            });
            unawaited(
              _recordQuestionResult(
                question,
                isCorrect && !_strokeHadWrongAttempt,
              ),
            );
          },
        );
      case 'stroke_trace':
        return _buildStrokeTraceQuestion(question);
      case 'keyinnumber':
        return _buildNumberQuestion(question);
      case 'mcq':
      default:
        final isAnswerImage = question.options.any(
          (o) => o.imageUrl != null && o.imageUrl!.isNotEmpty,
        );
        if (isAnswerImage) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final parentWidth = constraints.maxWidth;
              const crossAxisCount = 2;
              final itemWidth =
                  (parentWidth - (crossAxisCount - 1) * AppSpacing.xs) /
                  crossAxisCount;

              final double avatarSize = parentWidth > 360 ? 32.0 : 24.0;
              final double imageSize = (itemWidth * 0.55).clamp(48.0, 110.0);
              final double padding = AppSpacing.md * 2;
              final double spacing = AppSpacing.xs * 3;
              final double textHeight = parentWidth > 360 ? 20.0 : 16.0;
              final double totalHeight =
                  padding + avatarSize + spacing + imageSize + textHeight + 20;

              final aspectRatio = itemWidth / totalHeight;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: aspectRatio,
                children: List.generate(
                  question.options.length,
                  (index) => _option(index, question),
                ),
              );
            },
          );
        }
        return Column(
          children: List.generate(
            question.options.length,
            (index) => _option(index, question),
          ),
        );
    }
  }

  // --- REARRANGE TYPE ---
  List<int>? _rearrangeOrder;
  bool _rearrangeSubmitted = false;

  Widget _buildRearrangeQuestion(Question question, {Key? key}) {
    if (_rearrangeOrder == null) {
      _rearrangeOrder = List.generate(question.options.length, (i) => i);
      // Shuffle initially until it DOESN'T match the correct order (if possible)
      int attempts = 0;
      while (attempts < 5) {
        _rearrangeOrder!.shuffle();
        bool matches = true;
        for (int i = 0; i < _rearrangeOrder!.length; i++) {
          final currentText = question.options[_rearrangeOrder![i]].text;
          final correctText =
              question.correctOrder != null && i < question.correctOrder!.length
              ? question.correctOrder![i]
              : question.options[i].text;
          if (currentText != correctText) {
            matches = false;
            break;
          }
        }
        if (!matches) break;
        attempts++;
      }
    }

    return Column(
      children: [
        const Text(
          'Drag to put them in the right order!',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            buildDefaultDragHandles:
                false, // Disable default long-press handles
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (_rearrangeSubmitted) return;
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final int item = _rearrangeOrder!.removeAt(oldIndex);
                _rearrangeOrder!.insert(newIndex, item);
              });
            },
            children: [
              for (int i = 0; i < _rearrangeOrder!.length; i++)
                _reorderableItem(i, question),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reorderableItem(int index, Question question) {
    final optionIndex = _rearrangeOrder![index];
    final option = question.options[optionIndex];

    return ReorderableDragStartListener(
      key: ValueKey('reorder_$optionIndex'),
      index: index,
      enabled: !_rearrangeSubmitted,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.r(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            if (!_rearrangeSubmitted) ...[
              const Icon(Icons.drag_indicator, color: AppColors.mutedText),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: Text(option.text, style: AppTextStyles.bodyBold)),
          ],
        ),
      ),
    );
  }

  // --- FILL IN THE BLANK TYPE ---
  int? _draggedOptionIndex;
  bool _fillBlankSubmitted = false;
  bool _dragDropSpellingSubmitted = false;
  bool _matchingSubmitted = false;
  bool _strokeTraceSubmitted = false;
  bool _strokeHadWrongAttempt = false;

  // --- FILL BLANK LIST TYPE (multiple blanks) ---
  List<int?> _fillBlankListAnswers = [];
  bool _fillBlankListSubmitted = false;

  final List<TextEditingController> _fillBlankListControllers = [];

  Widget _buildNumberQuestion(Question question) {
    final correctNumber = question.correctNumber;
    final hasAnswer =
        correctNumber != null ||
        (question.correctAnswers != null &&
            question.correctAnswers!.isNotEmpty);
    if (!hasAnswer) {
      return Column(
        children: [
          const Text(
            'This question is unavailable because its answer data is invalid.',
            style: AppTextStyles.small,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Continue',
            onPressed: () {
              setState(() {
                _numberSubmitted = true;
                selected = -1;
              });
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.r(AppRadius.xl),
            boxShadow: AppShadows.card,
          ),
          child: TextField(
            key: const ValueKey('numeric_answer_input'),
            controller: _numberController,
            enabled: !_numberSubmitted,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(
              fontSize: 32,
              color: AppColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '?',
              hintStyle: AppTextStyles.title.copyWith(
                fontSize: 32,
                color: AppColors.mutedText.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) {
              if (!_numberSubmitted && _numberController.text.isNotEmpty) {
                _checkNumberAnswer(question);
              }
            },
          ),
        ),
      ],
    );
  }

  void _checkNumberAnswer(Question question) {
    final input = _numberController.text.trim();
    if (input.isEmpty) return;

    final isCorrect = question.isCorrectKeyInAnswer(input);

    setState(() {
      _numberSubmitted = true;
      selected = isCorrect ? question.correctAnswerIndex : -1;
      if (isCorrect) score++;
    });
    unawaited(_playQuestionFeedback(question, isCorrect));
    unawaited(_recordQuestionResult(question, isCorrect));
  }

  String _answerFeedbackText(Question question) {
    if (selected == question.correctAnswerIndex) {
      return 'Well done! Keep going! 🎉';
    }

    final type = question.type?.toLowerCase();
    if (type == 'fillblanklist' && question.correctOrder != null) {
      return 'Not quite! The correct answers are: ${question.correctOrder!.join(', ')}.';
    }
    if (type == 'matching') {
      return 'Better luck next time!';
    }
    if (type == 'dragdropspelling') {
      return 'Remember to check the letter order.';
    }
    if (type == 'stroke_trace') {
      return 'Watch the stroke order and try again later.';
    }
    if (type == 'rearrange' && question.correctOrder != null) {
      return 'The correct sentence is "${question.correctOrder!.join(' ')}".';
    }
    if (type == 'keyinnumber' && question.correctNumber != null) {
      return 'Not quite! The answer is ${question.correctNumber}.';
    }

    String? answer;
    if ((type == 'fillblank' || type == 'fillblanklistening') &&
        question.correctBlank != null &&
        question.correctBlank!.isNotEmpty) {
      answer = question.correctBlank;
    } else if (question.correctAnswerIndex >= 0 &&
        question.correctAnswerIndex < question.options.length) {
      answer = question.options[question.correctAnswerIndex].text;
    }

    if (answer != null && answer.isNotEmpty) {
      return 'The answer is "$answer".';
    }
    return 'Try again next time.';
  }

  Widget _buildFillBlankQuestion(Question question, {Key? key}) {
    return Column(
      children: [
        const Text(
          'Drag the correct word to the blank!',
          style: AppTextStyles.small,
        ),
        const SizedBox(height: AppSpacing.md),
        // Word options to drag from
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: List.generate(question.options.length, (index) {
            final isUsed = _draggedOptionIndex == index;
            return Draggable<int>(
              data: index,
              feedback: _draggableOption(index, question, true),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _draggableOption(index, question, false),
              ),
              child: isUsed
                  ? const SizedBox(width: 80, height: 40)
                  : _draggableOption(index, question, false),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFillBlankListQuestion(Question question, {Key? key}) {
    // ── Keyboard input mode — no options to drag, player types answers ──────────
    if (question.options.isEmpty) {
      final blanksCount = question.correctOrder?.length ?? 0;

      // Initialise controllers if size changed (new question)
      if (_fillBlankListControllers.length != blanksCount) {
        for (final c in _fillBlankListControllers) {
          c.dispose();
        }
        _fillBlankListControllers.clear();
        for (int i = 0; i < blanksCount; i++) {
          _fillBlankListControllers.add(TextEditingController());
        }
      }

      final allFilled = _fillBlankListControllers.every(
        (c) => c.text.trim().isNotEmpty,
      );

      return Column(
        key: key,
        children: [
          Text(
            question.text,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(blanksCount, (index) {
            final isSubmitted = _fillBlankListSubmitted;
            final correctAnswer = question.correctOrder![index];
            final userAnswer = _fillBlankListControllers[index].text.trim();
            final isCorrect = userAnswer == correctAnswer;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Text('Blank ${index + 1}:', style: AppTextStyles.bodyBold),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _fillBlankListControllers[index],
                      enabled: !isSubmitted,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '?',
                        filled: true,
                        fillColor: isSubmitted
                            ? isCorrect
                                  ? AppColors.accentLight
                                  : AppColors.destructiveLight
                            : AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.r(AppRadius.md),
                          borderSide: BorderSide(
                            color: isSubmitted
                                ? isCorrect
                                      ? AppColors.accent
                                      : AppColors.destructive
                                : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.r(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.r(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        suffixIcon: isSubmitted
                            ? Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect
                                    ? AppColors.accent
                                    : AppColors.destructive,
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  // Show correct answer beside wrong answer after submit
                  if (isSubmitted && !isCorrect) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '→ $correctAnswer',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (!_fillBlankListSubmitted && allFilled) ...[
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Check Answers',
              onPressed: () {
                final allCorrect = List.generate(
                  blanksCount,
                  (i) =>
                      _fillBlankListControllers[i].text.trim() ==
                      question.correctOrder![i],
                ).every((c) => c);

                setState(() {
                  _fillBlankListSubmitted = true;
                  selected = allCorrect ? question.correctAnswerIndex : -1;
                  if (allCorrect) score++;
                });
                unawaited(_playQuestionFeedback(question, allCorrect));
                unawaited(_recordQuestionResult(question, allCorrect));
              },
            ),
          ],
        ],
      );
    }

    // ── Drag mode — existing implementation unchanged below ───────────────────
    final RegExp blankRegex = RegExp(r'（\s*）|___+');
    final lines = question.text.split('\n');

    int totalBlanks = 0;
    for (final line in lines) {
      totalBlanks += blankRegex.allMatches(line).length;
    }

    if (_fillBlankListAnswers.length != totalBlanks) {
      _fillBlankListAnswers = List.filled(totalBlanks, null);
    }

    final usedOptionIndices = _fillBlankListAnswers
        .where((e) => e != null)
        .cast<int>()
        .toSet();
    final allFilled = totalBlanks > 0 && !_fillBlankListAnswers.contains(null);

    final textStyle = AppTextStyles.cardTitle.copyWith(fontSize: 16);

    int globalBlankIdx = 0;
    final lineWidgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        lineWidgets.add(const SizedBox(height: 4));
        continue;
      }

      final matches = blankRegex.allMatches(line).toList();

      if (matches.isEmpty) {
        lineWidgets.add(
          Text(line, style: textStyle, textAlign: TextAlign.center),
        );
        continue;
      }

      final rowChildren = <Widget>[];
      int lastEnd = 0;

      for (final match in matches) {
        if (match.start > lastEnd) {
          rowChildren.add(
            Text(line.substring(lastEnd, match.start), style: textStyle),
          );
        }
        final idx = globalBlankIdx;
        rowChildren.add(_buildFillBlankListSlot(idx, question));
        globalBlankIdx++;
        lastEnd = match.end;
      }
      if (lastEnd < line.length) {
        rowChildren.add(Text(line.substring(lastEnd), style: textStyle));
      }

      lineWidgets.add(
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          children: rowChildren,
        ),
      );
    }

    return Column(
      key: key,
      children: [
        ...lineWidgets,
        const SizedBox(height: AppSpacing.xxl),
        if (!_fillBlankListSubmitted) ...[
          const Text(
            'Drag the correct answers to the blanks!',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: List.generate(question.options.length, (optIdx) {
              final isUsed = usedOptionIndices.contains(optIdx);
              return Draggable<int>(
                data: optIdx,
                feedback: _draggableOption(optIdx, question, true),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _draggableOption(optIdx, question, false),
                ),
                child: isUsed
                    ? Opacity(
                        opacity: 0.3,
                        child: _draggableOption(optIdx, question, false),
                      )
                    : _draggableOption(optIdx, question, false),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (allFilled)
            PrimaryButton(
              label: 'Check Answer',
              onPressed: () {
                final answers = _fillBlankListAnswers
                    .map(
                      (idx) => idx != null
                          ? question.options[idx].text.trim().toLowerCase()
                          : '',
                    )
                    .toList();

                bool isCorrect = false;
                if (question.correctOrder != null &&
                    question.correctOrder!.length == answers.length) {
                  isCorrect = true;
                  for (int i = 0; i < answers.length; i++) {
                    if (answers[i] !=
                        question.correctOrder![i].trim().toLowerCase()) {
                      isCorrect = false;
                      break;
                    }
                  }
                }

                setState(() {
                  _fillBlankListSubmitted = true;
                  selected = isCorrect ? question.correctAnswerIndex : -1;
                  if (isCorrect) score++;
                });
                unawaited(_playQuestionFeedback(question, isCorrect));
                unawaited(_recordQuestionResult(question, isCorrect));
              },
            ),
        ],
      ],
    );
  }

  Widget _buildFillBlankListSlot(int blankIdx, Question question) {
    final filledOptIdx = blankIdx < _fillBlankListAnswers.length
        ? _fillBlankListAnswers[blankIdx]
        : null;

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => !_fillBlankListSubmitted,
      onAcceptWithDetails: (details) {
        setState(() {
          final optIdx = details.data;
          // If the same option is in another slot, clear it
          for (int i = 0; i < _fillBlankListAnswers.length; i++) {
            if (_fillBlankListAnswers[i] == optIdx && i != blankIdx) {
              _fillBlankListAnswers[i] = null;
            }
          }
          _fillBlankListAnswers[blankIdx] = optIdx;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isOccupied = filledOptIdx != null;

        return GestureDetector(
          onTap: isOccupied && !_fillBlankListSubmitted
              ? () => setState(() => _fillBlankListAnswers[blankIdx] = null)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minWidth: 56, maxWidth: 120),
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isHovering
                  ? AppColors.primaryContainer
                  : AppColors.primaryLight,
              borderRadius: AppRadius.r(AppRadius.sm),
              border: Border.all(
                color: AppColors.primary,
                width: isHovering ? 3 : 2,
              ),
              boxShadow: isHovering ? AppShadows.strong : AppShadows.card,
            ),
            child: Text(
              isOccupied ? question.options[filledOptIdx].text : '？',
              style: AppTextStyles.bodyBold.copyWith(
                color: isOccupied
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.4),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget _draggableOption(int index, Question question, bool isFeedback) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.r(AppRadius.md),
          border: Border.all(color: AppColors.primary),
          boxShadow: isFeedback ? AppShadows.strong : AppShadows.card,
        ),
        child: Text(
          question.options[index].text,
          style: AppTextStyles.bodyBold,
        ),
      ),
    );
  }

  Widget _buildStrokeTraceQuestion(Question question) {
    return StrokeTraceQuestion(
      key: ValueKey('stroke_trace_${question.id}'),
      question: question,
      onWrongAttempt: () {
        unawaited(_playStrokeWrong());
        _strokeHadWrongAttempt = true;
      },
      onCorrectStroke: (strokeIndex) {
        unawaited(_playStrokeCorrect(strokeIndex));
      },
      onComplete: (isCorrect) {
        if (_strokeTraceSubmitted) return;
        setState(() {
          _strokeTraceSubmitted = true;
          selected = isCorrect ? question.correctAnswerIndex : -1;
          if (isCorrect) score++;
        });
        unawaited(_playTracingCompletionFeedback(question, isCorrect));
        unawaited(
          _recordQuestionResult(question, isCorrect && !_strokeHadWrongAttempt),
        );
      },
    );
  }

  Widget _option(int index, Question question) {
    final option = question.options[index];
    final picked = selected == index;
    final isCorrect = index == question.correctAnswerIndex;
    final showCorrect = selected != null && isCorrect;
    final showWrong = picked && !isCorrect;

    final color = showCorrect
        ? AppColors.accentLight
        : showWrong
        ? AppColors.destructiveLight
        : AppColors.card;

    final isAnswerImage = question.options.any(
      (o) => o.imageUrl != null && o.imageUrl!.isNotEmpty,
    );

    if (isAnswerImage) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmallDevice = constraints.maxWidth < 180;
          final double avatarSize = isSmallDevice ? 24.0 : 32.0;

          return InkWell(
            onTap: selected == null
                ? () {
                    final isCorrect = index == question.correctAnswerIndex;
                    if (isCorrect) {
                      HapticFeedback.mediumImpact();
                      _playQuestionFeedback(question, true);
                    } else {
                      HapticFeedback.vibrate();
                      _playQuestionFeedback(question, false);
                    }
                    setState(() {
                      selected = index;
                      if (isCorrect) {
                        score++;
                      }
                    });
                    unawaited(_recordQuestionResult(question, isCorrect));
                  }
                : null,
            borderRadius: AppRadius.r(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.r(AppRadius.lg),
                border: Border.all(
                  color: showCorrect
                      ? AppColors.accent
                      : showWrong
                      ? AppColors.destructive
                      : AppColors.border,
                ),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: AppColors.muted,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: AppTextStyles.bodyBold.copyWith(
                            fontSize: isSmallDevice ? 11 : 13,
                          ),
                        ),
                      ),
                      if (showCorrect)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.accent,
                          size: 20,
                        )
                      else if (showWrong)
                        const Icon(
                          Icons.cancel,
                          color: AppColors.destructive,
                          size: 20,
                        )
                      else
                        const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (option.imageUrl != null && option.imageUrl!.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.imagePlaceholder,
                            borderRadius: AppRadius.r(AppRadius.md),
                          ),
                          child: ClipRRect(
                            borderRadius: AppRadius.r(AppRadius.md),
                            child: Image.network(
                              option.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.image,
                                    size: isSmallDevice ? 24 : 32,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  if (option.text.isNotEmpty)
                    Text(
                      option.text,
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: isSmallDevice ? 13 : 15,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: selected == null
            ? () {
                final isCorrect = index == question.correctAnswerIndex;
                if (isCorrect) {
                  HapticFeedback.mediumImpact();
                  _playQuestionFeedback(question, true);
                } else {
                  HapticFeedback.vibrate();
                  _playQuestionFeedback(question, false);
                }
                setState(() {
                  selected = index;
                  if (isCorrect) {
                    score++;
                  }
                });
                unawaited(_recordQuestionResult(question, isCorrect));
              }
            : null,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(
              color: showCorrect
                  ? AppColors.accent
                  : showWrong
                  ? AppColors.destructive
                  : AppColors.border,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.muted,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (option.imageUrl != null && option.imageUrl!.isNotEmpty) ...[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: AppRadius.r(AppRadius.md),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.r(AppRadius.md),
                    child: Image.network(
                      option.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              if (option.text.isNotEmpty)
                Expanded(
                  child: Text(option.text, style: AppTextStyles.bodyBold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BearsDenChip extends StatelessWidget {
  const _BearsDenChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: AppRadius.r(AppRadius.md),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Text(
          label,
          style: AppTextStyles.tiny.copyWith(color: const Color(0xFF92400E)),
        ),
      ),
    );
  }
}
