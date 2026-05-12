import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';

void main() {
  final List<Question> questionPool = List.generate(
    20,
    (i) => Question(
      id: 'q$i',
      text: 'Question $i',
      options: ['Option A', 'Option B', 'Option C', 'Option D'],
      correctAnswerIndex: 0,
    ),
  );

  group('shuffledQuestions', () {
    testWidgets('should only contain 10 questions even if pool is larger', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool)),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final state = tester.state(find.byType(LevelSessionScreen)) as dynamic;
      expect(state.shuffledQuestions.length, 10);
    });

    testWidgets('should not reset questions or progress on widget rebuild', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool)),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stateBefore = tester.state(find.byType(LevelSessionScreen)) as dynamic;
      final firstQuestionId = stateBefore.shuffledQuestions[0].id;

      // Select an answer to move state and trigger some internal updates
      await tester.tap(find.text('Option A'));
      await tester.pump();

      // Trigger a rebuild by calling markNeedsBuild on the element
      tester.element(find.byType(LevelSessionScreen)).markNeedsBuild();
      await tester.pump();

      final stateAfter = tester.state(find.byType(LevelSessionScreen)) as dynamic;
      expect(stateAfter.shuffledQuestions[0].id, firstQuestionId);
      expect(stateAfter.currentQuestionIndex, 0);
    });
  });

  group('score', () {
    testWidgets('should increment when tapping the correct option', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool.take(1).toList())),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Option A is correct (index 0)
      await tester.tap(find.text('Option A'));
      await tester.pump();

      final state = tester.state(find.byType(LevelSessionScreen)) as dynamic;
      expect(state.score, 1);
    });

    testWidgets('should not increment when tapping a wrong option', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool.take(1).toList())),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Option B is wrong (index 1)
      await tester.tap(find.text('Option B'));
      await tester.pump();

      final state = tester.state(find.byType(LevelSessionScreen)) as dynamic;
      expect(state.score, 0);
    });

    testWidgets('should not change score if tapping other options after selection', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool.take(1).toList())),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First tap correct
      await tester.tap(find.text('Option A'));
      await tester.pump();
      
      final state = tester.state(find.byType(LevelSessionScreen)) as dynamic;
      expect(state.score, 1);

      // Tap wrong option - score should not change
      await tester.tap(find.text('Option B'));
      await tester.pump();

      expect(state.score, 1);
    });
  });

  group('navigation', () {
    testWidgets('should display Finish button on the last question', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool.take(1).toList())),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select an answer for the single question to show the Next/Finish button
      await tester.tap(find.text('Option A'));
      await tester.pump();

      expect(find.text('Finish'), findsOneWidget);
    });

    testWidgets('should allow closing the session via the close button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            questionsProvider('test_prefix').overrideWith((ref) => Future.value(questionPool.take(1).toList())),
          ],
          child: const MaterialApp(
            home: LevelSessionScreen(levelPrefix: 'test_prefix'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
    });
  });
}

extension on State<LevelSessionScreen> {
  List<Question> get shuffledQuestions {
    final dynamicState = this as dynamic;
    return dynamicState.shuffledQuestions;
  }

  int get currentQuestionIndex {
    final dynamicState = this as dynamic;
    return dynamicState.currentQuestionIndex;
  }

  int get score {
    final dynamicState = this as dynamic;
    return dynamicState.score;
  }
}
