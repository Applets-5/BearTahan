import 'package:bear_tahan/models/question.dart';
import 'package:bear_tahan/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final question = Question(
    id: 'bc_c1_l1_q01',
    text: 'Question',
    type: 'mcq',
    options: ['A', 'B'],
    correctAnswerIndex: 0,
  );

  test('accepts a valid review question list', () {
    expect(parseReviewQuestionsExtra([question], isReviewSession: true), [
      question,
    ]);
  });

  test('uses an empty review list for a missing or malformed payload', () {
    expect(parseReviewQuestionsExtra(null, isReviewSession: true), isEmpty);
    expect(
      parseReviewQuestionsExtra(['invalid'], isReviewSession: true),
      isEmpty,
    );
  });

  test('ignores malformed extras for regular sessions', () {
    expect(
      parseReviewQuestionsExtra(['invalid'], isReviewSession: false),
      isNull,
    );
  });
}
