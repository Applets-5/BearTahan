import 'dart:async';

import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/services/session_asset_preloader.dart';
import 'package:bear_tahan/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTtsService extends Mock implements TtsService {}

void main() {
  late MockTtsService ttsService;

  setUp(() {
    ttsService = MockTtsService();
  });

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (builderContext) {
            context = builderContext;
            return const SizedBox();
          },
        ),
      ),
    );
    return context;
  }

  testWidgets('deduplicates and preloads all selected question assets', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final imageOrder = <String>[];
    final audioOrder = <String>[];

    when(
      () => ttsService.preload(any(), language: any(named: 'language')),
    ).thenAnswer((_) async => 'cached.wav');

    final preloader = SessionAssetPreloader(
      ttsService: ttsService,
      imagePreloader: (url, _) async => imageOrder.add(url),
      remoteAudioPreloader: (url) async => audioOrder.add(url),
    );
    final questions = [
      Question(
        id: 'bm_c1_l1_q1',
        text: 'First',
        imageUrl: 'https://example.com/first.png',
        promptAudioUrl: 'https://example.com/first.mp3',
        options: [
          {
            'text': 'A',
            'imageUrl': 'https://example.com/option.png',
            'pairImageUrl': 'https://example.com/pair.png',
          },
        ],
        correctAnswerIndex: 0,
      ),
      Question(
        id: 'bi_c1_l1_q2',
        text: 'Second',
        imageUrl: 'https://example.com/first.png',
        promptAudioText: 'Read the second question',
        options: [
          {'text': 'B', 'imageUrl': 'https://example.com/second.png'},
        ],
        correctAnswerIndex: 0,
      ),
    ];

    final progress = <(int, int)>[];
    final report = await preloader.preload(
      context: context,
      questions: questions,
      languageForQuestion: (question) =>
          question.id.startsWith('bm_') ? 'ms-MY' : 'en-GB',
      onProgress: (completed, total) => progress.add((completed, total)),
    );

    expect(report.totalAssets, 6);
    expect(report.completedAssets, 6);
    expect(report.failedAssets, 0);
    expect(report.timedOut, isFalse);
    expect(imageOrder.toSet(), {
      'https://example.com/first.png',
      'https://example.com/option.png',
      'https://example.com/pair.png',
      'https://example.com/second.png',
    });
    expect(
      imageOrder.indexOf('https://example.com/second.png'),
      greaterThan(imageOrder.indexOf('https://example.com/pair.png')),
    );
    expect(audioOrder, ['https://example.com/first.mp3']);
    verify(
      () => ttsService.preload('Read the second question', language: 'en-GB'),
    ).called(1);
    expect(progress.first, (0, 6));
    expect(progress.last, (6, 6));
  });

  testWidgets('returns after timeout when TTS preparation stalls', (
    tester,
  ) async {
    final context = await pumpContext(tester);
    final stalled = Completer<String?>();
    when(
      () => ttsService.preload(any(), language: any(named: 'language')),
    ).thenAnswer((_) => stalled.future);

    final preloader = SessionAssetPreloader(
      ttsService: ttsService,
      imagePreloader: (_, _) async {},
      remoteAudioPreloader: (_) async {},
    );

    final report = await preloader.preload(
      context: context,
      questions: [
        Question(
          id: 'bm_c1_l1_q1',
          text: 'Slow prompt',
          options: ['A'],
          correctAnswerIndex: 0,
        ),
      ],
      languageForQuestion: (_) => 'ms-MY',
      timeout: const Duration(milliseconds: 20),
    );

    expect(report.timedOut, isTrue);
    expect(report.completedAssets, 0);
    expect(report.totalAssets, 1);
  });
}
