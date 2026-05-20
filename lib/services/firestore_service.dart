import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Reward>> streamRewards(String parentId) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('rewards')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reward.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addReward(String parentId, Reward reward) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('rewards')
        .add(reward.toFirestore());
  }

  Future<void> updateReward(String parentId, Reward reward) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('rewards')
        .doc(reward.id)
        .update(reward.toFirestore());
  }

  Future<void> deleteReward(String parentId, String rewardId) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('rewards')
        .doc(rewardId)
        .delete();
  }

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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Subject.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<Question>> getQuestions(String prefix) async {
    final snapshot = await _db
        .collection('questions')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
        .where(FieldPath.documentId, isLessThan: '$prefix\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Stream<Map<String, dynamic>> streamParentSettings(String parentId) {
    return _db.collection('parents').doc(parentId).snapshots().map((doc) {
      return doc.data() ?? {};
    });
  }

  Future<void> updateParentSettings(
    String parentId,
    Map<String, dynamic> settings,
  ) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .set(settings, SetOptions(merge: true));
  }

  Future<void> updateLevelProgress(
    String parentId,
    String childId,
    String subjectId,
    String levelId,
    int stars,
  ) async {
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

      final int previousBestStars = (levelSnapshot.data()?['stars'] ?? 0)
          .toInt();
      final childData = childSnapshot.data() ?? {};
      final int currentBalance =
          (childData['stars'] ?? childData['starBalance'] ?? 0).toInt();

      // Streak Logic
      int newStreak = (childData['streakCount'] ?? 0).toInt();
      final Timestamp? lastActivityTimestamp =
          childData['lastActivityDate'] as Timestamp?;
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      if (lastActivityTimestamp == null) {
        // First time activity
        newStreak = 1;
        transaction.update(childDocRef, {
          'streakCount': newStreak,
          'lastActivityDate': Timestamp.fromDate(today),
        });
      } else {
        final DateTime lastActivity = lastActivityTimestamp.toDate();
        final DateTime lastActivityDay = DateTime(
          lastActivity.year,
          lastActivity.month,
          lastActivity.day,
        );
        final difference = today.difference(lastActivityDay).inDays;

        if (difference == 1) {
          // Consecutive day
          newStreak += 1;
          transaction.update(childDocRef, {
            'streakCount': newStreak,
            'lastActivityDate': Timestamp.fromDate(today),
          });
        } else if (difference > 1) {
          // Missed days, reset streak
          newStreak = 1;
          transaction.update(childDocRef, {
            'streakCount': newStreak,
            'lastActivityDate': Timestamp.fromDate(today),
          });
        }
        // If difference == 0 (same day), we don't change streak or date
      }

      // Logic: Status of level remains highest stars
      if (stars > previousBestStars) {
        transaction.set(levelDocRef, {'stars': stars}, SetOptions(merge: true));

        // Total star count increment by difference
        final int improvement = stars - previousBestStars;
        final String balanceField = childData.containsKey('stars')
            ? 'stars'
            : 'starBalance';
        transaction.update(childDocRef, {
          balanceField: currentBalance + improvement,
        });

        // Update subject progress
        final subjectDocRef = childDocRef
            .collection('subjectProgress')
            .doc(subjectId);
        final levelsSnapshot = await childDocRef
            .collection('subjectProgress')
            .doc(subjectId)
            .collection('levels')
            .get();

        // Count how many levels have at least 1 star
        int completedLevels = 0;
        final Map<String, int> starMap = {};
        for (var doc in levelsSnapshot.docs) {
          final s = (doc.data()['stars'] ?? 0).toInt();
          starMap[doc.id] = s;
          if (s > 0) completedLevels++;
        }

        // Ensure the current level is counted if it was just updated and not yet in levelsSnapshot
        if (stars > 0 && (starMap[levelId] ?? 0) == 0) {
          completedLevels++;
        }

        final int progressPercentage = ((completedLevels / 8) * 100).toInt();
        transaction.set(subjectDocRef, {
          'progress': progressPercentage,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Stream<Map<String, int>> streamLevelStars(
    String parentId,
    String childId,
    String subjectId,
  ) {
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
}
