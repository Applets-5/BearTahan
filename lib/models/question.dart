import 'package:flutter/foundation.dart';

class QuestionOption {
  final String text;
  final String? imageUrl;

  QuestionOption({required this.text, this.imageUrl});
}

class Question {
  final String id;
  final String text;
  final List<QuestionOption> options;
  final int correctAnswerIndex;
  final String? imageUrl;
  final String? promptAudioUrl;
  final String? type;
  final List<String>? correctOrder;
  final String? correctBlank;

  Question({
    required this.id,
    required this.text,
    required List<dynamic> options,
    required this.correctAnswerIndex,
    this.imageUrl,
    this.promptAudioUrl,
    this.type,
    this.correctOrder,
    this.correctBlank,
  }) : this.options = options.map((e) {
          if (e is QuestionOption) return e;
          return QuestionOption(text: e.toString());
        }).toList();

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
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

    String? extractImageUrl(dynamic value) {
      if (value is Map) {
        final imageKeys = ['imageUrl', 'image', 'img', 'url', 'picture'];
        for (var key in imageKeys) {
          if (value.containsKey(key)) return value[key]?.toString();
        }
      }
      return null;
    }

    String text = extractText(
      data['text'] ??
          data['questionText'] ??
          data['question'] ??
          data['prompt'] ??
          data['q'] ??
          '',
    );

    dynamic rawImage =
        data['imageUrl'] ?? data['image'] ?? data['img'] ?? data['picture'];
    String? finalImageUrl;
    if (rawImage is String) {
      finalImageUrl = rawImage;
    } else if (rawImage is Map) {
      finalImageUrl = extractImageUrl(rawImage);
    }

    String? finalAudioUrl =
        data['promptAudioUrl'] ??
        data['promptAudioURL'] ??
        data['audioUrl'] ??
        data['audioURL'] ??
        data['audio_url'] ??
        data['audio'] ??
        data['voice'];

    // Map questionType (used in Firestore) to type
    String? type = (data['questionType'] ?? data['type'])?.toString();

    // correctOrder for rearrange
    List<String>? correctOrder;
    if (data['correctOrder'] is List) {
      correctOrder = (data['correctOrder'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // correctBlank for fillblank
    String? correctBlank = data['correctBlank']?.toString();

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
    } else if (rawIndex is String && rawIndex.isNotEmpty) {
      String upper = rawIndex.trim().toUpperCase();
      if (upper.length == 1 &&
          upper.codeUnitAt(0) >= 65 &&
          upper.codeUnitAt(0) <= 90) {
        finalIndex = upper.codeUnitAt(0) - 65;
      } else {
        finalIndex = int.tryParse(upper) ?? 0;
      }
    } else if (type == 'fillblank' && correctBlank != null) {
      // Find index of correctBlank in options
      final rawOptions = data['options'] as List? ?? [];
      for (int i = 0; i < rawOptions.length; i++) {
        if (extractText(rawOptions[i]) == correctBlank) {
          finalIndex = i;
          break;
        }
      }
    }

    final rawOptions = data['options'] as List? ?? [];
    final List<QuestionOption> parsedOptions = rawOptions.map((e) {
      return QuestionOption(text: extractText(e), imageUrl: extractImageUrl(e));
    }).toList();

    return Question(
      id: id,
      text: text,
      options: parsedOptions,
      correctAnswerIndex: finalIndex,
      imageUrl: finalImageUrl,
      promptAudioUrl: finalAudioUrl,
      type: type,
      correctOrder: correctOrder,
      correctBlank: correctBlank,
    );
  }
}
