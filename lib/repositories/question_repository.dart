import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bear_tahan/models/question.dart';

class QuestionRepository {
  final FirebaseFirestore _firestore;

  QuestionRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Question>> fetchByLevel(String levelId) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('levelId', isEqualTo: levelId)
        .get();

    return snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<Question>> fetchByLevelAndDifficulty(
    String levelId,
    int difficulty,
  ) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('levelId', isEqualTo: levelId)
        .where('difficulty', isEqualTo: difficulty)
        .get();

    return snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<Question>> fetchByChapter(
    String levelId,
    String chapterId,
  ) async {
    final snapshot = await _firestore
        .collection('questions')
        .where('levelId', isEqualTo: levelId)
        .where('chapterId', isEqualTo: chapterId)
        .get();

    return snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}

// Providers

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(),
);

final questionsByLevelProvider = FutureProvider.family<List<Question>, String>((
  ref,
  levelId,
) {
  return ref.watch(questionRepositoryProvider).fetchByLevel(levelId);
});

final questionsByChapterProvider =
    FutureProvider.family<List<Question>, ({String levelId, String chapterId})>(
      (ref, params) {
        return ref
            .watch(questionRepositoryProvider)
            .fetchByChapter(params.levelId, params.chapterId);
      },
    );
