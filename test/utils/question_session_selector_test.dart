import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/utils/question_session_selector.dart';
import 'package:flutter_test/flutter_test.dart';

Question question(String id, String type) => Question(
  id: id,
  text: id,
  type: type,
  options: const [],
  correctAnswerIndex: 0,
);

void main() {
  test(
    'Mandarin L4 keeps all exercises and fills remaining slots with tracing',
    () {
      final questions = [
        for (var index = 0; index < 15; index++)
          question('trace_$index', 'stroke_trace'),
        for (var index = 0; index < 3; index++)
          question('fill_$index', 'fillblank'),
        for (var index = 0; index < 2; index++)
          question('rearrange_$index', 'rearrange'),
        question('matching', 'matching'),
      ];

      final selected = selectBalancedMandarinL4Questions(questions, count: 10);

      expect(selected, hasLength(10));
      expect(
        selected.where((item) => item.type != 'stroke_trace'),
        hasLength(6),
      );
      expect(
        selected.where((item) => item.type == 'stroke_trace'),
        hasLength(4),
      );
    },
  );

  test('review injection count reduces tracing before dropping exercises', () {
    final questions = [
      for (var index = 0; index < 15; index++)
        question('trace_$index', 'stroke_trace'),
      for (var index = 0; index < 6; index++)
        question('exercise_$index', 'mcq'),
    ];

    final selected = selectBalancedMandarinL4Questions(questions, count: 8);

    expect(selected.where((item) => item.type != 'stroke_trace'), hasLength(6));
    expect(selected.where((item) => item.type == 'stroke_trace'), hasLength(2));
  });
}
