import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/services/firestore_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late MockFirestoreService mockFirestoreService;

  setUpAll(() {
    registerFallbackValue(Question(
      id: '',
      text: '',
      options: [],
      correctAnswerIndex: 0,
    ));
  });

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    // Default mock behavior
    when(() => mockFirestoreService.getQuestions(any()))
        .thenAnswer((_) async => [
              Question(
                id: 'q1',
                text: 'Select the correct word:',
                options: ['A', 'Rumah'],
                correctAnswerIndex: 1,
              )
            ]);
    
    when(() => mockFirestoreService.recordAttempt(
          any(),
          any(),
          subjectId: any(named: 'subjectId'),
          levelId: any(named: 'levelId'),
          score: any(named: 'score'),
          total: any(named: 'total'),
          stars: any(named: 'stars'),
          timeInSeconds: any(named: 'timeInSeconds'),
        )).thenAnswer((_) async => {});

    when(() => mockFirestoreService.updateLevelProgress(
          any(),
          any(),
          any(),
          any(),
          any(),
        )).thenAnswer((_) async => {});
  });

  Widget createTestableWidget() {
    return ProviderScope(
      overrides: [
        firestoreServiceProvider.overrideWithValue(mockFirestoreService),
        // Providing a dummy parent ID
        parentIdProvider.overrideWithValue('mock-parent-id'),
      ],
      child: const MaterialApp(
        home: LevelSessionScreen(
          childId: 'mock-child-id',
          subjectId: 'bm',
          levelId: 'l1',
          levelPrefix: 'bm_c1_l1_',
        ),
      ),
    );
  }

  group('Level Session Timer Tests', () {
    testWidgets('Timer is visible and starts at 00:00', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Verify timer starts at 00:00
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('Timer counts up in MM:SS format', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Advance time by 3 seconds
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:03'), findsOneWidget);

      // Advance time by 65 seconds total (to check minutes)
      await tester.pump(const Duration(seconds: 62));
      expect(find.text('01:05'), findsOneWidget);
    });

    testWidgets('Timer continues while on feedback screen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('00:05'), findsOneWidget);

      // Tap the correct option 'Rumah'
      await tester.tap(find.text('Rumah'));
      await tester.pump(); // Show feedback

      // We are now on feedback screen, wait 4 more seconds
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('00:09'), findsOneWidget);
    });

    testWidgets('Timer stops and elapsed time is saved on completion', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // Play for 10 seconds
      await tester.pump(const Duration(seconds: 10));

      // Select answer
      await tester.tap(find.text('Rumah'));
      await tester.pump(); 

      // Tap Finish (it's the last and only question)
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle(); // Wait for completion flow

      // Verify recordAttempt was called with exactly 10 seconds
      verify(() => mockFirestoreService.recordAttempt(
            'mock-parent-id',
            'mock-child-id',
            subjectId: 'bm',
            levelId: 'l1',
            score: 1,
            total: 1,
            stars: any(named: 'stars'),
            timeInSeconds: 10,
          )).called(1);
    });
  });
}
