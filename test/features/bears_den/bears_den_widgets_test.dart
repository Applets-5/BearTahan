import 'package:bear_tahan/features/bears_den/bears_den_cave_node.dart';
import 'package:bear_tahan/features/bears_den/chapter_insights_card.dart';
import 'package:bear_tahan/models/chapter_data.dart';
import 'package:bear_tahan/models/bears_den_result.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/models/session_mode.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/providers/sound_effects_provider.dart';
import 'package:bear_tahan/screens/child/completion_screen.dart';
import 'package:bear_tahan/screens/child/level_session_screen.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/services/session_asset_preloader.dart';
import 'package:bear_tahan/services/tts_service.dart';
import 'package:bear_tahan/widgets/common/level_winding_path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockTtsService extends Mock implements TtsService {}

class ImmediateSessionAssetPreloader extends SessionAssetPreloader {
  ImmediateSessionAssetPreloader() : super(ttsService: MockTtsService());

  @override
  Future<SessionPreparationReport> preload({
    required BuildContext context,
    required List<Question> questions,
    required String Function(Question question) languageForQuestion,
    Duration timeout = const Duration(seconds: 10),
    PreparationProgressCallback? onProgress,
  }) async {
    return const SessionPreparationReport(
      completedAssets: 0,
      totalAssets: 0,
      failedAssets: 0,
      timedOut: false,
    );
  }
}

Question question(String id) => Question(
  id: id,
  text: 'Choose the answer',
  type: 'mcq',
  options: ['Correct', 'Wrong'],
  correctAnswerIndex: 0,
);

List<Question> bearsDenQuestions() {
  return [
    for (var index = 0; index < 2; index++)
      question('bi_c0_l1_q${index.toString().padLeft(2, '0')}'),
    for (var index = 0; index < 6; index++)
      question('bi_c1_l1_q${index.toString().padLeft(2, '0')}'),
    for (var index = 0; index < 4; index++)
      question('bi_c2_l1_q${index.toString().padLeft(2, '0')}'),
  ];
}

