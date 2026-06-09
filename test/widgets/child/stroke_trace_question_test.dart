import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/theme/app_theme.dart';
import 'package:bear_tahan/widgets/child/stroke_trace_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Question createQuestion({String? strokeOrderDataJson}) {
    return Question(
      id: 'trace_ren',
      text: 'Trace person',
      type: 'stroke_trace',
      options: const [],
      correctAnswerIndex: 0,
      characterUnicode: '\u4eba',
      strokeOrderDataJson: strokeOrderDataJson,
    );
  }

  Widget createWidget({
    GlobalKey<StrokeTraceQuestionState>? tracingKey,
    Question? question,
    ValueChanged<bool>? onComplete,
    VoidCallback? onWrongAttempt,
    ValueChanged<int>? onCorrectStroke,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: StrokeTraceQuestion(
            key: tracingKey,
            question: question ?? createQuestion(),
            onComplete: onComplete ?? (_) {},
            onWrongAttempt: onWrongAttempt ?? () {},
            onCorrectStroke: onCorrectStroke,
          ),
        ),
      ),
    );
  }

  Future<void> loadWidget(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> triggerWrongStroke(
    WidgetTester tester,
    GlobalKey<StrokeTraceQuestionState> tracingKey,
  ) async {
    tracingKey.currentState!.simulateWrongStroke();
    await tester.pump();
  }

  testWidgets('shows compact stroke and attempt markers', (tester) async {
    await loadWidget(tester, createWidget());

    expect(find.text('Strokes'), findsOneWidget);
    expect(find.text('Attempts'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('progress_label_strokes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('progress_label_attempts')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stroke_progress_markers')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('attempt_progress_markers')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('attempt_marker_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('attempt_marker_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('attempt_marker_2')), findsOneWidget);
  });

  testWidgets('reports the zero-based accepted stroke index', (tester) async {
    int? reportedIndex;
    final tracingKey = GlobalKey<StrokeTraceQuestionState>();
    await loadWidget(
      tester,
      createWidget(
        tracingKey: tracingKey,
        onCorrectStroke: (index) => reportedIndex = index,
      ),
    );

    tracingKey.currentState!.simulateCorrectStroke(1);

    expect(reportedIndex, 1);
  });

  testWidgets('locks input and shows immediate feedback after a wrong stroke', (
    tester,
  ) async {
    var wrongAttempts = 0;
    final tracingKey = GlobalKey<StrokeTraceQuestionState>();
    await loadWidget(
      tester,
      createWidget(
        tracingKey: tracingKey,
        onWrongAttempt: () => wrongAttempts++,
      ),
    );

    await triggerWrongStroke(tester, tracingKey);

    expect(wrongAttempts, 1);
    expect(find.text('Try again from stroke 1!'), findsOneWidget);
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('stroke_input_blocker')),
          )
          .ignoring,
      isTrue,
    );

    final canvas = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('stroke_canvas_feedback')),
    );
    final decoration = canvas.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.destructiveLight);

    await tester.pump(const Duration(milliseconds: 700));

    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('stroke_input_blocker')),
          )
          .ignoring,
      isFalse,
    );
  });

  testWidgets(
    'reveals the character and completes false after three failures',
    (tester) async {
      bool? result;
      final tracingKey = GlobalKey<StrokeTraceQuestionState>();
      await loadWidget(
        tester,
        createWidget(
          tracingKey: tracingKey,
          onComplete: (value) => result = value,
        ),
      );

      for (var attempt = 0; attempt < 3; attempt++) {
        await triggerWrongStroke(tester, tracingKey);
        if (attempt < 2) {
          await tester.pump(const Duration(milliseconds: 700));
        }
      }
      await tester.pump(const Duration(milliseconds: 400));

      expect(result, isFalse);
      expect(
        find.text('The correct character is shown. Try again later.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const ValueKey('stroke_input_blocker')),
            )
            .ignoring,
        isTrue,
      );
    },
  );

  test('uses text progress for characters with more than six strokes', () {
    expect(StrokeTraceQuestionState.usesStrokeMarkers(6), isTrue);
    expect(StrokeTraceQuestionState.usesStrokeMarkers(7), isFalse);
  });
}
