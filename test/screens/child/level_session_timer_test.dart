import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/services/session_asset_preloader.dart';
import 'package:bear_tahan/services/tts_service.dart';
import 'package:bear_tahan/models/level_progress_result.dart';
import 'package:bear_tahan/router/app_router.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockTtsService extends Mock implements TtsService {}

class ControlledSessionAssetPreloader extends SessionAssetPreloader {
  ControlledSessionAssetPreloader(this.gate)
    : super(ttsService: MockTtsService());

  final Future<void> gate;

  @override
  Future<SessionPreparationReport> preload({
    required BuildContext context,
    required List<Question> questions,
    required String Function(Question question) languageForQuestion,
    Duration timeout = const Duration(seconds: 10),
    PreparationProgressCallback? onProgress,
  }) async {
    await gate;
    return const SessionPreparationReport(
      completedAssets: 0,
      totalAssets: 0,
      failedAssets: 0,
      timedOut: false,
    );
  }
}

void main() {
  late MockFirestoreService mockFirestoreService;

  setUpAll(() {
    registerFallbackValue(
      Question(id: '', text: '', options: [], correctAnswerIndex: 0),
    );
  });

  setUp(() {
    mockFirestoreService = MockFirestoreService();

    when(() => mockFirestoreService.getQuestions(any())).thenAnswer(
      (_) async => [
        Question(
          id: 'q1',
          text: 'Select the correct word:',
          options: ['A', 'Rumah'],
          correctAnswerIndex: 1,
        ),
      ],
    );

    when(
      () => mockFirestoreService.recordAttempt(
        any(),
        any(),
        subjectId: any(named: 'subjectId'),
        levelId: any(named: 'levelId'),
        score: any(named: 'score'),
        total: any(named: 'total'),
        stars: any(named: 'stars'),
        timeInSeconds: any(named: 'timeInSeconds'),
      ),
    ).thenAnswer((_) async => {});

    when(
      () => mockFirestoreService.updateLevelProgress(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenAnswer(
      (_) async => const LevelProgressResult(
        performanceStars: 1,
        newStarsAwarded: 1,
        dailyBonusStars: 0,
        didImprove: true,
        didEscalate: false,
      ),
    );

    when(
      () => mockFirestoreService.evaluateAndUpdateQuestProgress(any(), any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () =>
          mockFirestoreService.updateQuestionStats(any(), any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockFirestoreService.recordReviewQuestionAnswered(
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockFirestoreService.flagWrongAnswer(
        any(),
        any(),
        questionId: any(named: 'questionId'),
        subjectId: any(named: 'subjectId'),
        levelId: any(named: 'levelId'),
        questionText: any(named: 'questionText'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockFirestoreService.getReviewQuestions(
        any(),
        any(),
        subjectId: any(named: 'subjectId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => []);

    when(
      () => mockFirestoreService.getQuestionStatsForUser(any(), any(), any()),
    ).thenAnswer((_) async => {});
  });

  Widget createTestableWidget({
    List<Question>? reviewQuestions,
    SessionAssetPreloader? assetPreloader,
  }) {
    final router = GoRouter(
      initialLocation: '/test-level',
      routes: [
        GoRoute(
          path: '/test-level',
          builder: (context, state) => LevelSessionScreen(
            childId: 'mock-child-id',
            subjectId: 'bm',
            levelId: reviewQuestions == null ? 'l1' : 'review_session',
            levelPrefix: reviewQuestions == null ? 'bm_c1_l1_' : 'review_',
            showFeedbackMascot: false,
            reviewQuestions: reviewQuestions,
          ),
        ),
        GoRoute(
          path: AppRouter.completion,
          builder: (context, state) =>
              const Scaffold(body: Text('Completion reached')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        firestoreServiceProvider.overrideWithValue(mockFirestoreService),
        parentIdProvider.overrideWithValue('mock-parent-id'),
        parentSettingsProvider.overrideWith(
          (ref) => Stream.value({'soundEffects': true}),
        ),
        sessionAssetPreloaderProvider.overrideWithValue(
          assetPreloader ??
              ControlledSessionAssetPreloader(Future<void>.value()),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('Level Session Timer Tests', () {
    testWidgets('Timer starts only after session preparation completes', (
      WidgetTester tester,
    ) async {
      final preparationGate = Completer<void>();
      await tester.pumpWidget(
        createTestableWidget(
          assetPreloader: ControlledSessionAssetPreloader(
            preparationGate.future,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Preparing your adventure'), findsOneWidget);
      expect(find.text('00:00'), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:00'), findsNothing);

      preparationGate.complete();
      await tester.pumpAndSettle();
      expect(find.text('00:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('00:02'), findsOneWidget);
    });

    testWidgets('Timer is visible and starts at 00:00', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('Timer counts up in MM:SS format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:03'), findsOneWidget);

      await tester.pump(const Duration(seconds: 62));
      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('Timer continues while on feedback screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('00:05'), findsOneWidget);

      await tester.tap(find.text('Rumah'));
      await tester.pump();

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('00:09'), findsOneWidget);
    });

    testWidgets('Timer stops and elapsed time is saved on completion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 10));

      await tester.tap(find.text('Rumah'));
      await tester.pump();

      await tester.ensureVisible(find.text('Finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Completion reached'), findsOneWidget);

      verify(
        () => mockFirestoreService.recordAttempt(
          'mock-parent-id',
          'mock-child-id',
          subjectId: 'bm',
          levelId: 'l1',
          score: 1,
          total: 1,
          stars: any(named: 'stars'),
          timeInSeconds: 10,
        ),
      ).called(1);
    });

    testWidgets(
      'review completion does not save level progress or an attempt',
      (WidgetTester tester) async {
        final reviewQuestion = Question(
          id: 'bc_c1_l2_q01',
          text: 'Review this question',
          type: 'mcq',
          options: ['Correct', 'Wrong'],
          correctAnswerIndex: 0,
        );

        await tester.pumpWidget(
          createTestableWidget(reviewQuestions: [reviewQuestion]),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Correct'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Finish'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Completion reached'), findsOneWidget);
        verify(
          () => mockFirestoreService.recordReviewQuestionAnswered(
            'mock-parent-id',
            'mock-child-id',
            reviewQuestion.id,
          ),
        ).called(1);
        verifyNever(
          () => mockFirestoreService.updateLevelProgress(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          ),
        );
        verifyNever(
          () => mockFirestoreService.recordAttempt(
            any(),
            any(),
            subjectId: any(named: 'subjectId'),
            levelId: any(named: 'levelId'),
            score: any(named: 'score'),
            total: any(named: 'total'),
            stars: any(named: 'stars'),
            timeInSeconds: any(named: 'timeInSeconds'),
          ),
        );
      },
    );
  });
}
