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

    test('fromFirestore parses each repaired L3 stroke question', () {
      for (final entry in {
        'bc_c1_l3_q01': '一',
        'bc_c1_l3_q02': '丨',
        'bc_c1_l3_q03': '丿',
        'bc_c1_l3_q04': '㇏',
      }.entries) {
        final question = Question.fromFirestore(entry.key, {
          'prompt': '写一写',
          'questionType': 'stroke_trace',
          'type': 'stroke_trace',
          'characterUnicode': entry.value,
          'strokeOrderData': {
            'strokes': ['M 0 0 L 10 10'],
            'medians': [
              [
                [0, 0],
                [10, 10],
              ],
            ],
          },
        });

        expect(question.type, 'stroke_trace');
        expect(question.characterUnicode, entry.value);
        expect(question.strokeOrderDataJson, isNotEmpty);
      }
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

    test('fromFirestore resolves string correctOrder to exact option text', () {
      final question = Question.fromFirestore('english_q1', {
        'questionText': 'Rearrange the sentence',
        'questionType': 'rearrange',
        'options': ['Hello,', 'world!'],
        'correctOrder': 'Hello; world',
      });

      expect(question.correctOrder, ['Hello,', 'world!']);
    });
  });
}
