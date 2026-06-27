import 'dart:math';

import 'package:bear_tahan/features/bears_den/bears_den_demo_data.dart';
import 'package:bear_tahan/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

Question question(String id, {String type = 'mcq'}) => Question(
  id: id,
  text: '',
  type: type,
  options: const [],
  correctAnswerIndex: 0,
);

List<Question> chapterPool(String chapter, int count, {String type = 'mcq'}) {
  return List.generate(
    count,
    (index) => question(
      'bi_${chapter}_l1_q${index.toString().padLeft(2, '0')}',
      type: type,
    ),
  );
}

void main() {
  test('derives English chapter labels from question IDs', () {
    expect(
      BearsDenDemoData.chapterLabelForQuestion(question('bi_c0_l1_q03')),
      'Chapter 0 - Foundation',
    );
    expect(
      BearsDenDemoData.chapterLabelForQuestion(question('bi_c2_l1_q01')),
      'Chapter 2',
    );
  });

  test('selects a unique 2/6/4 session from eligible question types', () {
    final pool = [
      ...chapterPool('c0', 8),
      ...chapterPool('c1', 12, type: 'fillBlank'),
      ...chapterPool('c2', 10),
      question('bi_c1_l1_matching', type: 'matching'),
      question('bi_c2_l1_listening', type: 'fillBlankListening'),
    ];

    final session = BearsDenDemoData.selectSession(pool, random: Random(7));

    expect(BearsDenDemoData.hasExpectedDistribution(session), isTrue);
    expect(session, hasLength(12));
    expect(session.every(BearsDenDemoData.isEligible), isTrue);
  });

  test('different seeds produce different valid sessions', () {
    final pool = [
      ...chapterPool('c0', 15),
      ...chapterPool('c1', 20),
      ...chapterPool('c2', 20),
    ];
    final first = BearsDenDemoData.selectSession(pool, random: Random(1));
    final second = BearsDenDemoData.selectSession(pool, random: Random(2));

    expect(
      first.map((question) => question.id).toList(),
      isNot(equals(second.map((question) => question.id).toList())),
    );
    expect(BearsDenDemoData.hasExpectedDistribution(first), isTrue);
    expect(BearsDenDemoData.hasExpectedDistribution(second), isTrue);
  });

  test('fills a chapter shortage from remaining eligible questions', () {
    final pool = [
      ...chapterPool('c0', 1),
      ...chapterPool('c1', 8),
      ...chapterPool('c2', 8),
    ];

    final session = BearsDenDemoData.selectSession(pool, random: Random(4));

    expect(session, hasLength(12));
    expect(session.map((question) => question.id).toSet(), hasLength(12));
    expect(session.every(BearsDenDemoData.isEligible), isTrue);
    expect(BearsDenDemoData.isValidSession(session), isTrue);
  });

  test(
    'returns an empty session when fewer than 12 questions are eligible',
    () {
      final session = BearsDenDemoData.selectSession(
        chapterPool('c1', 11),
        random: Random(1),
      );
      expect(session, isEmpty);
    },
  );
}
