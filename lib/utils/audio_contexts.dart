import 'package:audioplayers/audioplayers.dart';

AudioContext promptAudioContext() {
  return AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();
}

AudioContext soundEffectAudioContext() {
  return AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );
}
