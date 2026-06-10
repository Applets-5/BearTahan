import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String? promptAudioText;
  final String? type;
  final List<String>? correctOrder;
  final String? correctBlank;
  final String? characterUnicode;
  final String? strokeOrderDataJson;

  const Question({
    required this.id,
    required this.text,
    required List<dynamic> options,
    required this.correctAnswerIndex,
    this.imageUrl,
    this.promptAudioUrl,
    this.promptAudioText,
    this.type,
    this.correctOrder,
    this.correctBlank,
    this.characterUnicode,
    this.strokeOrderDataJson,
  }) : options = options.map((e) {
         if (e is QuestionOption) return e;
         if (e == null) return QuestionOption(text: '');
         if (e is Map) {
           // Handle map-style option
           String optText = '';
           final contentKeys = ['text', 'label', 'value', 'word', 'name'];
           for (var key in contentKeys) {
             if (e.containsKey(key)) {
               optText = e[key]?.toString() ?? '';
               break;
             }
           }
           String? optImg;
           final imageKeys = ['imageUrl', 'image', 'img', 'url', 'picture'];
           for (var key in imageKeys) {
             if (e.containsKey(key)) {
               optImg = e[key]?.toString();
               break;
             }
           }
           return QuestionOption(text: optText, imageUrl: optImg);
         }
         // Fallback for strings or other types
         return QuestionOption(text: e.toString());
       }).toList();

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
    debugPrint('DEBUG: Parsing question document: $id');

    String extractText(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        final contentKeys = ['text', 'label', 'value', 'word', 'name'];
        for (var key in contentKeys) {
          if (value.containsKey(key)) {
            final val = value[key];
            return val?.toString() ?? '';
          }
        }
      }
      return value.toString();
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

    String? finalAudioText =
        data['promptAudioText'] ??
        data['audioText'] ??
        data['ttsText'] ??
        data['spokenText'];

    // Map questionType (used in Firestore) to type
    String? type = (data['questionType'] ?? data['type'])?.toString();

    // correctOrder for rearrange and dragDropSpelling
    List<String>? correctOrder;
    if (data['correctOrder'] is List) {
      correctOrder = (data['correctOrder'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (data['correctOrder'] is String) {
      correctOrder = (data['correctOrder'] as String)
          .split(',')
          .map((e) => e.trim())
          .toList();
    }

    // correctBlank for fillblank
    String? correctBlank = data['correctBlank']?.toString();

    String? strokeOrderDataJson;
    final rawStrokeOrderData = data['strokeOrderData'];
    if (rawStrokeOrderData is String && rawStrokeOrderData.isNotEmpty) {
      strokeOrderDataJson = rawStrokeOrderData;
    } else if (rawStrokeOrderData is Map || rawStrokeOrderData is List) {
      strokeOrderDataJson = jsonEncode(rawStrokeOrderData);
    } else if (data['strokes'] is List && data['medians'] is List) {
      strokeOrderDataJson = jsonEncode({
        'strokes': data['strokes'],
        'medians': data['medians'],
        if (data['radStrokes'] is List) 'radStrokes': data['radStrokes'],
      });
    }

    dynamic rawIndex =
        data['correctanswerid'] ??
        data['correctAnswerIndex'] ??
        data['answerIndex'] ??
        data['correctIndex'] ??
        data['correctAnswer'] ??
        data['answer'] ??
        '';

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
      promptAudioText: finalAudioText,
      type: type,
      correctOrder: correctOrder,
      correctBlank: correctBlank,
      characterUnicode: data['characterUnicode']?.toString(),
      strokeOrderDataJson: strokeOrderDataJson,
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