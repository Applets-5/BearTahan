import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionImageMode {
  none,         // text prompt only
  promptImage,  // image illustrates the question
  answerImage,  // answer options are images
}

class Question {
  final String id;
  final String subjectId;
  final String chapterId;
  final String levelId;
  final int levelNumber;
  final int difficulty;
  final QuestionImageMode imageMode;
  final String prompt;
  final String? imageUrl;
  final List<QuestionOption> options;
  final String correctAnswerId;

  const Question({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.levelId,
    required this.levelNumber,
    required this.difficulty,
    required this.imageMode,
    required this.prompt,
    this.imageUrl,
    required this.options,
    required this.correctAnswerId,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      subjectId: data['subjectId'] as String,
      chapterId: data['chapterId'] as String,
      levelId: data['levelId'] as String,
      levelNumber: data['levelNumber'] as int,
      difficulty: data['difficulty'] as int,
      imageMode: QuestionImageMode.values.firstWhere(
        (e) => e.name == (data['imageMode'] as String? ?? 'none'),
        orElse: () => QuestionImageMode.none,
      ),
      prompt: data['prompt'] as String,
      imageUrl: data['imageUrl'] as String?,
      correctAnswerId: data['correctAnswerId'] as String,
      options: (data['options'] as List<dynamic>)
          .map((o) => QuestionOption.fromMap(o as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'chapterId': chapterId,
    'levelId': levelId,
    'levelNumber': levelNumber,
    'difficulty': difficulty,
    'imageMode': imageMode.name,
    'prompt': prompt,
    'imageUrl': imageUrl,
    'correctAnswerId': correctAnswerId,
    'options': options.map((o) => o.toMap()).toList(),
  };
}

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
    id: map['id'] as String,
    text: map['text'] as String,
    imageUrl: map['imageUrl'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'imageUrl': imageUrl,
  };
}