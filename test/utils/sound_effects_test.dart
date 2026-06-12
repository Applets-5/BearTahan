import 'package:bear_tahan/utils/sound_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stroke tracing suppresses full-question feedback', () {
    expect(shouldPlayQuestionFeedback('stroke_trace'), isFalse);
    expect(shouldPlayQuestionFeedback('STROKE_TRACE'), isFalse);
    expect(shouldPlayQuestionFeedback('mcq'), isTrue);
  });

  test('stroke tracing can explicitly play completion feedback', () {
    expect(
      shouldPlayQuestionFeedback('stroke_trace', allowStrokeTrace: true),
      isTrue,
    );
  });
}
