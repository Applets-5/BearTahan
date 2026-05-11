class Level {
  final String id;
  final String chapterId;
  final String levelId;
  final String title;
  final bool isLocked;
  final int totalQuestions;

  const Level({
    required this.id,
    required this.chapterId,
    required this.levelId,
    required this.title,
    required this.isLocked,
    required this.totalQuestions,
  });
}