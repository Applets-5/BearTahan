import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/question.dart';
import 'tts_service.dart';

typedef PreparationProgressCallback = void Function(int completed, int total);
typedef QuestionImagePreloader =
    Future<void> Function(String url, BuildContext context);
typedef RemoteAudioPreloader = Future<void> Function(String url);

class SessionPreparationReport {
  const SessionPreparationReport({
    required this.completedAssets,
    required this.totalAssets,
    required this.failedAssets,
    required this.timedOut,
  });

  final int completedAssets;
  final int totalAssets;
  final int failedAssets;
  final bool timedOut;
}

class SessionAssetPreloader {
  SessionAssetPreloader({
    required TtsService ttsService,
    BaseCacheManager? cacheManager,
    QuestionImagePreloader? imagePreloader,
    RemoteAudioPreloader? remoteAudioPreloader,
  }) : _ttsService = ttsService,
       _cacheManager = cacheManager ?? DefaultCacheManager(),
       _remoteAudioPreloader = remoteAudioPreloader,
       _imagePreloader =
           imagePreloader ??
           ((url, context) => precacheImage(NetworkImage(url), context));

  final TtsService _ttsService;
  final BaseCacheManager _cacheManager;
  final QuestionImagePreloader _imagePreloader;
  final RemoteAudioPreloader? _remoteAudioPreloader;

  Future<SessionPreparationReport> preload({
    required BuildContext context,
    required List<Question> questions,
    required String Function(Question question) languageForQuestion,
    Duration timeout = const Duration(seconds: 10),
    PreparationProgressCallback? onProgress,
  }) async {
    if (questions.isEmpty) {
      return const SessionPreparationReport(
        completedAssets: 0,
        totalAssets: 0,
        failedAssets: 0,
        timedOut: false,
      );
    }

    final imageUrls = <String>{};
    final remoteAudioUrls = <String>{};
    final ttsPrompts = <_TtsPrompt>{};
    final firstQuestionImages = <String>{};
    final firstQuestionAudio = <String>{};
    final firstQuestionTts = <_TtsPrompt>{};

    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      final questionImages = <String>{};
      _addUrl(imageUrls, question.imageUrl);
      _addUrl(questionImages, question.imageUrl);
      for (final option in question.options) {
        _addUrl(imageUrls, option.imageUrl);
        _addUrl(imageUrls, option.pairImageUrl);
        _addUrl(questionImages, option.imageUrl);
        _addUrl(questionImages, option.pairImageUrl);
      }
      if (index == 0) firstQuestionImages.addAll(questionImages);

      if (_isUsableUrl(question.promptAudioUrl)) {
        remoteAudioUrls.add(question.promptAudioUrl!);
        if (index == 0) firstQuestionAudio.add(question.promptAudioUrl!);
      } else {
        final text = question.promptAudioText ?? question.text;
        if (text.trim().isNotEmpty) {
          final prompt = _TtsPrompt(
            text: text,
            language: languageForQuestion(question),
          );
          ttsPrompts.add(prompt);
          if (index == 0) firstQuestionTts.add(prompt);
        }
      }
    }

    final total = imageUrls.length + remoteAudioUrls.length + ttsPrompts.length;
    if (total == 0) {
      return const SessionPreparationReport(
        completedAssets: 0,
        totalAssets: 0,
        failedAssets: 0,
        timedOut: false,
      );
    }
    onProgress?.call(0, total);

    var completed = 0;
    var failed = 0;
    var timedOut = false;
    var acceptingWork = true;

    void recordCompletion(bool succeeded) {
      if (!acceptingWork) return;
      completed++;
      if (!succeeded) failed++;
      onProgress?.call(completed, total);
    }

    Future<void> prepareImage(String url) async {
      try {
        await _imagePreloader(url, context);
        recordCompletion(true);
      } catch (error) {
        debugPrint('Unable to preload question image $url: $error');
        recordCompletion(false);
      }
    }

    Future<void> prepareRemoteAudio(String url) async {
      try {
        final preloader = _remoteAudioPreloader;
        if (preloader != null) {
          await preloader(url);
        } else {
          await _cacheManager.getSingleFile(url);
        }
        recordCompletion(true);
      } catch (error) {
        debugPrint('Unable to preload prompt audio $url: $error');
        recordCompletion(false);
      }
    }

    Future<void> prepareTts(_TtsPrompt prompt) async {
      try {
        final path = await _ttsService.preload(
          prompt.text,
          language: prompt.language,
        );
        recordCompletion(path != null);
      } catch (error) {
        debugPrint('Unable to preload TTS prompt: $error');
        recordCompletion(false);
      }
    }

    final stopwatch = Stopwatch()..start();
    Future<void> prepareBatch(
      Set<String> images,
      Set<String> audio,
      Set<_TtsPrompt> prompts,
    ) {
      return Future.wait<void>([
        ...images.map(prepareImage),
        ...audio.map(prepareRemoteAudio),
        _prepareTtsPrompts(
          prompts,
          prepareTts,
          stopwatch: stopwatch,
          timeout: timeout,
        ),
      ]);
    }

    try {
      await prepareBatch(
        firstQuestionImages,
        firstQuestionAudio,
        firstQuestionTts,
      ).timeout(timeout);

      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) throw TimeoutException('Timed out');

      await prepareBatch(
        imageUrls.difference(firstQuestionImages),
        remoteAudioUrls.difference(firstQuestionAudio),
        ttsPrompts.difference(firstQuestionTts),
      ).timeout(remaining);
    } on TimeoutException {
      timedOut = true;
      acceptingWork = false;
      debugPrint(
        'Session asset preparation timed out after ${timeout.inSeconds}s.',
      );
    }

    return SessionPreparationReport(
      completedAssets: completed,
      totalAssets: total,
      failedAssets: failed,
      timedOut: timedOut,
    );
  }

  Future<void> _prepareTtsPrompts(
    Iterable<_TtsPrompt> prompts,
    Future<void> Function(_TtsPrompt prompt) prepare, {
    required Stopwatch stopwatch,
    required Duration timeout,
  }) async {
    for (final prompt in prompts) {
      final remaining = timeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) return;
      try {
        await prepare(prompt).timeout(remaining);
      } on TimeoutException {
        return;
      }
    }
  }

  static void _addUrl(Set<String> urls, String? value) {
    if (_isUsableUrl(value)) urls.add(value!);
  }

  static bool _isUsableUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class _TtsPrompt {
  const _TtsPrompt({required this.text, required this.language});

  final String text;
  final String language;

  @override
  bool operator ==(Object other) {
    return other is _TtsPrompt &&
        other.text == text &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(text, language);
}
