import 'dart:math';

import '../models/math_generation_rule.dart';
import '../models/question.dart';

class GeneratedMathQuestion {
  final String prompt;
  final int correctAnswer;
  final List<int> options;

  const GeneratedMathQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  Question toQuestion(String id) {
    return Question(
      id: id,
      text: prompt,
      options: options.map((value) => value.toString()).toList(),
      correctAnswerIndex: options.indexOf(correctAnswer),
      type: 'mcq',
    );
  }
}

/// Generates Maths questions at runtime from a [MathGenerationRule] instead
/// of reading individually authored questions from Firestore.
class MathQuestionGenerator {
  MathQuestionGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  GeneratedMathQuestion generate(MathGenerationRule rule) {
    final a = _randomInRange(rule.minA, rule.maxA);
    final b = _randomInRange(rule.minB, rule.maxB);

    final int operandA;
    final int operandB;
    final int correctAnswer;
    final String symbol;

    if (rule.operation == MathOperation.subtraction) {
      // Order operands largest-first so young children never see a
      // negative result.
      operandA = a >= b ? a : b;
      operandB = a >= b ? b : a;
      correctAnswer = operandA - operandB;
      symbol = '-';
    } else {
      operandA = a;
      operandB = b;
      correctAnswer = operandA + operandB;
      symbol = '+';
    }

    return GeneratedMathQuestion(
      prompt: '$operandA $symbol $operandB = ?',
      correctAnswer: correctAnswer,
      options: _generateOptions(correctAnswer),
    );
  }

  int _randomInRange(int min, int max) {
    final lo = min <= max ? min : max;
    final hi = min <= max ? max : min;
    return lo + _random.nextInt(hi - lo + 1);
  }

  /// Picks 3 distinct, non-negative, numerically-plausible wrong options
  /// (small offsets from the correct answer) and returns all 4 shuffled.
  List<int> _generateOptions(int correctAnswer) {
    final deltas = [
      for (var d = 1; d <= 10; d++) d,
      for (var d = 1; d <= 10; d++) -d,
    ]..shuffle(_random);

    final options = <int>{correctAnswer};
    for (final delta in deltas) {
      if (options.length == 4) break;
      final candidate = correctAnswer + delta;
      if (candidate < 0) continue;
      options.add(candidate);
    }

    return options.toList()..shuffle(_random);
  }
}
