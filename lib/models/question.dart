import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String subjectId;
  final String chapterId;
  final String levelId;
  final int difficulty;
  final String prompt;
  final List<QuestionOption> options;
  final String correctAnswerId;

  const Question({
    required this.id,
    required this.subjectId,
    required this.chapterId,
    required this.levelId,
    required this.difficulty,
    required this.prompt,
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
      difficulty: data['difficulty'] as int,
      prompt: data['prompt'] as String,
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
    'difficulty': difficulty,
    'prompt': prompt,
    'correctAnswerId': correctAnswerId,
    'options': options.map((o) => o.toMap()).toList(),
  };
}

class QuestionOption {
  final String id;
  final String text;

  const QuestionOption({required this.id, required this.text});

  factory QuestionOption.fromMap(Map<String, dynamic> map) =>
      QuestionOption(id: map['id'] as String, text: map['text'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'text': text};
}