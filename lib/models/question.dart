import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum QuestionType {
  mcq,
  fillBlank,
  rearrange,
}

enum QuestionImageMode {
  none,
  promptImage,
  answerImage,
}

class Question {
  final String id;
  final String subjectId;
  final String chapterId;
  final String levelId;
  final int levelNumber;
  final int difficulty;
  final QuestionType questionType;
  final QuestionImageMode imageMode;
  final String prompt;
  final String? imageUrl;
  final List<QuestionOption> options;
  final String correctAnswerId;
  final String? correctBlank;
  final List<String>? correctOrder;

  const Question({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.levelId,
    required this.levelNumber,
    required this.difficulty,
    required this.questionType,
    required this.imageMode,
    required this.prompt,
    this.imageUrl,
    required this.options,
    this.correctAnswerId = '',
    this.correctBlank,
    this.correctOrder,
  });

  // ── Main factory — used by repository ──────────────────────────────────────
  factory Question.fromFirestore(DocumentSnapshot doc) {
    final String id = doc.id;
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Question._parse(id, data);
  }

  // ── Legacy factory — used by firestore_service.dart and tests ──────────────
  factory Question.fromMap(String id, Map<String, dynamic> data) {
    return Question._parse(id, data);
  }

  // ── Shared parse logic ─────────────────────────────────────────────────────
  factory Question._parse(String id, Map<String, dynamic> data) {
    debugPrint('DEBUG: Parsing question document: $id');
    debugPrint('DEBUG: Raw data: $data');

    String extractText(dynamic value) {
      if (value is String) return value;
      if (value is Map) {
        final contentKeys = ['text', 'label', 'value', 'word', 'name'];
        for (var key in contentKeys) {
          if (value.containsKey(key)) return value[key].toString();
        }
      }
      return value?.toString() ?? '';
    }

    // Prompt — supports multiple field aliases
    final String prompt = extractText(
      data['prompt'] ??
      data['text'] ??
      data['questionText'] ??
      data['question'] ??
      data['q'] ??
      '',
    );

    // Image URL — supports multiple field aliases
    dynamic rawImage =
        data['imageUrl'] ?? data['image'] ?? data['img'] ?? data['picture'];
    String? finalImageUrl;
    if (rawImage is String) {
      finalImageUrl = rawImage;
    } else if (rawImage is Map && rawImage.containsKey('url')) {
      finalImageUrl = rawImage['url']?.toString();
    }

    // Correct answer ID — supports letter (A/B/C/D) or index (0/1/2/3)
    dynamic rawAnswer =
        data['correctAnswerId'] ??
        data['correctanswerid'] ??
        data['correctAnswerIndex'] ??
        data['answerIndex'] ??
        data['correctIndex'] ??
        data['correctAnswer'] ??
        data['answer'] ??
        '';

    String finalCorrectAnswerId = '';
    if (rawAnswer is String) {
      finalCorrectAnswerId = rawAnswer.trim();
    } else if (rawAnswer is num) {
      // Convert old index format: 0→A, 1→B, 2→C, 3→D
      final idx = rawAnswer.toInt();
      if (idx >= 0 && idx <= 25) {
        finalCorrectAnswerId = String.fromCharCode(65 + idx);
      }
    }

    // Options — supports both List<String> and List<Map> formats
    final rawOptions = data['options'] as List<dynamic>? ?? [];
    final List<QuestionOption> options = rawOptions.asMap().entries.map((entry) {
      final idx = entry.key;
      final e = entry.value;
      if (e is Map<String, dynamic>) {
        return QuestionOption.fromMap(e);
      } else {
        // Old plain string format — auto-assign A/B/C/D
        return QuestionOption(
          id: String.fromCharCode(65 + idx),
          text: extractText(e),
        );
      }
    }).toList();

    final QuestionType questionType = QuestionType.values.firstWhere(
      (e) => e.name == (data['questionType'] as String? ?? 'mcq'),
      orElse: () => QuestionType.mcq,
    );

    final QuestionImageMode imageMode = QuestionImageMode.values.firstWhere(
      (e) => e.name == (data['imageMode'] as String? ?? 'none'),
      orElse: () => QuestionImageMode.none,
    );

    final List<String>? correctOrder =
        (data['correctOrder'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();

    return Question(
      id: id,
      subjectId: data['subjectId'] as String? ?? '',
      chapterId: data['chapterId'] as String? ?? '',
      levelId: data['levelId'] as String? ?? '',
      levelNumber: data['levelNumber'] as int? ?? 1,
      difficulty: data['difficulty'] as int? ?? 1,
      questionType: questionType,
      imageMode: imageMode,
      prompt: prompt,
      imageUrl: finalImageUrl,
      options: options,
      correctAnswerId: finalCorrectAnswerId,
      correctBlank: data['correctBlank'] as String?,
      correctOrder: correctOrder,
    );
  }

  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'chapterId': chapterId,
    'levelId': levelId,
    'levelNumber': levelNumber,
    'difficulty': difficulty,
    'questionType': questionType.name,
    'imageMode': imageMode.name,
    'prompt': prompt,
    'imageUrl': imageUrl,
    'correctAnswerId': correctAnswerId,
    'correctBlank': correctBlank,
    'correctOrder': correctOrder,
    'options': options.map((o) => o.toMap()).toList(),
  };
}

// ── QuestionOption ─────────────────────────────────────────────────────────

class QuestionOption {
  final String id;
  final String text;
  final String? imageUrl;

  const QuestionOption({
    required this.id,
    required this.text,
    this.imageUrl,
  });

  factory QuestionOption.fromMap(Map<String, dynamic> map) => QuestionOption(
    id: map['id'] as String? ?? '',
    text: map['text'] as String? ?? '',
    imageUrl: map['imageUrl'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'imageUrl': imageUrl,
  };
}