class StarUtils {
  static int calculateStars({
    required int score,
    required int total,
    required String levelId,
  }) {
    if (total == 0) return 0;
    double percentage = score / total;

    bool isStricterStage =
        levelId.contains('summary') || levelId.contains('revision');

    if (isStricterStage) {
      if (percentage == 1.0) return 3;
      if (percentage >= 0.9) return 2;
      if (percentage >= 0.8) return 1;
      return 0;
    } else {
      if (percentage == 1.0) return 3;
      if (percentage >= 0.8) return 2;
      if (percentage >= 0.5) return 1;
      return 0;
    }
  }
}
