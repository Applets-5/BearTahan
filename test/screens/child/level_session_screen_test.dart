import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/widgets/common/audio_prompt_player.dart';

void main() {
  Widget createTestWidget(List<Question> questions, {Key? key}) {
    return ProviderScope(
      overrides: [
        questionsProvider(
          'test_prefix',
        ).overrideWith((ref) => Future.value(questions)),
        parentIdProvider.overrideWithValue('test_parent_id'),
      ],
      child: MaterialApp(
        home: LevelSessionScreen(
          key: key,
          levelPrefix: 'test_prefix',
          childId: 'test_child_id',
          subjectId: 'bm',
          levelId: 'l1',
        ),
      ),
    );
  }

  group('LevelSessionScreen', () {
    testWidgets('should display MCQ options with A, B, C labels correctly', (
      tester,
    ) async {
      final questions = [
        Question(
          id: 'q1',
          text: 'What is this?',
          type: 'mcq',
          options: [
            QuestionOption(text: 'Option A Text'),
            QuestionOption(text: 'Option B Text'),
          ],
          correctAnswerIndex: 0,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('mcq')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('What is this?'), findsOneWidget);
      expect(find.text('Option A Text'), findsOneWidget);
      expect(find.text('Option B Text'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets(
      'should display Rearrange instructions and reorderable list for rearrange type',
      (tester) async {
        final questions = [
          Question(
            id: 'q1',
            text: 'Arrange the sentence',
            type: 'rearrange',
            options: [
              QuestionOption(text: 'Saya'),
              QuestionOption(text: 'Makan'),
              QuestionOption(text: 'Nasi'),
            ],
            correctAnswerIndex: 0,
            correctOrder: ['Saya', 'Makan', 'Nasi'],
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(questions, key: const ValueKey('rearrange')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Drag to put them in the right order!'),
          findsOneWidget,
        );
        expect(find.byType(ReorderableListView), findsOneWidget);
        expect(find.text('Saya'), findsOneWidget);
        expect(find.text('Makan'), findsOneWidget);
        expect(find.text('Nasi'), findsOneWidget);
      },
    );

    testWidgets(
      'should display Fill-in-the-blank instructions and draggable targets',
      (tester) async {
        final questions = [
          Question(
            id: 'q1',
            text: 'Ini ____ buku.',
            type: 'fillblank',
            options: [
              QuestionOption(text: 'ialah'),
              QuestionOption(text: 'adalah'),
            ],
            correctAnswerIndex: 0,
            correctBlank: 'ialah',
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(questions, key: const ValueKey('fillblank')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.text('Drag the correct word to the blank!'),
          findsOneWidget,
        );
        expect(find.text('Ini '), findsOneWidget);
        expect(find.text(' buku.'), findsOneWidget);
        expect(find.byType(DragTarget<int>), findsOneWidget);
        expect(find.byType(Draggable<int>), findsNWidgets(2));
      },
    );

    testWidgets('should display image container when imageUrl is provided', (
      tester,
    ) async {
      final questionsWithImage = [
        Question(
          id: 'q1',
          text: 'Question with image',
          imageUrl: 'https://example.com/image.png',
          options: [QuestionOption(text: 'Yes')],
          correctAnswerIndex: 0,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questionsWithImage, key: const ValueKey('img_yes')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should NOT display image container when imageUrl is missing', (
      tester,
    ) async {
      final questionsWithoutImage = [
        Question(
          id: 'q2',
          text: 'Question without image',
          options: [QuestionOption(text: 'Yes')],
          correctAnswerIndex: 0,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questionsWithoutImage, key: const ValueKey('img_no')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('should show audio prompt player for all question types', (
      tester,
    ) async {
      final questions = [
        Question(
          id: 'q1',
          text: 'Speak this',
          options: [QuestionOption(text: 'OK')],
          correctAnswerIndex: 0,
          promptAudioUrl: 'audio.mp3',
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('audio')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AudioPromptPlayer), findsOneWidget);
    });

    testWidgets('should render stroke tracing question type', (tester) async {
      final questions = [
        Question(
          id: 'q_stroke',
          text: 'Trace this character',
          type: 'stroke_trace',
          options: const [],
          correctAnswerIndex: 0,
          characterUnicode: '人',
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('stroke_trace')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Trace 人'), findsOneWidget);
      expect(find.textContaining('attempts left'), findsOneWidget);
    });

    testWidgets(
      'should handle empty question pool gracefully with error message',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget([], key: const ValueKey('empty')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('No questions found for this level.'), findsOneWidget);
        expect(find.text('Go Back'), findsOneWidget);
      },
    );
  });
}
