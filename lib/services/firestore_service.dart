import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../models/notification.dart';
import '../utils/streak_utils.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

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

  Future<void> claimReward(
    String parentId,
    String childId,
    Reward reward,
    String childName,
  ) async {
    final rewardDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('rewards')
        .doc(reward.id);
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);
    final notificationColRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('notifications');

    await _db.runTransaction((transaction) async {
          final childSnapshot = await transaction.get(childDocRef);
          final childData = childSnapshot.data() ?? {};

          // Always use 'stars' as the canonical field — created in create_profile_screen.dart
          final int currentBalance = (childData['stars'] ?? 0).toInt();

          if (currentBalance < reward.cost) {
            throw Exception('Insufficient stars');
          }

          // Update reward status to pending
          transaction.update(rewardDocRef, {'status': 'pending'});

          // Deduct stars using the canonical field name
          transaction.update(childDocRef, {
            'stars': currentBalance - reward.cost,
          });

      // Create notification
      final notification = ParentNotification(
        id: '',
        title: '$childName wants to redeem ${reward.title}',
        type: 'reward',
        timestamp: DateTime.now(),
        childId: childId,
        childName: childName,
      );
      transaction.set(notificationColRef.doc(), notification.toFirestore());
    });
  }

  Stream<List<ParentNotification>> streamNotifications(String parentId) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ParentNotification.fromFirestore(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(
    String parentId,
    String notificationId,
  ) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<List<UserProfile>> streamChildren(String parentId) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // Normalize: always map 'stars' -> 'starBalance' for the model
            data['starBalance'] = (data['stars'] ?? data['starBalance'] ?? 0);
            return UserProfile.fromFirestore(doc.id, data);
          }).toList(),
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
          // Normalize: always map 'stars' -> 'starBalance' for the model
          data['starBalance'] = (data['stars'] ?? data['starBalance'] ?? 0);
          return UserProfile.fromFirestore(doc.id, data);
        });
  }

Stream<List<Subject>> streamSubjectProgress(String parentId, String childId) {
  debugPrint('DEBUG: streamSubjectProgress called - parentId: $parentId, childId: $childId');
  return _db
      .collection('parents')
      .doc(parentId)
      .collection('children')
      .doc(childId)
      .collection('subjectProgress')
      .snapshots()
      .map(
        (snapshot) {
          debugPrint('DEBUG: subjectProgress snapshot - docs count: ${snapshot.docs.length}');
          for (var doc in snapshot.docs) {
            debugPrint('DEBUG: subjectProgress doc id: ${doc.id}, data: ${doc.data()}');
          }
          return snapshot.docs
              .map((doc) => Subject.fromFirestore(doc.id, doc.data()))
              .toList();
        },
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
  debugPrint(
    'DEBUG: updateLevelProgress for child: $childId, subject: $subjectId, level: $levelId, stars: $stars',
  );

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

  try {
    final didImproveStars = await _db.runTransaction<bool>((transaction) async {
      final levelSnapshot = await transaction.get(levelDocRef);
      final childSnapshot = await transaction.get(childDocRef);

      final int previousBestStars =
          (levelSnapshot.data()?['stars'] ?? 0).toInt();
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
        childUpdates['lastActivityDate'] =
            Timestamp.fromDate(streakResult.lastActivityDate);
      }

      final didImprove = stars > previousBestStars;
      if (didImprove) {
        transaction.set(
          levelDocRef,
          {'stars': stars},
          SetOptions(merge: true),
        );

        final int improvement = stars - previousBestStars;
        childUpdates['stars'] = currentBalance + improvement;
      }

      if (childUpdates.isNotEmpty) {
        debugPrint('DEBUG: Transaction child updates: $childUpdates');
        transaction.set(childDocRef, childUpdates, SetOptions(merge: true));
      }

      return didImprove;
    });

    debugPrint(
      'DEBUG: updateLevelProgress transaction complete. didImprove: $didImproveStars',
    );

    if (!didImproveStars) return;

    final subjectDocRef =
        childDocRef.collection('subjectProgress').doc(subjectId);
    final levelsSnapshot = await subjectDocRef.collection('levels').get();

    int totalStarsCount = 0;
    int completedLevels = 0;

    for (var doc in levelsSnapshot.docs) {
      final levelStars = (doc.data()['stars'] ?? 0) as num;
      if (levelStars > 0) {
        completedLevels++;
        totalStarsCount += levelStars.toInt();
      }
    }

    final int totalLevels =
        levelsSnapshot.docs.length > 8 ? levelsSnapshot.docs.length : 8;
    final int progressPercentage =
        ((completedLevels / totalLevels) * 100).toInt().clamp(0, 100);

    await subjectDocRef.set({
      'progress': progressPercentage,
      'completedLevels': completedLevels,
      'totalStars': totalStarsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint(
      'DEBUG: Subject progress updated: $progressPercentage% '
      '($completedLevels/$totalLevels levels, $totalStarsCount stars)',
    );
  } catch (e) {
    debugPrint('DEBUG ERROR: updateLevelProgress failed: $e');
  }
}

  Stream<Map<String, int>> streamLevelStars(
    String parentId,
    String childId,
    String subjectId,
  ) {
    debugPrint(
      'DEBUG: streamLevelStars for child: $childId, subject: $subjectId',
    );
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
          debugPrint('DEBUG: Emitted stars: $stars');
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
