import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bear_tahan/screens/child/completion_screen.dart';

void main() {
  group('_calculateStars', () {
    test('should return 3 stars for a perfect score (100%)', () {
      const screen = CompletionScreen(score: 10, total: 10);
      final state = screen.createState() as dynamic;
      
      expect(state.calculateStars(), 3);
    });

    test('should return 2 stars for a score of 80% or above but less than 100%', () {
      const screen = CompletionScreen(score: 8, total: 10);
      final state = screen.createState() as dynamic;
      
      expect(state.calculateStars(), 2);
    });

    test('should return 1 star for a score of 50% or above but less than 80%', () {
      const screen = CompletionScreen(score: 5, total: 10);
      final state = screen.createState() as dynamic;
      
      expect(state.calculateStars(), 1);
    });

    test('should return 0 stars for a score below 50%', () {
      const screen = CompletionScreen(score: 4, total: 10);
      final state = screen.createState() as dynamic;
      
      expect(state.calculateStars(), 0);
    });

    test('should return 0 stars if the total number of questions is 0', () {
      const screen = CompletionScreen(score: 0, total: 0);
      final state = screen.createState() as dynamic;
      
      expect(state.calculateStars(), 0);
    });
  });

  group('_saveProgress', () {
    testWidgets('should transition _saved to true after calling _saveProgress', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CompletionScreen(
              childId: 'test_child',
              score: 10,
              total: 10,
            ),
          ),
        ),
      );

      final state = tester.state(find.byType(CompletionScreen)) as dynamic;
      
      expect(state.saved, isTrue);
    });
  });
}

extension on State<CompletionScreen> {
  int calculateStars() {
    final dynamicState = this as dynamic;
    return dynamicState._calculateStars();
  }
  
  bool get saved {
    final dynamicState = this as dynamic;
    return dynamicState._saved;
  }
}
