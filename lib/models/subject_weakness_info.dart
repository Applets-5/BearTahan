class SubjectWeaknessInfo {
  final String subjectId;
  final String subjectName;
  final double strengthScore; // 0.0 to 1.0
  final String weakestChapter;
  final String weakestLevel;
  final double accuracy;
  final int averageTimeSeconds;
  final String suggestion;

  SubjectWeaknessInfo({
    required this.subjectId,
    required this.subjectName,
    required this.strengthScore,
    required this.weakestChapter,
    required this.weakestLevel,
    required this.accuracy,
    required this.averageTimeSeconds,
    required this.suggestion,
  });
}
