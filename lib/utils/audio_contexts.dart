import 'package:audioplayers/audioplayers.dart';

AudioContext promptAudioContext() {
  return AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();
}

AudioContext soundEffectAudioContext() {
  return AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );
}
