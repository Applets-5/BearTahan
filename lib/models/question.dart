import 'package:flutter/foundation.dart';

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String? imageUrl;
  final String? promptAudioUrl;
  final String? type;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.imageUrl,
    this.promptAudioUrl,
    this.type,
  });

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    debugPrint('DEBUG: Parsing question document: $id');
    debugPrint('DEBUG: Raw data: $data');

    String extractText(dynamic value) {
      if (value is String) return value;
      if (value is Map) {
        // Look for common content keys in a Map
        final contentKeys = ['text', 'label', 'value', 'word', 'name'];
        for (var key in contentKeys) {
          if (value.containsKey(key)) return value[key].toString();
        }
      }
      return value?.toString() ?? '';
    }

    // Process question text safely with multiple aliases
    String text = extractText(
      data['text'] ??
          data['questionText'] ??
          data['question'] ??
          data['prompt'] ??
          data['q'] ??
          '',
    );

    // Process image URL safely
    dynamic rawImage =
        data['imageUrl'] ?? data['image'] ?? data['img'] ?? data['picture'];
    String? finalImageUrl;
    if (rawImage is String) {
      finalImageUrl = rawImage;
    } else if (rawImage is Map && rawImage.containsKey('url')) {
      finalImageUrl = rawImage['url']?.toString();
    }

    // Process audio URL safely
    String? finalAudioUrl =
        data['promptAudioUrl'] ?? data['promptAudioURL'] ?? data['audioUrl'] ?? data['audio'];

    // Process type safely
    String? type = data['type']?.toString();

    // Process answer index safely (handles numbers, strings, and letters like "A", "B")
    dynamic rawIndex =
        data['correctanswerid'] ??
        data['correctAnswerId'] ??
        data['correctAnswerIndex'] ??
        data['answerIndex'] ??
        data['correctIndex'] ??
        data['correctAnswer'] ??
        data['answer'];

    int finalIndex = 0;
    if (rawIndex is num) {
      finalIndex = rawIndex.toInt();
    } else if (rawIndex is String) {
      String upper = rawIndex.trim().toUpperCase();
      // Handle letter-based answers (A, B, C, D...)
      if (upper.length == 1 &&
          upper.codeUnitAt(0) >= 65 &&
          upper.codeUnitAt(0) <= 90) {
        finalIndex = upper.codeUnitAt(0) - 65;
      } else {
        finalIndex = int.tryParse(upper) ?? 0;
      }
    }

    return Question(
      id: id,
      text: text,
      options: (data['options'] as List? ?? [])
          .map((e) => extractText(e))
          .toList(),
      correctAnswerIndex: finalIndex,
      imageUrl: finalImageUrl,
      promptAudioUrl: finalAudioUrl,
      type: type,
    );
  }
}
