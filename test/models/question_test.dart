import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/models/question.dart';

void main() {
  group('Question', () {
    test('fromFirestore parses stroke trace metadata', () {
      final strokeData = {
        'strokes': ['M 0 0 L 10 10'],
        'medians': [
          [
            [0, 0],
            [10, 10],
          ],
        ],
      };

      final question = Question.fromFirestore('q1', {
        'prompt': 'Trace 人',
        'type': 'stroke_trace',
        'characterUnicode': '人',
        'strokeOrderData': strokeData,
      });

      expect(question.type, 'stroke_trace');
      expect(question.characterUnicode, '人');
      expect(question.strokeOrderDataJson, jsonEncode(strokeData));
    });

    test('fromFirestore parses numeric answer metadata', () {
      final question = Question.fromFirestore('math_q1', {
        'questionText': 'How many apples?',
        'questionType': 'keyinnumber',
        'correctAnswer': 7,
      });

      expect(question.type, 'keyinnumber');
      expect(question.correctNumber, 7);
    });

    test('fromFirestore parses legacy lowercase numeric answer metadata', () {
      final question = Question.fromFirestore('math_q2', {
        'questionText': 'How many oranges?',
        'questionType': 'keyinnumber',
        'correctanswerid': '9',
      });

      expect(question.type, 'keyinnumber');
      expect(question.correctNumber, 9);
    });
  });
}
