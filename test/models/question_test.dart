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
  });
}
