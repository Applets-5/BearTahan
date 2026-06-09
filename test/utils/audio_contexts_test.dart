import 'package:audioplayers/audioplayers.dart';
import 'package:bear_tahan/utils/audio_contexts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prompt audio context allows other app audio to keep playing', () {
    final context = promptAudioContext();

    expect(context.android.audioFocus, AndroidAudioFocus.none);
  });

  test('sound effect audio context does not interrupt prompt audio', () {
    final context = soundEffectAudioContext();

    expect(context.android.audioFocus, AndroidAudioFocus.none);
    expect(context.android.contentType, AndroidContentType.sonification);
    expect(context.android.usageType, AndroidUsageType.assistanceSonification);
    expect(context.iOS.options, contains(AVAudioSessionOptions.mixWithOthers));
  });
}
