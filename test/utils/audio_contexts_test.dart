import 'package:audioplayers/audioplayers.dart';
import 'package:bear_tahan/utils/audio_contexts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
