import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/utils/star_utils.dart';

void main() {
  group('Summary Level Star Logic - Escalation', () {
    test(
      'Starting at Threshold 0 (80%): 80% score should escalate to Threshold 1 and give 1 star',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 12,
          total: 15, // 80%
          currentThreshold: 0,
          lastSummaryStarDate: null,
        );

        expect(result['stars'], 1);
        expect(result['newThreshold'], 1);
        expect(result['earnedDailyStar'], false);
      },
    );

    test(
      'Starting at Threshold 0 (80%): 73% score should NOT escalate and give 0 stars',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 11,
          total: 15, // ~73%
          currentThreshold: 0,
          lastSummaryStarDate: null,
        );

        expect(result['stars'], 0);
        expect(result['newThreshold'], 0);
      },
    );

    test(
      'Starting at Threshold 1 (90%): 80% score should give 1 star but NOT escalate',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 12,
          total: 15, // 80%
          currentThreshold: 1,
          lastSummaryStarDate: null,
        );

        expect(result['stars'], 1);
        expect(result['newThreshold'], 1);
      },
    );

    test(
      'Starting at Threshold 1 (90%): 93% score should escalate to Threshold 2 and give 2 stars',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 14,
          total: 15, // ~93%
          currentThreshold: 1,
          lastSummaryStarDate: null,
        );

        expect(result['stars'], 2);
        expect(result['newThreshold'], 2);
      },
    );

    test(
      'Starting at Threshold 2 (100%): 93% score should give 2 stars but NOT escalate',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 14,
          total: 15, // ~93%
          currentThreshold: 2,
          lastSummaryStarDate: null,
        );

        expect(result['stars'], 2);
        expect(result['newThreshold'], 2);
      },
    );

    test(
      'Starting at Threshold 2 (100%): 100% score should escalate to Threshold 3 (Master) and give 3 stars',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 15,
          total: 15, // 100%
          currentThreshold: 2,
          lastSummaryStarDate: null,
        );

        expect(result['stars'], 3);
        expect(result['newThreshold'], 3);
      },
    );
  });

  group('Summary Level Star Logic - Daily Cap (Master State)', () {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    test(
      'Master (Threshold 3): 100% score on a new day should award 1 extra star',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 15,
          total: 15,
          currentThreshold: 3,
          lastSummaryStarDate: yesterday,
        );

        expect(result['stars'], 3); // Keeps best score
        expect(result['earnedDailyStar'], true);
      },
    );

    test(
      'Master (Threshold 3): 100% score on the SAME day should NOT award another star',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 15,
          total: 15,
          currentThreshold: 3,
          lastSummaryStarDate: today,
        );

        expect(result['earnedDailyStar'], false);
      },
    );

    test(
      'Master (Threshold 3): 93% score should NOT award a daily star even on a new day',
      () {
        final result = StarUtils.calculateSummaryResult(
          score: 14,
          total: 15,
          currentThreshold: 3,
          lastSummaryStarDate: yesterday,
        );

        expect(result['earnedDailyStar'], false);
      },
    );
  });
}
