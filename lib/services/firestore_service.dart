import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserProfile> streamUserProfile(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserProfile.fromFirestore(doc.id, doc.data() ?? {}));
  }

  Stream<List<Subject>> streamSubjectProgress(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('subjectProgress')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subject.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<List<Question>> getQuestions(String prefix) async {
    final snapshot = await _db
        .collection('questions')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThan: prefix + '\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateLevelProgress(String uid, String subjectId, String levelId, int stars) async {
    final levelDocRef = _db
        .collection('users')
        .doc(uid)
        .collection('subjectProgress')
        .doc(subjectId)
        .collection('levels')
        .doc(levelId);

    final userDocRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      final levelSnapshot = await transaction.get(levelDocRef);
      final userSnapshot = await transaction.get(userDocRef);

      final int previousStars = (levelSnapshot.data()?['stars'] ?? 0).toInt();
      final int currentBalance = (userSnapshot.data()?['starBalance'] ?? 0).toInt();

      // Update level stars to latest result as requested
      transaction.set(levelDocRef, {'stars': stars}, SetOptions(merge: true));

      // Only increment balance if they improved their best score for this level
      if (stars > previousStars) {
        final int improvement = stars - previousStars;
        transaction.update(userDocRef, {'starBalance': currentBalance + improvement});
      }
    });
  }

  Stream<Map<String, int>> streamLevelStars(String uid, String subjectId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('subjectProgress')
        .doc(subjectId)
        .collection('levels')
        .snapshots()
        .map((snapshot) {
      final Map<String, int> stars = {};
      for (var doc in snapshot.docs) {
        stars[doc.id] = (doc.data()['stars'] ?? 0).toInt();
      }
      return stars;
    });
  }

  Future<void> seedMockData(String uid) async {
    try {
      print('Seeding mock data for user: $uid');
      // Set user profile
      await _db.collection('users').doc(uid).set({
        'name': 'Adryan',
        'starBalance': 150,
        'activeMascotOutfit': 'Hero Cape',
        'parentId': 'scKBgki4JkM7fBSsQDXUgo58Dnl1',
      }, SetOptions(merge: true));
      print('User profile seeded successfully');

      // Set subject progress
      final subjects = [
        {
          'id': 'bm',
          'name': 'Bahasa Melayu',
          'subtitle': 'Membaca & Menulis',
          'icon': 'edit_rounded',
          'color': 'bm',
          'progress': 45,
        },
        {
          'id': 'english',
          'name': 'English',
          'subtitle': 'Reading & Writing',
          'icon': 'menu_book_rounded',
          'color': 'english',
          'progress': 30,
        },
        {
          'id': 'mandarin',
          'name': 'Mandarin',
          'subtitle': 'Chinese characters',
          'icon': 'translate_rounded',
          'color': 'mandarin',
          'progress': 20,
        },
        {
          'id': 'math',
          'name': 'Mathematics',
          'subtitle': 'Numbers & shapes',
          'icon': 'calculate_rounded',
          'color': 'math',
          'progress': 55,
        },
        {
          'id': 'science',
          'name': 'Science',
          'subtitle': 'Explore & discover',
          'icon': 'science_rounded',
          'color': 'science',
          'progress': 25,
        },
      ];

      for (var subject in subjects) {
        final id = subject.remove('id') as String;
        await _db
            .collection('users')
            .doc(uid)
            .collection('subjectProgress')
            .doc(id)
            .set(subject, SetOptions(merge: true));
        print('Subject seeded: $id');
      }
      print('All mock data seeded successfully');
    } catch (e) {
      print('Error seeding mock data: $e');
      rethrow;
    }
  }
}
