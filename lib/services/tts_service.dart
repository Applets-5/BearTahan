import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  late final Future<void> _ready = _initTts();
  Future<void> _operationQueue = Future.value();

  Future<void> get ready => _ready;

  Future<void> _initTts() async {
    // Standard 1 students need slower, clearer speech
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(0.8);
    await _flutterTts.setPitch(1.0);

    if (Platform.isAndroid) {
      await _flutterTts.setQueueMode(1); // Play next after current finishes
    }

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      await _flutterTts.awaitSynthCompletion(true);
    }

    // Attempt to set a specifically Malaysian voice if available
    try {
      final voices = await _flutterTts.getVoices;
      for (var voice in voices) {
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

    await _enqueue(() async {
      await _ready;
      final lang = language ?? 'ms-MY';
      await _flutterTts.setLanguage(lang);
      await _flutterTts.speak(_sanitizeText(text, lang));
    });
  }

  Future<String?> preload(String text, {String? language}) async {
    if (text.trim().isEmpty || (!Platform.isAndroid && !Platform.isIOS)) {
      await _ready;
      return null;
    }

    return _enqueue(() async {
      await _ready;
      final lang = language ?? 'ms-MY';
      final file = await _cachedFile(text, lang);
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }

      await file.parent.create(recursive: true);
      await _flutterTts.setLanguage(lang);
      final result = await _flutterTts.synthesizeToFile(
        _sanitizeText(text, lang),
        file.path,
        true,
      );
      if (result == 1 && await file.exists() && await file.length() > 0) {
        return file.path;
      }
      return null;
    });
  }

  Future<String?> cachedAudioPath(String text, {String? language}) async {
    if (text.trim().isEmpty || (!Platform.isAndroid && !Platform.isIOS)) {
      return null;
    }
    final file = await _cachedFile(text, language ?? 'ms-MY');
    return await file.exists() && await file.length() > 0 ? file.path : null;
  }

  Future<File> _cachedFile(String text, String language) async {
    final cacheDirectory = await getTemporaryDirectory();
    final sanitized = _sanitizeText(text, language);
    final key = sha256
        .convert(utf8.encode('$language|0.45|0.8|1.0|$sanitized'))
        .toString();
    final extension = Platform.isIOS ? 'caf' : 'wav';
    return File(
      '${cacheDirectory.path}${Platform.pathSeparator}tts_prompts'
      '${Platform.pathSeparator}$key.$extension',
    );
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
    try {
      await _ready;
    } catch (error) {
      debugPrint('Unable to initialize TTS before stopping: $error');
    }
    try {
      await _flutterTts.stop();
    } catch (error) {
      debugPrint('Unable to stop TTS: $error');
    }
  }
}
