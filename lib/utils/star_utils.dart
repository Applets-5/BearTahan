class StarUtils {
  static int calculateStars({
    required int score,
    required int total,
    required String levelId,
  }) {
    if (total == 0) return 0;
    double percentage = score / total;

    bool isSummary = levelId.toLowerCase().contains('summary');
    if (isSummary) {
      // For summary, use the base 80/90/100 logic for the first pass
      // But usually this will be handled by calculateSummaryResult
      if (percentage == 1.0) return 3;
      if (percentage >= 0.9) return 2;
      if (percentage >= 0.8) return 1;
      return 0;
    }

    bool isRevision = levelId.contains('revision');
    if (isRevision) {
      if (percentage == 1.0) return 3;
      if (percentage >= 0.9) return 2;
      if (percentage >= 0.8) return 1;
      return 0;
    }

    if (percentage == 1.0) return 3;
    if (percentage >= 0.8) return 2;
    if (percentage >= 0.5) return 1;
    return 0;
  }

  /// Calculates the result for a summary level based on the current threshold.
  /// Returns a map with 'stars', 'newThreshold', and 'earnedDailyStar'.
  static Map<String, dynamic> calculateSummaryResult({
    required int score,
    required int total,
    required int currentThreshold, // 0 (80%), 1 (90%), 2 (100%), 3 (Mastered)
    required DateTime? lastSummaryStarDate,
  }) {
    if (total == 0) {
      return {
        'stars': 0,
        'newThreshold': currentThreshold,
        'earnedDailyStar': false,
      };
    }

    double percentage = score / total;
    int stars = 0;
    int newThreshold = currentThreshold;
    bool earnedDailyStar = false;

    // Threshold escalation logic
    if (currentThreshold == 0) {
      // Level 1: 80%
      if (percentage >= 0.8) {
        stars = 1;
        newThreshold = 1;
      }
    } else if (currentThreshold == 1) {
      // Level 2: 90%
      if (percentage >= 0.9) {
        stars = 2;
        newThreshold = 2;
      } else if (percentage >= 0.8) {
        stars = 1; // Stayed at 1
      }
    } else if (currentThreshold == 2) {
      // Level 3: 100%
      if (percentage >= 1.0) {
        stars = 3;
        newThreshold = 3;
      } else if (percentage >= 0.9) {
        stars = 2;
      } else if (percentage >= 0.8) {
        stars = 1;
      }
    } else if (currentThreshold >= 3) {
      // Mastered: 100% daily cap logic
      stars = 3; // Keep 3 stars as best
      if (percentage >= 1.0) {
        final now = DateTime.now();
        final bool isNewDay =
            lastSummaryStarDate == null ||
            lastSummaryStarDate.year != now.year ||
            lastSummaryStarDate.month != now.month ||
            lastSummaryStarDate.day != now.day;

        if (isNewDay) {
          earnedDailyStar = true;
        }
      }
    }

    return {
      'stars': stars,
      'newThreshold': newThreshold,
      'earnedDailyStar': earnedDailyStar,
    };
  }
}
