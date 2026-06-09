import 'package:bear_tahan/models/outfit_quest.dart';
import 'package:bear_tahan/models/user_profile.dart';
import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/screens/child/quests_screen.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late MockFirestoreService firestore;

  setUp(() {
    firestore = MockFirestoreService();
    when(
      () => firestore.evaluateAndUpdateQuestProgress(any(), any()),
    ).thenAnswer((_) async => const []);
  });

  testWidgets('quest cards do not overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/quests',
      routes: [
        GoRoute(
          path: '/quests',
          builder: (context, state) =>
              const QuestsScreen(childId: 'test-child'),
        ),
      ],
    );
    addTearDown(router.dispose);

    final profile = UserProfile(
      uid: 'test-child',
      name: 'Aiden',
      lifetimeStarsEarned: 20,
      availableStars: 10,
      activeMascotOutfit: 'scholar_bear',
    );
    final progress = {
      'chef_bear': const OutfitQuestProgress(
        outfitId: 'chef_bear',
        currentValue: 5,
        targetValue: 5,
        isUnlocked: true,
      ),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider.overrideWithValue(firestore),
          parentIdProvider.overrideWithValue('test-parent'),
          outfitQuestsProvider.overrideWith(
            (ref) => Stream.value(OutfitQuest.defaults),
          ),
          questProgressProvider.overrideWith(
            (ref, arg) => Stream.value(progress),
          ),
          userProfileProvider.overrideWith(
            (ref, childId) => Stream.value(profile),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chef Bear'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
