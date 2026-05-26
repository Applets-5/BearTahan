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
  static StreakResult calculateStreak({
    required int currentStreak,
    required DateTime? lastActivityDate,
    required DateTime now,
  }) {
    final DateTime today = DateTime(now.year, now.month, now.day);

    if (lastActivityDate == null) {
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
    } else if (difference == 1) {
      // Consecutive day
      return StreakResult(
        newStreak: currentStreak + 1,
        lastActivityDate: today,
        shouldUpdate: true,
      );
    } else {
      // Gap day
      return StreakResult(
        newStreak: 1,
        lastActivityDate: today,
        shouldUpdate: true,
      );
    }
  }
}
