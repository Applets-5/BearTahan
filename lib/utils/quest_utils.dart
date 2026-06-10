import '../models/outfit_quest.dart';

class QuestUtils {
  const QuestUtils._();

  static int calculateQuestCurrentValue({
    required OutfitQuest quest,
    required int lifetimeStarsEarned,
    required Map<String, Map<String, dynamic>> subjectProgress,
    required List<Map<String, dynamic>> attempts,
  }) {
    final subjectId = quest.subjectId;

    switch (quest.conditionType) {
      case 'starter':
        return quest.target;
      case 'completed_lessons':
        if (subjectId == null) return 0;
        return (subjectProgress[subjectId]?['completedLevels'] ?? 0).toInt();
      case 'perfect_quizzes':
        if (subjectId == null) return 0;
        return attempts.where((attempt) {
          final score = (attempt['score'] ?? 0).toInt();
          final total = (attempt['total'] ?? 0).toInt();
          return attempt['subjectId'] == subjectId &&
              total > 0 &&
              score == total;
        }).length;
      case 'total_stars':
        return lifetimeStarsEarned;
      case 'complete_all_topics':
        if (subjectId == null) return 0;
        final data = subjectProgress[subjectId] ?? {};
        final progress = (data['progress'] ?? 0).toInt();
        final completedLevels = (data['completedLevels'] ?? 0).toInt();
        return progress >= 100 ? quest.target : completedLevels;
      default:
        return 0;
    }
  }

  static bool isQuestUnlocked({
    required OutfitQuest quest,
    required int currentValue,
    bool wasUnlocked = false,
  }) {
    return wasUnlocked || quest.isStarter || currentValue >= quest.target;
  }

  static bool isNewUnlock({
    required OutfitQuest quest,
    required int currentValue,
    bool wasUnlocked = false,
  }) {
    return !quest.isStarter && !wasUnlocked && currentValue >= quest.target;
  }
}
