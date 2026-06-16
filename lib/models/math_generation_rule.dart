enum MathOperation { addition, subtraction }

class MathGenerationRule {
  final MathOperation operation;
  final int minA;
  final int maxA;
  final int minB;
  final int maxB;

  const MathGenerationRule({
    required this.operation,
    required this.minA,
    required this.maxA,
    required this.minB,
    required this.maxB,
  });

  factory MathGenerationRule.fromMap(Map<String, dynamic> data) {
    int parseInt(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    final operationRaw = (data['operation'] ?? data['operationType'] ?? '')
        .toString()
        .toLowerCase();

    return MathGenerationRule(
      operation: operationRaw.startsWith('sub')
          ? MathOperation.subtraction
          : MathOperation.addition,
      minA: parseInt(data['minA'], 1),
      maxA: parseInt(data['maxA'], 10),
      minB: parseInt(data['minB'], 1),
      maxB: parseInt(data['maxB'], 10),
    );
  }
}
