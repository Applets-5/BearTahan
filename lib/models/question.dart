import 'dart:convert';

class QuestionOption {
  final String text;
  final String? imageUrl;
  final String? pairText;
  final String? pairImageUrl;

  QuestionOption({
    required this.text,
    this.imageUrl,
    this.pairText,
    this.pairImageUrl,
  });
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
  final int? correctNumber;

  Question({
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
    this.correctNumber,
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

           String? pText;
           if (e.containsKey('pairText')) {
             pText = e['pairText']?.toString();
           } else if (e.containsKey('matchText')) {
             pText = e['matchText']?.toString();
           }

           String? pImg;
           if (e.containsKey('pairImageUrl')) {
             pImg = e['pairImageUrl']?.toString();
           } else if (e.containsKey('pairImage')) {
             pImg = e['pairImage']?.toString();
           } else if (e.containsKey('matchImageUrl')) {
             pImg = e['matchImageUrl']?.toString();
           }

           return QuestionOption(
             text: optText,
             imageUrl: optImg,
             pairText: pText,
             pairImageUrl: pImg,
           );
         }
         // Fallback for strings or other types
         return QuestionOption(text: e.toString());
       }).toList();

  factory Question.fromFirestore(String id, Map<String, dynamic> data) {
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

    String? extractPairText(dynamic value) {
      if (value is Map) {
        if (value.containsKey('pairText')) return value['pairText']?.toString();
        if (value.containsKey('matchText')) {
          return value['matchText']?.toString();
        }
      }
      return null;
    }

    String? extractPairImageUrl(dynamic value) {
      if (value is Map) {
        if (value.containsKey('pairImageUrl')) {
          return value['pairImageUrl']?.toString();
        }
        if (value.containsKey('pairImage')) {
          return value['pairImage']?.toString();
        }
        if (value.containsKey('matchImageUrl')) {
          return value['matchImageUrl']?.toString();
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

    String? finalAudioText =
        data['promptAudioText'] ??
        data['audioText'] ??
        data['ttsText'] ??
        data['spokenText'];

    // Map questionType (used in Firestore) to type
    String? type = (data['questionType'] ?? data['type'])?.toString();
    final normalizedType = type?.toLowerCase();

    // correctOrder for rearrange and dragDropSpelling
    List<String>? correctOrder;
    if (data['correctOrder'] is List) {
      correctOrder = (data['correctOrder'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (data['correctOrder'] is String) {
      final String str = data['correctOrder'] as String;

      // Robust matching against actual options to preserve punctuation
      final rawOptions = data['options'] as List? ?? [];
      final List<QuestionOption> availableOptions = rawOptions.map((e) {
        return QuestionOption(
          text: extractText(e),
          imageUrl: extractImageUrl(e),
          pairText: extractPairText(e),
          pairImageUrl: extractPairImageUrl(e),
        );
      }).toList();

      String normalize(String s) {
        // Remove common punctuation and spaces for comparison
        return s.toLowerCase().replaceAll(RegExp(r'[ ,.!?;:|，。！？；：]'), '');
      }

      // Split by common delimiters
      final segments = str
          .split(RegExp(r'\s*[,;|]\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final List<String> resolvedOrder = [];
      final List<QuestionOption> optionsPool = List.from(availableOptions);

      for (final segment in segments) {
        final normSegment = normalize(segment);
        if (normSegment.isEmpty) continue;

        // Try exact match first
        int matchIndex = optionsPool.indexWhere(
          (o) => o.text.trim() == segment,
        );

        // Fallback to normalized match
        if (matchIndex == -1) {
          matchIndex = optionsPool.indexWhere(
            (o) => normalize(o.text) == normSegment,
          );
        }

        if (matchIndex != -1) {
          resolvedOrder.add(optionsPool[matchIndex].text);
          optionsPool.removeAt(matchIndex);
        } else {
          resolvedOrder.add(segment);
        }
      }
      correctOrder = resolvedOrder;
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
        data['correctAnswerId'] ??
        data['correctAnswerIndex'] ??
        data['answerIndex'] ??
        data['correctIndex'] ??
        data['correctAnswer'] ??
        data['answer'];

    int? correctNumber;
    if (normalizedType == 'keyinnumber') {
      final rawNumber =
          data['correctNumber'] ??
          data['correctAnswer'] ??
          data['correctanswerid'] ??
          data['correctAnswerId'] ??
          data['correctBlank'] ??
          data['answer'];
      correctNumber = rawNumber is num
          ? rawNumber.toInt()
          : int.tryParse(rawNumber?.toString().trim() ?? '');
    }

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
    }

    // For fillblank, correctBlank is a more reliable source of truth than a potentially stale index
    if ((normalizedType == 'fillblank' ||
            normalizedType == 'fillblanklistening') &&
        correctBlank != null) {
      final rawOptions = data['options'] as List? ?? [];
      for (int i = 0; i < rawOptions.length; i++) {
        if (extractText(rawOptions[i]).trim().toLowerCase() ==
            correctBlank.trim().toLowerCase()) {
          finalIndex = i;
          break;
        }
      }
    }

    final rawOptions = data['options'] as List? ?? [];
    final List<QuestionOption> parsedOptions = rawOptions.map((e) {
      return QuestionOption(
        text: extractText(e),
        imageUrl: extractImageUrl(e),
        pairText: extractPairText(e),
        pairImageUrl: extractPairImageUrl(e),
      );
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
      correctNumber: correctNumber,
    );
  }
}
