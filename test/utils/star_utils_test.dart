import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/utils/star_utils.dart';

void main() {
  group('StarUtils.calculateStars', () {
    test('Standard level: 100% score should give 3 stars', () {
      final stars = StarUtils.calculateStars(
        score: 10,
        total: 10,
        levelId: 'l1',
      );
      expect(stars, 3);
    });

    test('Standard level: 80% score should give 2 stars', () {
      final stars = StarUtils.calculateStars(
        score: 8,
        total: 10,
        levelId: 'l1',
      );
      expect(stars, 2);
    });

    test('Standard level: 50% score should give 1 star', () {
      final stars = StarUtils.calculateStars(
        score: 5,
        total: 10,
        levelId: 'l1',
      );
      expect(stars, 1);
    });

    test('Standard level: <50% score should give 0 stars', () {
      final stars = StarUtils.calculateStars(
        score: 4,
        total: 10,
        levelId: 'l1',
      );
      expect(stars, 0);
    });

    test('Stricter stage (summary): 100% score should give 3 stars', () {
      final stars = StarUtils.calculateStars(
        score: 10,
        total: 10,
        levelId: 'summary_1',
      );
      expect(stars, 3);
    });

    test('Stricter stage (summary): 90% score should give 2 stars', () {
      final stars = StarUtils.calculateStars(
        score: 9,
        total: 10,
        levelId: 'summary_1',
      );
      expect(stars, 2);
    });

    test('Stricter stage (summary): 80% score should give 1 star', () {
      final stars = StarUtils.calculateStars(
        score: 8,
        total: 10,
        levelId: 'summary_1',
      );
      expect(stars, 1);
    });

    test('Stricter stage (summary): <80% score should give 0 stars', () {
      final stars = StarUtils.calculateStars(
        score: 7,
        total: 10,
        levelId: 'summary_1',
      );
      expect(stars, 0);
    });

    test('Revision stage: <80% score should give 0 stars', () {
      final stars = StarUtils.calculateStars(
        score: 7,
        total: 10,
        levelId: 'revision_1',
      );
      expect(stars, 0);
    });
  });
}
