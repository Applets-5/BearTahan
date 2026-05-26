import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/utils/streak_utils.dart';

void main() {
  group('StreakUtils.calculateStreak', () {
    test('First session should initialize streak to 1', () {
      final now = DateTime(2026, 5, 26, 14, 30);
      final result = StreakUtils.calculateStreak(
        currentStreak: 0,
        lastActivityDate: null,
        now: now,
      );

      expect(result.newStreak, 1);
      expect(result.lastActivityDate, DateTime(2026, 5, 26));
      expect(result.shouldUpdate, true);
    });

    test('Session on consecutive day should increment streak', () {
      final lastActivity = DateTime(2026, 5, 25, 10, 0);
      final now = DateTime(2026, 5, 26, 14, 30);
      final result = StreakUtils.calculateStreak(
        currentStreak: 5,
        lastActivityDate: lastActivity,
        now: now,
      );

      expect(result.newStreak, 6);
      expect(result.lastActivityDate, DateTime(2026, 5, 26));
      expect(result.shouldUpdate, true);
    });

    test('Session after a gap day should reset streak to 1', () {
      final lastActivity = DateTime(2026, 5, 24, 10, 0);
      final now = DateTime(2026, 5, 26, 14, 30);
      final result = StreakUtils.calculateStreak(
        currentStreak: 5,
        lastActivityDate: lastActivity,
        now: now,
      );

      expect(result.newStreak, 1);
      expect(result.lastActivityDate, DateTime(2026, 5, 26));
      expect(result.shouldUpdate, true);
    });

    test('Session on the same day should not increment streak', () {
      final lastActivity = DateTime(2026, 5, 26, 10, 0);
      final now = DateTime(2026, 5, 26, 14, 30);
      final result = StreakUtils.calculateStreak(
        currentStreak: 5,
        lastActivityDate: lastActivity,
        now: now,
      );

      expect(result.newStreak, 5);
      expect(result.shouldUpdate, false);
    });
  });
}