void main() {
  testWidgets('renders the Golden Cave and Chapter Insights card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              BearsDenCaveNode(onTap: () {}, stars: 1),
              const ChapterInsightsCard(),
            ],
          ),
        ),
      ),
    );

    expect(find.text("Bear's Den"), findsOneWidget);
    expect(find.text('Chapter Mix'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    final cave = find.byType(BearsDenCaveNode);
    expect(
      find.descendant(of: cave, matching: find.byIcon(Icons.star_rounded)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: cave,
        matching: find.byIcon(Icons.star_outline_rounded),
      ),
      findsOneWidget,
    );
    expect(find.text('Chapter Insights'), findsOneWidget);
    expect(find.text('Needs Work'), findsOneWidget);
  });

  testWidgets('shows Bear Den identity and skips normal question writes', (
    tester,
  ) async {
    final service = MockFirestoreService();
    final questions = bearsDenQuestions();

    when(
      () => service.completeBearsDenSession(
        any(),
        any(),
        score: any(named: 'score'),
        total: any(named: 'total'),
      ),
    ).thenAnswer(
      (_) async => const BearsDenResult(
        performanceStars: 2,
        awardedStars: 2,
        status: BearsDenAwardStatus.awarded,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(service),
          parentIdProvider.overrideWithValue('parent'),
          bearsDenQuestionsProvider.overrideWith((ref) async => questions),
          parentSettingsProvider.overrideWith(
            (ref) => Stream.value({'soundEffects': false}),
          ),
          soundEffectsProvider.overrideWith(
            () => _DisabledSoundEffectsNotifier(),
          ),
          sessionAssetPreloaderProvider.overrideWithValue(
            ImmediateSessionAssetPreloader(),
          ),
        ],
        child: const MaterialApp(
          home: LevelSessionScreen(
            childId: 'child',
            subjectId: 'bi',
            levelId: 'bears_den',
            levelPrefix: 'bi_',
            sessionMode: SessionMode.bearsDen,
            showFeedbackMascot: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Bear's Den"), findsOneWidget);
    expect(find.textContaining('Chapter '), findsOneWidget);

    await tester.tap(find.text('Correct'));
    await tester.pumpAndSettle();

    verifyNever(() => service.updateQuestionStats(any(), any(), any(), any()));
    verifyNever(
      () =>
          service.updateLevelProgress(any(), any(), any(), any(), any(), any()),
    );
  });

  testWidgets('renders Bear Den independently above Chapter 2 Level 5', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            child: LevelWindingPath(
              starMap: const {},
              chapters: [
                ChapterData(
                  id: 'c0',
                  name: 'Chapter 0',
                  levelIds: const ['c0_l1', 'c0_l2', 'c0_l3', 'c0_summary'],
                ),
                ChapterData(
                  id: 'c1',
                  name: 'Chapter 1',
                  levelIds: const [
                    'c1_l1',
                    'c1_l2',
                    'c1_l3',
                    'c1_l4',
                    'c1_l5',
                    'c1_l6',
                    'c1_summary',
                  ],
                ),
                ChapterData(
                  id: 'c2',
                  name: 'Chapter 2',
                  levelIds: const [
                    'c2_l1',
                    'c2_l2',
                    'c2_l3',
                    'c2_l4',
                    'c2_l5',
                    'c2_l6',
                    'c2_summary',
                  ],
                ),
              ],
              subjectId: 'bi',
              onLevelTap: (_, _, _) {},
              onBearsDenTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final customPaints = tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    );
    final mainPath = customPaints
        .map((paint) => paint.painter)
        .whereType<PathPainter>()
        .single;

    expect(mainPath.points, hasLength(18));
    expect(
      customPaints.map((paint) => paint.painter).whereType<PathPainter>(),
      hasLength(1),
    );
    final cave = find.byType(BearsDenCaveNode);
    final levelFive = find.text('Level 5').last;
    expect(cave, findsOneWidget);
    expect(
      tester.getCenter(cave).dx,
      greaterThan(tester.getCenter(levelFive).dx),
    );
    expect(tester.getCenter(cave).dy, lessThan(tester.getCenter(levelFive).dy));
  });

  testWidgets('falls back beside the last regular Chapter 2 level', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 430,
            child: LevelWindingPath(
              starMap: const {},
              chapters: [
                ChapterData(
                  id: 'c2',
                  name: 'Chapter 2',
                  levelIds: const ['c2_l1', 'c2_l2', 'c2_l3', 'c2_summary'],
                ),
              ],
              subjectId: 'bi',
              onLevelTap: (_, _, _) {},
              onBearsDenTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final cave = find.byType(BearsDenCaveNode);
    final lastRegularLevel = find.text('Level 3');
    expect(cave, findsOneWidget);
    expect(
      tester.getCenter(cave).dx,
      lessThan(tester.getCenter(lastRegularLevel).dx),
    );
    expect(
      tester.getCenter(cave).dy,
      lessThan(tester.getCenter(lastRegularLevel).dy),
    );
  });

  testWidgets('completion presents two reward slots and wallet result', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(MockFirebaseAuth()),
          soundEffectsProvider.overrideWith(
            () => _DisabledSoundEffectsNotifier(),
          ),
        ],
        child: const MaterialApp(
          home: CompletionScreen(
            childId: 'child',
            subjectId: 'bi',
            levelId: 'bears_den',
            score: 12,
            total: 12,
            performanceStars: 2,
            newStarsAwarded: 2,
            sessionMode: SessionMode.bearsDen,
            bearsDenAwardStatus: BearsDenAwardStatus.awarded,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text("Bear's Den Complete!"), findsOneWidget);
    expect(find.text("Today's reward"), findsOneWidget);
    expect(find.text('+2 stars added to your wallet!'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(2));
  });
}

class _DisabledSoundEffectsNotifier extends SoundEffectsNotifier {
  @override
  Future<bool> build() async => false;
}
