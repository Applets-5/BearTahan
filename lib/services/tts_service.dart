import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // Standard 1 students need slower, clearer speech
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    if (Platform.isAndroid) {
      await _flutterTts.setQueueMode(1); // Play next after current finishes
    }

    // Attempt to set a specifically Malaysian voice if available
    try {
      final voices = await _flutterTts.getVoices;
      for (var voice in voices) {
        final String name = voice['name']?.toString().toLowerCase() ?? '';
        final String locale = voice['locale']?.toString().toLowerCase() ?? '';

        // Priority for ms-my locale with natural sounding tags
        if (locale.contains('ms-my')) {
          await _flutterTts.setVoice({
            "name": voice["name"],
            "locale": voice["locale"],
          });
          break;
        }
      }
    } catch (e) {
      debugPrint('Error fetching/setting local voice: $e');
    }
  }

  Future<void> speak(String text, {String? language}) async {
    if (text.isEmpty) return;

    // Default to ms-MY for this project context
    final lang = language ?? 'ms-MY';
    await _flutterTts.setLanguage(lang);

    // Sanitize text: replace underscores with a spoken placeholder
    String sanitizedText = _sanitizeText(text, lang);

    await _flutterTts.speak(sanitizedText);
  }

  String _sanitizeText(String text, String lang) {
    // Regex to find 2 or more underscores
    final RegExp underscorePattern = RegExp(r'_{2,}');

    String replacement;
    final normalizedLang = lang.toLowerCase();

    if (normalizedLang.contains('ms') || normalizedLang.contains('my')) {
      replacement = 'tempat kosong';
    } else if (normalizedLang.contains('zh')) {
      replacement = 'kòng gé'; // Mandarin for blank/space
    } else {
      replacement = 'blank';
    }

    return text.replaceAll(underscorePattern, replacement);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
