import 'dart:math';

import '../../models/question.dart';

class BearsDenDemoData {
  const BearsDenDemoData._();

  static const sessionSize = 12;
  static const chapterTargets = {'c0': 2, 'c1': 6, 'c2': 4};
  static const eligibleTypes = {'mcq', 'fillblank'};

  static const chapterLabels = {
    'c0': 'Chapter 0 - Foundation',
    'c1': 'Chapter 1',
    'c2': 'Chapter 2',
  };

  static String chapterKeyForQuestion(Question question) {
    final parts = question.id.toLowerCase().split('_');
    if (parts.length >= 2 && chapterLabels.containsKey(parts[1])) {
      return parts[1];
    }
    return '';
  }

  static String chapterLabelForQuestion(Question question) {
    return chapterLabels[chapterKeyForQuestion(question)] ?? 'Chapter Mix';
  }

  static bool isEligible(Question question) {
    final type = question.type?.toLowerCase() ?? 'mcq';
    return eligibleTypes.contains(type) &&
        chapterLabels.containsKey(chapterKeyForQuestion(question));
  }

  static List<Question> selectSession(
    List<Question> questionPool, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final eligible = questionPool.where(isEligible).toList();
    final byChapter = <String, List<Question>>{
      for (final chapter in chapterTargets.keys) chapter: [],
    };

    for (final question in eligible) {
      byChapter[chapterKeyForQuestion(question)]?.add(question);
    }
    for (final questions in byChapter.values) {
      questions.shuffle(rng);
    }

    final selected = <Question>[];
    final selectedIds = <String>{};
    for (final entry in chapterTargets.entries) {
      for (final question in byChapter[entry.key]!.take(entry.value)) {
        if (selectedIds.add(question.id)) selected.add(question);
      }
    }

    if (selected.length < sessionSize) {
      final remaining =
          eligible
              .where((question) => !selectedIds.contains(question.id))
              .toList()
            ..shuffle(rng);
      for (final question in remaining) {
        if (selected.length >= sessionSize) break;
        if (selectedIds.add(question.id)) selected.add(question);
      }
    }

    if (selected.length < sessionSize) return [];
    selected.shuffle(rng);
    return selected.take(sessionSize).toList();
  }

  static bool hasExpectedDistribution(List<Question> questions) {
    final counts = <String, int>{};
    for (final question in questions) {
      final key = chapterKeyForQuestion(question);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return questions.length == sessionSize &&
        counts['c0'] == chapterTargets['c0'] &&
        counts['c1'] == chapterTargets['c1'] &&
        counts['c2'] == chapterTargets['c2'] &&
        questions.every(isEligible) &&
        questions.map((question) => question.id).toSet().length ==
            questions.length;
  }

  static bool isValidSession(List<Question> questions) {
    return questions.length == sessionSize &&
        questions.every(isEligible) &&
        questions.map((question) => question.id).toSet().length ==
            questions.length;
  }
}
