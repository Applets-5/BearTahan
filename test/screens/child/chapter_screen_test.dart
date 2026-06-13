import 'dart:async';

import 'package:bear_tahan/providers/data_providers.dart';
import 'package:bear_tahan/screens/child/chapter_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const progressArgs = (
    childId: 'child-1',
    subjectId: 'bm',
    levelId: 'c1_summary',
  );
  const starsArgs = (childId: 'child-1', subjectId: 'bm');

  Widget buildScreen({
    required Future<Map<String, dynamic>> Function() progress,
  }) {
    return ProviderScope(
      overrides: [
        levelStarsProvider(
          starsArgs,
        ).overrideWith((ref) => Stream.value({'c1_summary': 0})),
        levelProgressProvider(progressArgs).overrideWith((ref) => progress()),
      ],
      child: const MaterialApp(
        home: ChapterScreen(
          childId: 'child-1',
          subjectId: 'bm',
          chapterId: 'c1',
        ),
      ),
    );
  }

  testWidgets('shows the saved summary threshold', (tester) async {
    await tester.pumpWidget(
      buildScreen(progress: () async => {'summaryThreshold': 2}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Goal: 100% to earn a star'), findsOneWidget);
  });

  testWidgets('shows progress loading and error states', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(buildScreen(progress: () => pending.future));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Error loading chapter progress'),
      findsOneWidget,
    );
  });

  testWidgets('does not recreate progress loading during rebuilds', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      buildScreen(
        progress: () async {
          calls++;
          return {'summaryThreshold': 1};
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();

    expect(calls, 1);
    expect(find.text('Goal: 90% to earn a star'), findsOneWidget);
  });
}
