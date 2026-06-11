import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bear_tahan/screens/child/completion_screen.dart';
import 'package:bear_tahan/theme/app_theme.dart';

import 'package:bear_tahan/providers/data_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late MockFirebaseAuth mockAuth;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  Widget createWidget({
    int score = 0,
    int total = 0,
    int? performanceStars,
    int? newStarsAwarded,
  }) {
    return ProviderScope(
      overrides: [firebaseAuthProvider.overrideWithValue(mockAuth)],
      child: MaterialApp(
        home: CompletionScreen(
          score: score,
          total: total,
          childId: 'demo_child_001',
          performanceStars: performanceStars,
          newStarsAwarded:
              newStarsAwarded ?? (score == total && total > 0 ? 3 : 0),
        ),
      ),
    );
  }

  group('CompletionScreen Stars', () {
    testWidgets('should show 3 stars for a perfect score (100%)', (
      tester,
    ) async {
      await tester.pumpWidget(createWidget(score: 10, total: 10));
      await tester.pumpAndSettle();

      final starIcons = find.byIcon(Icons.star);
      expect(starIcons, findsNWidgets(3));

      final coloredStars = tester
          .widgetList<Icon>(starIcons)
          .where((icon) => icon.color == AppColors.star);
      expect(coloredStars.length, 3);
    });

    testWidgets('should show 2 stars for a score of 80%', (tester) async {
      await tester.pumpWidget(createWidget(score: 8, total: 10));
      await tester.pumpAndSettle();

      final starIcons = find.byIcon(Icons.star);
      final coloredStars = tester
          .widgetList<Icon>(starIcons)
          .where((icon) => icon.color == AppColors.star);
      expect(coloredStars.length, 2);
    });

    testWidgets('should show 1 star for a score of 50%', (tester) async {
      await tester.pumpWidget(createWidget(score: 5, total: 10));
      await tester.pumpAndSettle();

      final starIcons = find.byIcon(Icons.star);
      final coloredStars = tester
          .widgetList<Icon>(starIcons)
          .where((icon) => icon.color == AppColors.star);
      expect(coloredStars.length, 1);
    });

    testWidgets('should show 0 stars for a score below 50%', (tester) async {
      await tester.pumpWidget(createWidget(score: 4, total: 10));
      await tester.pumpAndSettle();

      final starIcons = find.byIcon(Icons.star);
      final coloredStars = tester
          .widgetList<Icon>(starIcons)
          .where((icon) => icon.color == AppColors.star);
      expect(coloredStars.length, 0);
    });

    testWidgets('shows no-new-stars message for a completed replay', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidget(
          score: 8,
          total: 10,
          performanceStars: 2,
          newStarsAwarded: 0,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Stage complete. No new wallet stars this time.'),
        findsOneWidget,
      );
    });
  });
}
