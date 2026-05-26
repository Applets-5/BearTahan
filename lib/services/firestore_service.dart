import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../utils/streak_utils.dart';

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

    final didImproveStars = await _db.runTransaction<bool>((transaction) async {
      final levelSnapshot = await transaction.get(levelDocRef);
      final childSnapshot = await transaction.get(childDocRef);

      final int previousBestStars = (levelSnapshot.data()?['stars'] ?? 0)
          .toInt();
      final childData = childSnapshot.data() ?? {};
      final int currentBalance =
          (childData['stars'] ?? childData['starBalance'] ?? 0).toInt();

      final childUpdates = <String, dynamic>{};

      final streakResult = StreakUtils.calculateStreak(
        currentStreak: (childData['streakCount'] ?? 0).toInt(),
        lastActivityDate: childData['lastActivityDate'] != null
            ? (childData['lastActivityDate'] as Timestamp).toDate()
            : null,
        now: DateTime.now(),
      );

      if (streakResult.shouldUpdate) {
        childUpdates['streakCount'] = streakResult.newStreak;
        childUpdates['lastActivityDate'] = Timestamp.fromDate(
          streakResult.lastActivityDate,
        );
      }

      final didImprove = stars > previousBestStars;
      if (didImprove) {
        transaction.set(levelDocRef, {'stars': stars}, SetOptions(merge: true));

        final int improvement = stars - previousBestStars;
        final String balanceField = childData.containsKey('stars')
            ? 'stars'
            : 'starBalance';
        childUpdates[balanceField] = currentBalance + improvement;
      }

      if (childUpdates.isNotEmpty) {
        transaction.set(childDocRef, childUpdates, SetOptions(merge: true));
      }

      return didImprove;
    });

    if (!didImproveStars) return;

    final subjectDocRef = childDocRef
        .collection('subjectProgress')
        .doc(subjectId);
    final levelsSnapshot = await subjectDocRef.collection('levels').get();
    final completedLevels = levelsSnapshot.docs.where((doc) {
      return (doc.data()['stars'] ?? 0).toInt() > 0;
    }).length;

    final int progressPercentage = ((completedLevels / 8) * 100).toInt();
    await subjectDocRef.set({
      'progress': progressPercentage,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  Future<void> recordAttempt(
    String parentId,
    String childId, {
    required String subjectId,
    required String levelId,
    required int score,
    required int total,
    required int stars,
    required int timeInSeconds,
  }) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('attempts')
        .add({
          'subjectId': subjectId,
          'levelId': levelId,
          'score': score,
          'total': total,
          'stars': stars,
          'timeInSeconds': timeInSeconds,
          'completedAt': FieldValue.serverTimestamp(),
        });
  }
}
