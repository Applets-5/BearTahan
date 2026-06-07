import 'package:bear_tahan/utils/sound_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sound effects default to enabled', () {
    expect(soundEffectsEnabled(null), isTrue);
    expect(soundEffectsEnabled({}), isTrue);
  });

  test('sound effects can be disabled from parent settings', () {
    expect(soundEffectsEnabled({'soundEffects': false}), isFalse);
    expect(soundEffectsEnabled({'soundEffects': true}), isTrue);
  });

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
