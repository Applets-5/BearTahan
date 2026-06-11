import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/models/level_progress_result.dart';
import 'package:bear_tahan/router/app_router.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

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
      () => mockFirestoreService.flagWrongAnswer(
        any(),
        any(),
        questionId: any(named: 'questionId'),
        subjectId: any(named: 'subjectId'),
        levelId: any(named: 'levelId'),
        questionText: any(named: 'questionText'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget createTestableWidget() {
    final router = GoRouter(
      initialLocation: '/test-level',
      routes: [
        GoRoute(
          path: '/test-level',
          builder: (context, state) => const LevelSessionScreen(
            childId: 'mock-child-id',
            subjectId: 'bm',
            levelId: 'l1',
            levelPrefix: 'bm_c1_l1_',
            showFeedbackMascot: false,
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
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('Level Session Timer Tests', () {
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

      await tester.tap(find.text('Finish'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
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
  });
}
