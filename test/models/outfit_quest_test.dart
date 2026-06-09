import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/models/outfit_quest.dart';

void main() {
  group('OutfitQuest', () {
    test('contains all V1 default outfit quests', () {
      final outfitIds = OutfitQuest.defaults.map((quest) => quest.id).toList();

      expect(outfitIds, contains('scholar_bear'));
      expect(outfitIds, contains('chef_bear'));
      expect(outfitIds, contains('astro_bear'));
      expect(outfitIds, contains('pirate_bear'));
      expect(outfitIds, contains('super_bear'));
      expect(outfitIds, contains('explorer_bear'));
      expect(OutfitQuest.defaults.length, equals(6));
    });

    test('defines Scholar Bear as starter outfit', () {
      final quest = OutfitQuest.byId('scholar_bear');

      expect(quest.name, equals('Scholar Bear'));
      expect(quest.conditionType, equals('starter'));
      expect(quest.target, equals(0));
      expect(quest.isStarter, isTrue);
    });

    test('defines Chef Bear as complete 5 BM lessons', () {
      final quest = OutfitQuest.byId('chef_bear');

      expect(quest.conditionType, equals('completed_lessons'));
      expect(quest.subjectId, equals('bm'));
      expect(quest.target, equals(5));
    });

    test('defines Astro Bear as score 100 percent on 3 Maths quizzes', () {
      final quest = OutfitQuest.byId('astro_bear');

      expect(quest.conditionType, equals('perfect_quizzes'));
      expect(quest.subjectId, equals('math'));
      expect(quest.target, equals(3));
    });

    test('defines Pirate Bear as complete 10 English lessons', () {
      final quest = OutfitQuest.byId('pirate_bear');

      expect(quest.conditionType, equals('completed_lessons'));
      expect(quest.subjectId, equals('en'));
      expect(quest.target, equals(10));
    });

    test('defines Super Bear as earn 500 total stars', () {
      final quest = OutfitQuest.byId('super_bear');

      expect(quest.conditionType, equals('total_stars'));
      expect(quest.target, equals(500));
    });

    test('defines Explorer Bear as complete all Science topics', () {
      final quest = OutfitQuest.byId('explorer_bear');

      expect(quest.conditionType, equals('complete_all_topics'));
      expect(quest.subjectId, equals('science'));
      expect(quest.target, equals(8));
    });

    test('returns requested default quest by id', () {
      final quest = OutfitQuest.byId('chef_bear');

      expect(quest.id, equals('chef_bear'));
      expect(quest.name, equals('Chef Bear'));
    });

    test('returns Scholar Bear when id does not exist', () {
      final quest = OutfitQuest.byId('missing_bear');

      expect(quest.id, equals('scholar_bear'));
    });

    test('creates quest from Firestore data', () {
      final quest = OutfitQuest.fromFirestore('custom_bear', {
        'name': 'Custom Bear',
        'description': 'Complete custom mission',
        'imagePath': 'assets/images/custom.png',
        'conditionType': 'completed_lessons',
        'subjectId': 'bm',
        'target': 7,
        'displayOrder': 10,
      });

      expect(quest.id, equals('custom_bear'));
      expect(quest.name, equals('Custom Bear'));
      expect(quest.description, equals('Complete custom mission'));
      expect(quest.imagePath, equals('assets/images/custom.png'));
      expect(quest.conditionType, equals('completed_lessons'));
      expect(quest.subjectId, equals('bm'));
      expect(quest.target, equals(7));
      expect(quest.displayOrder, equals(10));
    });

    test('uses safe fallback values when Firestore data is missing', () {
      final quest = OutfitQuest.fromFirestore('fallback_bear', {});

      expect(quest.id, equals('fallback_bear'));
      expect(quest.name, equals('fallback_bear'));
      expect(quest.description, equals(''));
      expect(quest.imagePath, equals('assets/images/bear1.png'));
      expect(quest.conditionType, equals('starter'));
      expect(quest.target, equals(0));
      expect(quest.displayOrder, equals(999));
    });
  });

  group('OutfitQuestProgress', () {
    test('returns 0 percentage when target is 0 and outfit is locked', () {
      const progress = OutfitQuestProgress(
        outfitId: 'chef_bear',
        currentValue: 0,
        targetValue: 0,
        isUnlocked: false,
      );

      expect(progress.percentage, equals(0));
    });

    test('returns 1 percentage when target is 0 and outfit is unlocked', () {
      const progress = OutfitQuestProgress(
        outfitId: 'scholar_bear',
        currentValue: 0,
        targetValue: 0,
        isUnlocked: true,
      );

      expect(progress.percentage, equals(1));
    });

    test('calculates percentage from current and target values', () {
      const progress = OutfitQuestProgress(
        outfitId: 'chef_bear',
        currentValue: 3,
        targetValue: 5,
        isUnlocked: false,
      );

      expect(progress.percentage, equals(0.6));
    });

    test('clamps percentage to 1 when current value is above target', () {
      const progress = OutfitQuestProgress(
        outfitId: 'chef_bear',
        currentValue: 9,
        targetValue: 5,
        isUnlocked: true,
      );

      expect(progress.percentage, equals(1));
    });

    test('creates progress from Firestore data', () {
      final progress = OutfitQuestProgress.fromFirestore('chef_bear', {
        'currentValue': 5,
        'targetValue': 5,
        'isUnlocked': true,
      });

      expect(progress.outfitId, equals('chef_bear'));
      expect(progress.currentValue, equals(5));
      expect(progress.targetValue, equals(5));
      expect(progress.isUnlocked, isTrue);
      expect(progress.unlockedAt, isNull);
    });
  });
}
