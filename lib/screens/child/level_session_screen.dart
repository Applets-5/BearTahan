import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/question.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../utils/audio_contexts.dart';
import '../../utils/sound_effects.dart';
import '../../utils/star_utils.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/audio_prompt_player.dart';
import '../../widgets/questions/drag_drop_spelling_widget.dart';
import '../../widgets/questions/matching_widget.dart';
import '../../widgets/child/stroke_trace_question.dart';

class LevelSessionScreen extends ConsumerStatefulWidget {
  const LevelSessionScreen({
    super.key,
    this.childId,
    this.levelPrefix = 'bm_c1_l1_',
    this.subjectId = 'bm',
    this.levelId = 'l1',
    this.showFeedbackMascot = true,
  });

  final String? childId;
  final String levelPrefix;
  final String subjectId;
  final String levelId;
  final bool showFeedbackMascot;

  @override
  ConsumerState<LevelSessionScreen> createState() => _LevelSessionScreenState();
}

class _LevelSessionScreenState extends ConsumerState<LevelSessionScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  bool _timerStarted = false;

  int? selected;
  List<Question>? shuffledQuestions;
  List<Question>? _lastRawQuestions;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final Future<void> _feedbackAudioContextReady;
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
    _feedbackAudioContextReady = _audioPlayer.setAudioContext(
      soundEffectAudioContext(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionTimer();
    });
    unawaited(_initializeSoundEffectAudio());
  }

  bool get _soundEffectsEnabled {
    return soundEffectsEnabled(ref.read(parentSettingsProvider).value);
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
      _stopCorrectAnswer = await pool.start(volume: 0.70);
    } else {
      await _stopWrongAnswer?.call();
      _stopWrongAnswer = await pool.start(volume: 0.70);
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
    unawaited(_disposeSoundEffectAudio());
    unawaited(_audioPlayer.dispose());
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
    _stopSessionTimer();

    int stars = 0;
    bool isEscalated = false;
    bool isDailyBonus = false;
    final newlyUnlockedOutfits = <String>[];

    try {
      final parentId = ref.read(parentIdProvider);
      if (widget.childId != null && parentId.isNotEmpty) {
        final firestore = ref.read(firestoreServiceProvider);

        // For summary stages, we need to know if it escalated or got a daily bonus
        if (widget.levelId.toLowerCase().contains('summary')) {
          final levelData = await firestore.getLevelProgress(
            parentId,
            widget.childId!,
            widget.subjectId,
            widget.levelId,
          );
          final int currentThreshold = (levelData['summaryThreshold'] ?? 0)
              .toInt();
          final DateTime? lastSummaryStarDate =
              levelData['lastSummaryStarDate'] != null
                  ? (levelData['lastSummaryStarDate'] as Timestamp).toDate()
                  : null;

          final result = StarUtils.calculateSummaryResult(
            score: score,
            total: totalQuestions,
            currentThreshold: currentThreshold,
            lastSummaryStarDate: lastSummaryStarDate,
          );

          isEscalated = result['newThreshold'] > currentThreshold;
          isDailyBonus = result['earnedDailyStar'];
        }

        // Update progress and get calculated stars (handles summary thresholds/daily cap)
        stars = await firestore.updateLevelProgress(
          parentId,
          widget.childId!,
          widget.subjectId,
          widget.levelId,
          score,
          totalQuestions,
        );

        // Record detailed attempt including timer data
        await firestore.recordAttempt(
          parentId,
          widget.childId!,
          subjectId: widget.subjectId,
          levelId: widget.levelId,
          score: score,
          total: totalQuestions,
          stars: stars,
          timeInSeconds: _elapsedSeconds,
        );

        // Evaluate and update quest progress for outfit unlocks
        newlyUnlockedOutfits.addAll(
          await firestore.evaluateAndUpdateQuestProgress(
            parentId,
            widget.childId!,
          ),
        );
      } else {
        // Fallback for offline/guest mode
        stars = StarUtils.calculateStars(
          score: score,
          total: totalQuestions,
          levelId: widget.levelId,
        );
      }
    } catch (e) {
      debugPrint('Error saving attempt: $e');
      stars = StarUtils.calculateStars(
        score: score,
        total: totalQuestions,
        levelId: widget.levelId,
      );
    }

    // Play appropriate audio
    final String audioPath = stars > 0
        ? 'audio/levelPassed.mp3'
        : 'audio/levelFailed.mp3';
    
    final playFuture = _playSound(() async {
      await _feedbackAudioContextReady;
      final completed = _audioPlayer.onPlayerComplete.first;
      await _audioPlayer.play(AssetSource(audioPath), volume: 0.60);
      await completed;
    });

    // Wait for the audio to finish before navigating
    await playFuture;

    if (mounted) {
      final params = {
        'childId': widget.childId ?? '',
        'score': score.toString(),
        'total': totalQuestions.toString(),
        'levelId': widget.levelId,
        'subjectId': widget.subjectId,
        'stars': stars.toString(),
        'isEscalated': isEscalated.toString(),
        'isDailyBonus': isDailyBonus.toString(),
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



  @override
  Widget build(BuildContext context) {
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

            // If questions are ready, we need to fetch stats for prioritization
            // (Only for Summary and Revision stages)
            final isSummary = widget.levelId.toLowerCase().contains('summary');
            final needsPrioritization = isSummary || isRevision;

            if (shuffledQuestions == null ||
                _lastRawQuestions != rawQuestions) {
              _lastRawQuestions = rawQuestions;

              if (needsPrioritization) {
                return FutureBuilder<Map<String, Map<String, int>>>(
                  future: ref
                      .read(firestoreServiceProvider)
                      .getQuestionStatsForUser(
                        ref.read(parentIdProvider),
                        widget.childId ?? '',
                        rawQuestions.map((q) => q.id).toList(),
                      ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        shuffledQuestions == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (shuffledQuestions == null) {
                      final stats = snapshot.data ?? {};
                      shuffledQuestions = _prioritizeQuestions(
                        rawQuestions,
                        stats,
                        15,
                        isRevision,
                      );
                    }

                    return _buildSession(shuffledQuestions!);
                  },
                );
              } else {
                final List<Question> temp = List.from(rawQuestions)..shuffle();
                shuffledQuestions = temp.take(10).toList();
              }
            }

            return _buildSession(shuffledQuestions!);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildNoQuestionsPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No questions found for this level.'),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Go Back',
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
        ],
      ),
    );
  }

  Widget _buildSession(List<Question> questions) {
    final question = questions[currentQuestionIndex];
    final isLastQuestion = currentQuestionIndex == questions.length - 1;
    final progress = (currentQuestionIndex + 1) / questions.length;

    String getLanguage() {
      switch (widget.subjectId.toLowerCase()) {
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
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
          const Spacer(flex: 1),
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholder,
                    borderRadius: AppRadius.r(AppRadius.xl),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.r(AppRadius.xl),
                    child: Image.network(
                      question.imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image,
                        color: AppColors.mutedText,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _buildQuestionText(question, getLanguage()),
          const SizedBox(height: AppSpacing.sm),
          _buildQuestionBody(question),
          const Spacer(flex: 2),
          if (selected != null || _isQuestionComplete(question)) ...[
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected == question.correctAnswerIndex
                      ? AppColors.accentLight
                      : AppColors.destructiveLight,
                  borderRadius: AppRadius.r(AppRadius.lg),
                ),
                child: Text(
                  selected == question.correctAnswerIndex
                      ? 'Correct! Well done!'
                      : (question.type?.toLowerCase() == 'rearrange' &&
                            question.correctOrder != null)
                      ? 'Not quite! The correct sentence is "${question.correctOrder!.join(' ')}".'
                      : question
                            .options[question.correctAnswerIndex]
                            .text
                            .isNotEmpty
                      ? 'Not quite! The answer is "${question.options[question.correctAnswerIndex].text}".'
                      : 'Not quite! The correct answer is option ${String.fromCharCode(65 + question.correctAnswerIndex)}.',
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: isLastQuestion ? 'Finish' : 'Next',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (isLastQuestion) {
                  _completeSession(questions.length);
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
                  });
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionText(Question question, String language) {
    final type = question.type?.toLowerCase() ?? 'mcq';
    if (type == 'fillblank' || type == 'fillblanklistening') {
      return _buildFillBlankSentence(question, language);
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: question.text,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
          ),
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

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.sm,
      children: [
        if (parts.isNotEmpty && parts[0].isNotEmpty)
          Text(
            parts[0],
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        DragTarget<int>(
          onAcceptWithDetails: (details) {
            if (_fillBlankSubmitted) return;
            setState(() {
              _draggedOptionIndex = details.data;
            });
          },
          builder: (context, candidateData, rejectedData) {
            final bool isOccupied = _draggedOptionIndex != null;
            return Container(
              constraints: const BoxConstraints(maxWidth: 100),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: candidateData.isNotEmpty || isOccupied
                        ? AppColors.primary
                        : const Color(0xFFAAAAAA),
                    width: 2,
                  ),
                ),
                color: isOccupied
                    ? AppColors.primaryLight.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Text(
                isOccupied
                    ? question.options[_draggedOptionIndex!].text
                    : '   ',
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            );
          },
        ),
        if (parts.length > 1 && parts[1].isNotEmpty)
          Text(
            parts[1],
            style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        Padding(
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
      ],
    );
  }

  bool _isQuestionComplete(Question question) {
    final type = question.type?.toLowerCase() ?? 'mcq';
    if (type == 'rearrange') return _rearrangeSubmitted;
    if (type == 'fillblank' || type == 'fillblanklistening') {
      return _fillBlankSubmitted;
    }
    if (type == 'dragdropspelling') return _dragDropSpellingSubmitted;
    if (type == 'matching') return _matchingSubmitted;
    if (type == 'stroke_trace') return _strokeTraceSubmitted;
    return selected != null;
  }

  Widget _buildQuestionBody(Question question) {
    final type = question.type?.toLowerCase() ?? 'mcq';

    switch (type) {
      case 'rearrange':
        return _buildRearrangeQuestion(question);
      case 'fillblank':
      case 'fillblanklistening':
        return _buildFillBlankQuestion(question);
      case 'dragdropspelling':
        return DragDropSpellingWidget(
          question: question,
          onCompleted: (isCorrect) {
            setState(() {
              _dragDropSpellingSubmitted = true;
              selected = isCorrect ? question.correctAnswerIndex : -1;
              if (isCorrect) score++;
              _playQuestionFeedback(question, isCorrect);
            });
          },
        );
      case 'matching':
        return MatchingWidget(
          question: question,
          onCompleted: (isCorrect) {
            setState(() {
              _matchingSubmitted = true;
              selected = isCorrect ? question.correctAnswerIndex : -1;
              if (isCorrect) score++;
              _playQuestionFeedback(question, isCorrect);
            });
          },
        );
      case 'stroke_trace':
        return _buildStrokeTraceQuestion(question);
      case 'mcq':
      default:
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

  Widget _buildRearrangeQuestion(Question question) {
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
        SizedBox(
          height: 200,
          child: ReorderableListView(
            onReorderItem: (oldIndex, newIndex) {
              if (_rearrangeSubmitted) return;
              setState(() {
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
        const SizedBox(height: AppSpacing.lg),
        if (!_rearrangeSubmitted)
          PrimaryButton(
            label: 'Check Answer',
            onPressed: () {
              bool isCorrect = true;
              if (question.correctOrder != null) {
                for (int i = 0; i < _rearrangeOrder!.length; i++) {
                  final currentText =
                      question.options[_rearrangeOrder![i]].text;
                  if (i >= question.correctOrder!.length ||
                      currentText != question.correctOrder![i]) {
                    isCorrect = false;
                    break;
                  }
                }
              } else {
                // Fallback to index-based if correctOrder is missing
                for (int i = 0; i < _rearrangeOrder!.length; i++) {
                  if (_rearrangeOrder![i] != i) {
                    isCorrect = false;
                    break;
                  }
                }
              }

              setState(() {
                _rearrangeSubmitted = true;
                selected = isCorrect ? question.correctAnswerIndex : -1;
                if (isCorrect) score++;
                _playQuestionFeedback(question, isCorrect);
              });
            },
          ),
      ],
    );
  }

  Widget _reorderableItem(int index, Question question) {
    final optionIndex = _rearrangeOrder![index];
    final option = question.options[optionIndex];

    return Container(
      key: ValueKey('reorder_$optionIndex'),
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
          const Icon(Icons.drag_indicator, color: AppColors.mutedText),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(option.text, style: AppTextStyles.bodyBold)),
        ],
      ),
    );
  }

  // --- FILL IN THE BLANK TYPE ---
  int? _draggedOptionIndex;
  bool _fillBlankSubmitted = false;
  bool _dragDropSpellingSubmitted = false;
  bool _matchingSubmitted = false;
  bool _strokeTraceSubmitted = false;

  Widget _buildFillBlankQuestion(Question question) {
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
              child: isUsed && !_fillBlankSubmitted
                  ? const SizedBox(width: 80, height: 40)
                  : _draggableOption(index, question, false),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_draggedOptionIndex != null && !_fillBlankSubmitted)
          PrimaryButton(
            label: 'Check Answer',
            onPressed: () {
              // Robust validation: trim and case-insensitive
              final selectedText = question.options[_draggedOptionIndex!].text
                  .trim()
                  .toLowerCase();
              final correctText =
                  question.correctBlank?.trim().toLowerCase() ??
                  question.options[question.correctAnswerIndex].text
                      .trim()
                      .toLowerCase();

              bool isCorrect = selectedText == correctText;

              debugPrint(
                'DEBUG: FillBlank Validation - Selected: "$selectedText", Correct: "$correctText", Result: $isCorrect',
              );

              setState(() {
                _fillBlankSubmitted = true;
                selected = isCorrect ? question.correctAnswerIndex : -1;
                if (isCorrect) score++;
                _playQuestionFeedback(question, isCorrect);
              });
            },
          ),
      ],
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
        final parentId = ref.read(parentIdProvider);
        final childId = widget.childId;
        if (parentId.isEmpty || childId == null || childId.isEmpty) return;

        ref
            .read(firestoreServiceProvider)
            .flagWrongAnswer(
              parentId,
              childId,
              questionId: question.id,
              subjectId: widget.subjectId,
              levelId: widget.levelId,
              questionText: question.text,
            )
            .catchError((error) {
              debugPrint('Error flagging wrong stroke answer: $error');
            });
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
