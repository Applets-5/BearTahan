import 'dart:math';

import 'package:bear_tahan/models/math_generation_rule.dart';
import 'package:bear_tahan/utils/math_question_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses a `a symbol b = ?` prompt back into its parts so tests can
/// check the generator's arithmetic independently of its implementation.
({int a, String symbol, int b}) _parsePrompt(String prompt) {
  final match = RegExp(r'^(\d+) ([+-]) (\d+) = \?$').firstMatch(prompt);
  if (match == null) {
    fail('Prompt "$prompt" does not match the expected format');
  }
  return (
    a: int.parse(match.group(1)!),
    symbol: match.group(2)!,
    b: int.parse(match.group(3)!),
  );
}

void main() {
  group('MathGenerationRule.fromMap', () {
    test('parses addition rule fields', () {
      final rule = MathGenerationRule.fromMap({
        'operation': 'addition',
        'minA': 1,
        'maxA': 10,
        'minB': 2,
        'maxB': 5,
      });

      expect(rule.operation, MathOperation.addition);
      expect(rule.minA, 1);
      expect(rule.maxA, 10);
      expect(rule.minB, 2);
      expect(rule.maxB, 5);
    });

    test(
      'parses subtraction rule from "operationType" and numeric strings',
      () {
        final rule = MathGenerationRule.fromMap({
          'operationType': 'Subtraction',
          'minA': '5',
          'maxA': '20',
          'minB': '1',
          'maxB': '9',
        });

        expect(rule.operation, MathOperation.subtraction);
        expect(rule.minA, 5);
        expect(rule.maxA, 20);
        expect(rule.minB, 1);
        expect(rule.maxB, 9);
      },
    );

    test('falls back to addition defaults when fields are missing', () {
      final rule = MathGenerationRule.fromMap(const {});

      expect(rule.operation, MathOperation.addition);
      expect(rule.minA, 1);
      expect(rule.maxA, 10);
      expect(rule.minB, 1);
      expect(rule.maxB, 10);
    });
  });

  group('MathQuestionGenerator', () {
    test('addition: correct answer equals a + b within configured ranges', () {
      const rule = MathGenerationRule(
        operation: MathOperation.addition,
        minA: 1,
        maxA: 10,
        minB: 1,
        maxB: 10,
      );
      final generator = MathQuestionGenerator(random: Random(1));

      for (var i = 0; i < 200; i++) {
        final question = generator.generate(rule);
        final parsed = _parsePrompt(question.prompt);

        expect(parsed.symbol, '+');
        expect(parsed.a, inInclusiveRange(1, 10));
        expect(parsed.b, inInclusiveRange(1, 10));
        expect(question.correctAnswer, parsed.a + parsed.b);
      }
    });

    test(
      'subtraction: operands are swapped so the result is never negative',
      () {
        const rule = MathGenerationRule(
          operation: MathOperation.subtraction,
          minA: 1,
          maxA: 5,
          minB: 1,
          maxB: 20,
        );
        final generator = MathQuestionGenerator(random: Random(2));

        for (var i = 0; i < 200; i++) {
          final question = generator.generate(rule);
          final parsed = _parsePrompt(question.prompt);

          expect(parsed.symbol, '-');
          expect(parsed.a, greaterThanOrEqualTo(parsed.b));
          expect(question.correctAnswer, parsed.a - parsed.b);
          expect(question.correctAnswer, greaterThanOrEqualTo(0));
        }
      },
    );

    test('boundary: minA == maxA and minB == maxB pin both operands', () {
      const rule = MathGenerationRule(
        operation: MathOperation.addition,
        minA: 7,
        maxA: 7,
        minB: 3,
        maxB: 3,
      );
      final generator = MathQuestionGenerator(random: Random(3));

      final question = generator.generate(rule);
      final parsed = _parsePrompt(question.prompt);

      expect(parsed.a, 7);
      expect(parsed.b, 3);
      expect(question.correctAnswer, 10);
    });

    test(
      'boundary: subtraction where minA == minB == maxA == maxB gives zero',
      () {
        const rule = MathGenerationRule(
          operation: MathOperation.subtraction,
          minA: 5,
          maxA: 5,
          minB: 5,
          maxB: 5,
        );
        final generator = MathQuestionGenerator(random: Random(4));

        final question = generator.generate(rule);

        expect(question.correctAnswer, 0);
        expect(question.options, contains(0));
      },
    );

    test(
      'options always contain exactly 4 distinct, non-negative integers',
      () {
        const rules = [
          MathGenerationRule(
            operation: MathOperation.addition,
            minA: 1,
            maxA: 10,
            minB: 1,
            maxB: 10,
          ),
          MathGenerationRule(
            operation: MathOperation.subtraction,
            minA: 1,
            maxA: 10,
            minB: 1,
            maxB: 10,
          ),
          MathGenerationRule(
            operation: MathOperation.subtraction,
            minA: 0,
            maxA: 0,
            minB: 0,
            maxB: 0,
          ),
        ];

        for (final rule in rules) {
          final generator = MathQuestionGenerator(random: Random(5));
          for (var i = 0; i < 200; i++) {
            final question = generator.generate(rule);

            expect(question.options, hasLength(4));
            expect(question.options.toSet(), hasLength(4));
            expect(question.options, everyElement(greaterThanOrEqualTo(0)));
          }
        }
      },
    );

    test('the correct answer is always included in the options', () {
      const rule = MathGenerationRule(
        operation: MathOperation.addition,
        minA: 1,
        maxA: 50,
        minB: 1,
        maxB: 50,
      );
      final generator = MathQuestionGenerator(random: Random(6));

      for (var i = 0; i < 200; i++) {
        final question = generator.generate(rule);
        expect(question.options, contains(question.correctAnswer));
      }
    });

    test(
      'toQuestion maps the correct answer to its index among the options',
      () {
        const rule = MathGenerationRule(
          operation: MathOperation.addition,
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        final generator = MathQuestionGenerator(random: Random(7));
        final generated = generator.generate(rule);

        final question = generated.toQuestion('math_generated_test_0');

        expect(question.id, 'math_generated_test_0');
        expect(question.type, 'mcq');
        expect(question.text, generated.prompt);
        expect(question.options, hasLength(4));
        expect(
          question.options[question.correctAnswerIndex].text,
          generated.correctAnswer.toString(),
        );
      },
    );
  });
}
