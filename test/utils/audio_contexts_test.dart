import 'package:audioplayers/audioplayers.dart';
import 'package:bear_tahan/utils/audio_contexts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quiz answer and level result sounds use matching volume', () {
    expect(answerFeedbackVolume, 0.60);
    expect(levelResultVolume, 0.60);
  });

  test('level result audio selects pass, fail, and review assets', () {
    expect(
      levelResultAudioPath(isReviewSession: false, performanceStars: 1),
      'audio/levelPassed.mp3',
    );
    expect(
      levelResultAudioPath(isReviewSession: false, performanceStars: 0),
      'audio/levelFailed.mp3',
    );
    expect(
      levelResultAudioPath(isReviewSession: true, performanceStars: 0),
      'audio/levelPassed.mp3',
    );
  });

  test('prompt audio context allows other app audio to keep playing', () {
    final context = promptAudioContext();

    expect(context.android.audioFocus, AndroidAudioFocus.none);
  });

  test('sound effects use media volume and respect silent mode', () {
    final context = soundEffectAudioContext();

    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.android.contentType, AndroidContentType.music);
    expect(context.android.usageType, AndroidUsageType.media);
    expect(context.iOS.category, AVAudioSessionCategory.ambient);
    expect(context.iOS.options, isEmpty);
  });
}
