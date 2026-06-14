import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/widgets/child/stroke_trace_question.dart';
import 'package:bear_tahan/widgets/common/audio_prompt_player.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/services/session_asset_preloader.dart';
import 'package:bear_tahan/services/tts_service.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockTtsService extends Mock implements TtsService {}

class ImmediateSessionAssetPreloader extends SessionAssetPreloader {
  ImmediateSessionAssetPreloader() : super(ttsService: MockTtsService());

  @override
  Future<SessionPreparationReport> preload({
    required BuildContext context,
    required List<Question> questions,
    required String Function(Question question) languageForQuestion,
    Duration timeout = const Duration(seconds: 10),
    PreparationProgressCallback? onProgress,
  }) async {
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

  setUp(() {
    mockFirestoreService = MockFirestoreService();
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
  });

  Widget createTestWidget(
    List<Question> questions, {
    Key? key,
    String parentId = 'test_parent_id',
  }) {
    return ProviderScope(
      overrides: [
        questionsProvider(
          'test_prefix',
        ).overrideWith((ref) => Future.value(questions)),
        parentIdProvider.overrideWithValue(parentId),
        parentSettingsProvider.overrideWith(
          (ref) => Stream.value({'soundEffects': true}),
        ),
        firestoreServiceProvider.overrideWithValue(mockFirestoreService),
        sessionAssetPreloaderProvider.overrideWithValue(
          ImmediateSessionAssetPreloader(),
        ),
      ],
      child: MaterialApp(
        home: LevelSessionScreen(
          key: key,
          levelPrefix: 'test_prefix',
          childId: 'test_child_id',
          subjectId: 'bm',
          levelId: 'l1',
          showFeedbackMascot: false,
        ),
      ),
    );
  }

  const mockStrokeData =
      '{"strokes": ["M 0 0 L 10 10"], "medians": [[[0, 0], [10, 10]]]}';

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
      await tester.pumpAndSettle();

      expect(find.textContaining('What is this?'), findsOneWidget);
      expect(find.text('Option A Text'), findsOneWidget);
      expect(find.text('Option B Text'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      final scrollView = find.byKey(const ValueKey('level_session_scroll'));
      final questionContent = find.byKey(const ValueKey('question_content'));
      expect(
        (tester.getCenter(scrollView).dy - tester.getCenter(questionContent).dy)
            .abs(),
        lessThan(40),
      );
    });

    testWidgets('falls back to regular questions when review loading fails', (
      tester,
    ) async {
      when(
        () => mockFirestoreService.getReviewQuestions(
          any(),
          any(),
          subjectId: any(named: 'subjectId'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('Missing index'));

      final questions = [
        Question(
          id: 'test_prefix_q1',
          text: 'Fallback question',
          type: 'mcq',
          options: [
            QuestionOption(text: 'Correct'),
            QuestionOption(text: 'Wrong'),
          ],
          correctAnswerIndex: 0,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('fallback')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.textContaining('Fallback question'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
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
        await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();

        expect(
          find.text('Drag the correct word to the blank!'),
          findsOneWidget,
        );
        final sentence = tester.widget<RichText>(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Ini ') &&
                widget.text.toPlainText().contains(' buku.'),
          ),
        );
        expect(sentence.text.toPlainText(), contains('Ini '));
        expect(sentence.text.toPlainText(), contains(' buku.'));
        expect(find.byType(DragTarget<int>), findsOneWidget);
        expect(find.byType(Draggable<int>), findsNWidgets(2));
        final dropTargetSize = tester.getSize(
          find.byKey(const ValueKey('fillblank_drop_target')),
        );
        expect(dropTargetSize.width, greaterThan(100));
        expect(dropTargetSize.height, greaterThanOrEqualTo(28));
      },
    );

    testWidgets(
      'keeps a long Mandarin fillblank sentence inline on a narrow phone',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final questions = [
          Question(
            id: 'bc_c1_l4_q07',
            text: '他的兴趣爱好很广泛，平时最喜欢的事情就是（ ）。',
            type: 'fillblank',
            options: [
              QuestionOption(text: '做早操'),
              QuestionOption(text: '读书'),
              QuestionOption(text: '写字'),
            ],
            correctAnswerIndex: 1,
            correctBlank: '读书',
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            questions,
            key: const ValueKey('mandarin_fillblank'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DragTarget<int>), findsOneWidget);
        expect(tester.takeException(), isNull);
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
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should render and validate numeric input questions', (
      tester,
    ) async {
      final questions = [
        Question(
          id: 'math_q1',
          text: 'How many?',
          type: 'keyinnumber',
          options: const [],
          correctAnswerIndex: 0,
          correctNumber: 7,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('numeric')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('numeric_answer_input')),
        '7',
      );
      await tester.tap(find.text('Check Answer'));
      await tester.pumpAndSettle();

      expect(find.text('Correct!'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);
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
      await tester.pumpAndSettle();
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
      await tester.pumpAndSettle();

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
          strokeOrderDataJson: mockStrokeData,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('stroke_trace')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Trace 人'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('stroke_progress_markers')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('attempt_progress_markers')),
        findsOneWidget,
      );
    });

    testWidgets('matching keeps feedback and Finish anchored at the bottom', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 744));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final questions = [
        Question(
          id: 'q_matching',
          text: 'Match each word to its number',
          type: 'matching',
          options: [
            QuestionOption(text: 'One', pairText: '1'),
            QuestionOption(text: 'Two', pairText: '2'),
            QuestionOption(text: 'Three', pairText: '3'),
          ],
          correctAnswerIndex: 0,
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(questions, key: const ValueKey('matching')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Match each word to its number',
          findRichText: true,
        ),
        findsOneWidget,
      );

      for (final pair in [('One', '1'), ('Two', '2'), ('Three', '3')]) {
        await tester.ensureVisible(find.text(pair.$1));
        await tester.tap(find.text(pair.$1));
        await tester.ensureVisible(find.text(pair.$2));
        await tester.tap(find.text(pair.$2));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      final finishButton = find.widgetWithText(FilledButton, 'Finish');
      final feedback = find.byKey(const ValueKey('answer_feedback'));

      // In the redesigned feedback panel, the Finish button is inside the
      // unified feedback container. Verify both are present and the container
      // reaches near the bottom of the screen.
      expect(finishButton, findsOneWidget);
      expect(feedback, findsOneWidget);
      expect(tester.getBottomRight(feedback).dy, greaterThan(690));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should safely complete consecutive failed stroke tracing questions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 932));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final questions = [
          Question(
            id: 'q_stroke_1',
            text: 'Trace person one',
            type: 'stroke_trace',
            options: const [],
            correctAnswerIndex: 0,
            characterUnicode: '\u4eba',
            strokeOrderDataJson: mockStrokeData,
          ),
          Question(
            id: 'q_stroke_2',
            text: 'Trace person two',
            type: 'stroke_trace',
            options: const [],
            correctAnswerIndex: 0,
            characterUnicode: '\u4eba',
            strokeOrderDataJson: mockStrokeData,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(
            questions,
            key: const ValueKey('consecutive_stroke_trace'),
          ),
        );
        await tester.pumpAndSettle();

        Future<void> failCurrentTracingQuestion() async {
          for (var attempt = 0; attempt < 3; attempt++) {
            final tracingFinder = find.byType(StrokeTraceQuestion);
            expect(tracingFinder, findsOneWidget);
            final tracingState = tester.state<StrokeTraceQuestionState>(
              tracingFinder,
            );
            tracingState.simulateWrongStroke();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
            await tester.pumpAndSettle();

            if (attempt < 2) {
              await tester.pump(const Duration(milliseconds: 800));
              await tester.pumpAndSettle();
            }
          }
        }

        await failCurrentTracingQuestion();

        expect(tester.takeException(), isNull);
        expect(find.text('Incorrect!'), findsOneWidget);
        expect(find.text('Got it'), findsOneWidget);

        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));

        await failCurrentTracingQuestion();

        expect(tester.takeException(), isNull);
        expect(find.text('Incorrect!'), findsOneWidget);
        expect(find.text('Finish'), findsOneWidget);
      },
    );

    testWidgets(
      'should handle empty question pool gracefully with error message',
      (tester) async {
        await tester.pumpWidget(
          createTestWidget([], key: const ValueKey('empty')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('The question trail is quiet!'), findsOneWidget);
        expect(
          find.text(
            'No questions are ready for this level yet. '
            'Head back and explore another trail.',
          ),
          findsOneWidget,
        );
        expect(find.text('Back to the Trail'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      },
    );
  });
}
