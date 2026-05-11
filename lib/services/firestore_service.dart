import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';

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
