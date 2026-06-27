import 'package:audioplayers/audioplayers.dart';

const double answerFeedbackVolume = 0.60;
const double levelResultVolume = 0.60;

String levelResultAudioPath({
  required bool isReviewSession,
  required int performanceStars,
}) {
  return isReviewSession || performanceStars > 0
      ? 'audio/levelPassed.mp3'
      : 'audio/levelFailed.mp3';
}

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
