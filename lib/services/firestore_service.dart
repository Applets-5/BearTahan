import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<UserProfile> streamUserProfile(String parentId, String childId) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .snapshots()
        .map((doc) {
      final data = doc.data() ?? {};
      // Map 'stars' to 'starBalance' if that's what's used in the DB
      if (data.containsKey('stars') && !data.containsKey('starBalance')) {
        data['starBalance'] = data['stars'];
      }
      return UserProfile.fromFirestore(doc.id, data);
    });
  }

  Stream<List<Subject>> streamSubjectProgress(String parentId, String childId) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
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

  Future<void> updateLevelProgress(String parentId, String childId, String subjectId, String levelId, int stars) async {
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);

    final levelDocRef = childDocRef
        .collection('subjectProgress')
        .doc(subjectId)
        .collection('levels')
        .doc(levelId);

    await _db.runTransaction((transaction) async {
      final levelSnapshot = await transaction.get(levelDocRef);
      final childSnapshot = await transaction.get(childDocRef);

      final int previousBestStars = (levelSnapshot.data()?['stars'] ?? 0).toInt();
      final childData = childSnapshot.data() ?? {};
      final int currentBalance = (childData['stars'] ?? childData['starBalance'] ?? 0).toInt();

      // Logic: Status of level remains highest stars
      if (stars > previousBestStars) {
        transaction.set(levelDocRef, {'stars': stars}, SetOptions(merge: true));
        
        // Total star count increment by difference
        final int improvement = stars - previousBestStars;
        final String balanceField = childData.containsKey('stars') ? 'stars' : 'starBalance';
        transaction.update(childDocRef, {balanceField: currentBalance + improvement});
      }
      // If stars <= previousBestStars, we do nothing (keep highest stars and don't change balance)
    });
  }

  Stream<Map<String, int>> streamLevelStars(String parentId, String childId, String subjectId) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
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
        'name': 'Olaf',
        'starBalance': 2,
        'activeMascotOutfit': 'Hero Cape',
        'parentId': 'scKBgki4JkM7fBSsQDXUgo58Dnl1',
      }, SetOptions(merge: true));
      print('User profile seeded successfully');

      // Set level 1 progress for BM to 2 stars
      await _db
          .collection('users')
          .doc(uid)
          .collection('subjectProgress')
          .doc('bm')
          .collection('levels')
          .doc('l1')
          .set({'stars': 2}, SetOptions(merge: true));

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
