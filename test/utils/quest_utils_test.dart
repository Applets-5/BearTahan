import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/models/outfit_quest.dart';
import 'package:bear_tahan/utils/quest_utils.dart';

void main() {
  group('QuestUtils.calculateQuestCurrentValue', () {
    test('returns target value for starter quest', () {
      final quest = OutfitQuest.byId('scholar_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 0,
        subjectProgress: {},
        attempts: [],
      );

      expect(value, equals(0));
    });

    test('returns completed BM lessons for Chef Bear quest', () {
      final quest = OutfitQuest.byId('chef_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 0,
        subjectProgress: {
          'bm': {'completedLevels': 4},
        },
        attempts: [],
      );

      expect(value, equals(4));
    });

    test('returns 0 completed lessons when subject progress is missing', () {
      final quest = OutfitQuest.byId('chef_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 0,
        subjectProgress: {},
        attempts: [],
      );

      expect(value, equals(0));
    });

    test('counts only perfect Maths quiz attempts for Astro Bear quest', () {
      final quest = OutfitQuest.byId('astro_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 0,
        subjectProgress: {},
        attempts: [
          {'subjectId': 'math', 'score': 10, 'total': 10},
          {'subjectId': 'math', 'score': 5, 'total': 5},
          {'subjectId': 'math', 'score': 9, 'total': 10},
          {'subjectId': 'science', 'score': 10, 'total': 10},
          {'subjectId': 'math', 'score': 0, 'total': 0},
        ],
      );

      expect(value, equals(2));
    });

    test('returns lifetime stars for Super Bear quest', () {
      final quest = OutfitQuest.byId('super_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 499,
        subjectProgress: {},
        attempts: [],
      );

      expect(value, equals(499));
    });

    test('returns target value when all Science topics are completed', () {
      final quest = OutfitQuest.byId('explorer_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 0,
        subjectProgress: {
          'science': {'progress': 100, 'completedLevels': 6},
        },
        attempts: [],
      );

      expect(value, equals(8));
    });

    test('returns completed Science levels before all topics are completed', () {
      final quest = OutfitQuest.byId('explorer_bear');

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 0,
        subjectProgress: {
          'science': {'progress': 75, 'completedLevels': 6},
        },
        attempts: [],
      );

      expect(value, equals(6));
    });

    test('returns 0 for unknown quest condition type', () {
      const quest = OutfitQuest(
        id: 'unknown_bear',
        name: 'Unknown Bear',
        description: 'Unknown quest',
        imagePath: 'assets/images/bear1.png',
        conditionType: 'unknown_condition',
        target: 1,
        displayOrder: 99,
      );

      final value = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: 999,
        subjectProgress: {
          'bm': {'completedLevels': 99},
        },
        attempts: [
          {'subjectId': 'math', 'score': 10, 'total': 10},
        ],
      );

      expect(value, equals(0));
    });
  });

  group('QuestUtils.isQuestUnlocked', () {
    test('returns true for starter outfit', () {
      final quest = OutfitQuest.byId('scholar_bear');

      final isUnlocked = QuestUtils.isQuestUnlocked(
        quest: quest,
        currentValue: 0,
      );

      expect(isUnlocked, isTrue);
    });

    test('returns false when current value is below target', () {
      final quest = OutfitQuest.byId('chef_bear');

      final isUnlocked = QuestUtils.isQuestUnlocked(
        quest: quest,
        currentValue: 4,
      );

      expect(isUnlocked, isFalse);
    });

    test('returns true when current value is exactly target', () {
      final quest = OutfitQuest.byId('chef_bear');

      final isUnlocked = QuestUtils.isQuestUnlocked(
        quest: quest,
        currentValue: 5,
      );

      expect(isUnlocked, isTrue);
    });

    test('keeps outfit unlocked permanently even when current value drops', () {
      final quest = OutfitQuest.byId('super_bear');

      final isUnlocked = QuestUtils.isQuestUnlocked(
        quest: quest,
        currentValue: 100,
        wasUnlocked: true,
      );

      expect(isUnlocked, isTrue);
    });
  });

  group('QuestUtils.isNewUnlock', () {
    test('returns true when non-starter quest reaches target for first time', () {
      final quest = OutfitQuest.byId('astro_bear');

      final isNewUnlock = QuestUtils.isNewUnlock(
        quest: quest,
        currentValue: 3,
      );

      expect(isNewUnlock, isTrue);
    });

    test('returns false for starter quest', () {
      final quest = OutfitQuest.byId('scholar_bear');

      final isNewUnlock = QuestUtils.isNewUnlock(
        quest: quest,
        currentValue: 0,
      );

      expect(isNewUnlock, isFalse);
    });

    test('returns false when quest was already unlocked', () {
      final quest = OutfitQuest.byId('pirate_bear');

      final isNewUnlock = QuestUtils.isNewUnlock(
        quest: quest,
        currentValue: 10,
        wasUnlocked: true,
      );

      expect(isNewUnlock, isFalse);
    });

    test('returns false when non-starter quest is still below target', () {
      final quest = OutfitQuest.byId('pirate_bear');

      final isNewUnlock = QuestUtils.isNewUnlock(
        quest: quest,
        currentValue: 9,
      );

      expect(isNewUnlock, isFalse);
    });
  });
}
