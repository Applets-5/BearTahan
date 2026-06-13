class StreakResult {
  final int newStreak;
  final DateTime lastActivityDate;
  final bool shouldUpdate;

  StreakResult({
    required this.newStreak,
    required this.lastActivityDate,
    required this.shouldUpdate,
  });
}

class StreakUtils {
  /// Calculates the effective streak based on the stored streak and last activity date.
  /// If today is a gap day (missed yesterday), the effective streak is 0.
  static int getEffectiveStreak({
    required int storedStreak,
    required DateTime? lastActivityDate,
    required DateTime now,
  }) {
    if (lastActivityDate == null) return 0;

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime lastActivityDay = DateTime(
      lastActivityDate.year,
      lastActivityDate.month,
      lastActivityDate.day,
    );

    final difference = today.difference(lastActivityDay).inDays;

    if (difference == 0) {
      // Played today, streak is valid
      return storedStreak;
    } else if (difference == 1) {
      // Played yesterday, streak is still valid for today
      return storedStreak;
    } else {
      // Missed at least one day, streak is broken
      return 0;
    }
  }

  static StreakResult calculateStreak({
    required int currentStreak,
    required DateTime? lastActivityDate,
    required DateTime now,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Use effective streak to determine if we are continuing or starting over
    final effectiveStreak = getEffectiveStreak(
      storedStreak: currentStreak,
      lastActivityDate: lastActivityDate,
      now: now,
    );

    if (lastActivityDate == null || effectiveStreak == 0) {
      return StreakResult(
        newStreak: 1,
        lastActivityDate: today,
        shouldUpdate: true,
      );
    }

    final DateTime lastActivityDay = DateTime(
      lastActivityDate.year,
      lastActivityDate.month,
      lastActivityDate.day,
    );

    final difference = today.difference(lastActivityDay).inDays;

    if (difference == 0) {
      // Already played today
      return StreakResult(
        newStreak: currentStreak,
        lastActivityDate: lastActivityDay,
        shouldUpdate: false,
      );
    } else {
      // Consecutive day (difference must be 1 because effectiveStreak > 0)
      return StreakResult(
        newStreak: currentStreak + 1,
        lastActivityDate: today,
        shouldUpdate: true,
      );
    }
  }
}
