import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../models/notification.dart';
import '../models/star_transaction.dart';
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

      // Unified star balance field detection
      final String balanceField =
          childData.containsKey('stars') ? 'stars' : 'starBalance';
      final int currentBalance = (childData[balanceField] ?? 0).toInt();

      if (currentBalance < reward.cost) {
        throw Exception('Insufficient stars');
      }

      // Update reward status to pending and record who claimed it
      transaction.update(rewardDocRef, {
        'status': 'pending',
        'claimedByChildId': childId,
      });

      // Deduct stars
      transaction.update(childDocRef, {
        balanceField: currentBalance - reward.cost,
      });

      // Record spend transaction
      final transactionDocRef = childDocRef.collection('starHistory').doc();
      transaction.set(transactionDocRef, {
        'type': 'spend',
        'amount': -reward.cost,
        'description': 'Redeemed ${reward.title}',
        'timestamp': FieldValue.serverTimestamp(),
        'rewardId': reward.id,
      });

      // Create notification for parent
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

  Future<void> approveReward(String parentId, Reward reward) async {
    if (reward.claimedByChildId == null) return;

    final rewardDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('rewards')
        .doc(reward.id);

    await rewardDocRef.update({
      'status': 'redeemed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> declineReward(String parentId, Reward reward) async {
    final childId = reward.claimedByChildId;
    if (childId == null) return;

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

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childDocRef);
      final childData = childSnapshot.data() ?? {};

      // Unified star balance field detection
      final String balanceField =
          childData.containsKey('stars') ? 'stars' : 'starBalance';
      final int currentBalance = (childData[balanceField] ?? 0).toInt();

      // Reset reward to available
      transaction.update(rewardDocRef, {
        'status': 'available',
        'claimedByChildId': FieldValue.delete(),
      });

      // Refund stars
      transaction.update(childDocRef, {
        balanceField: currentBalance + reward.cost,
      });

      // Record refund transaction
      final transactionDocRef = childDocRef.collection('starHistory').doc();
      transaction.set(transactionDocRef, {
        'type': 'earn',
        'amount': reward.cost,
        'description': 'Refund: ${reward.title} (Declined)',
        'timestamp': FieldValue.serverTimestamp(),
        'rewardId': reward.id,
      });
    });
  }

  Stream<List<StarTransaction>> streamStarTransactions(
    String parentId,
    String childId,
  ) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('starHistory')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StarTransaction.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  String _getSubjectName(String id) {
    switch (id) {
      case 'bm':
        return 'Bahasa Melayu';
      case 'en':
        return 'English';
      case 'bc':
        return 'Mandarin';
      case 'math':
        return 'Mathematics';
      case 'science':
        return 'Science';
      default:
        return id.toUpperCase();
    }
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

    final subjectDocRef = childDocRef
        .collection('subjectProgress')
        .doc(subjectId);

    final levelDocRef = subjectDocRef
        .collection('levels')
        .doc(levelId);

    try {
      bool shouldForceSync = false;

      await _db.runTransaction((transaction) async {
        final levelSnapshot = await transaction.get(levelDocRef);
        final childSnapshot = await transaction.get(childDocRef);
        final subjectSnapshot = await transaction.get(subjectDocRef);

        final int previousBestStars = (levelSnapshot.data()?['stars'] ?? 0)
            .toInt();
        final childData = childSnapshot.data() ?? {};
        final int currentBalance =
            (childData['stars'] ?? childData['starBalance'] ?? 0).toInt();

        final subjectData = subjectSnapshot.data() ?? {};
        
        // If the subject document is missing aggregation fields, 
        // we should force a full sync after this transaction.
        if (!subjectData.containsKey('totalStars') || !subjectData.containsKey('completedLevels')) {
          shouldForceSync = true;
        }

        int currentTotalStars = (subjectData['totalStars'] ?? 0).toInt();
        int currentCompletedLevels = (subjectData['completedLevels'] ?? 0).toInt();

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
          // Update level stars
          transaction.set(levelDocRef, {
            'stars': stars,
          }, SetOptions(merge: true));

          // Update aggregated subject progress incrementally
          final int improvement = stars - previousBestStars;
          currentTotalStars += improvement;
          
          if (previousBestStars == 0) {
            currentCompletedLevels++;
          }

          final int progressPercentage = ((currentCompletedLevels / 8) * 100).toInt();
          
          transaction.set(subjectDocRef, {
            'progress': progressPercentage,
            'completedLevels': currentCompletedLevels,
            'totalStars': currentTotalStars,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Update child star balance
          final String balanceField = childData.containsKey('stars')
              ? 'stars'
              : 'starBalance';
          childUpdates[balanceField] = currentBalance + improvement;

          // Record earn transaction
          final transactionDocRef = childDocRef.collection('starHistory').doc();
          transaction.set(transactionDocRef, {
            'type': 'earn',
            'amount': improvement,
            'description': 'Learned ${_getSubjectName(subjectId)} (${levelId.toUpperCase()})',
            'timestamp': FieldValue.serverTimestamp(),
            'subjectId': subjectId,
            'levelId': levelId,
          });
        }

        if (childUpdates.isNotEmpty) {
          transaction.set(childDocRef, childUpdates, SetOptions(merge: true));
        }
      });

      // If we detected missing aggregation data, perform a full sync now.
      if (shouldForceSync) {
        debugPrint('DEBUG: Forcing full subject sync for $subjectId');
        await syncSubjectAggregation(parentId, childId, subjectId);
      }

      debugPrint('DEBUG: updateLevelProgress complete.');
    } catch (e) {
      debugPrint('DEBUG ERROR: updateLevelProgress failed: $e');
    }
  }

  /// Performs a full scan of all subjects for a child and updates the 
  /// aggregation documents. This is a one-time repair for legacy data.
  Future<void> repairSubjectProgress(String parentId, String childId) async {
    final subjects = ['bm', 'en', 'bc', 'math', 'science'];

    for (final subjectId in subjects) {
      await syncSubjectAggregation(parentId, childId, subjectId);
    }
  }

  /// Performs a full scan of the levels subcollection and updates the 
  /// subject aggregation document. This is used to bootstrap legacy data.
  Future<void> syncSubjectAggregation(
    String parentId,
    String childId,
    String subjectId,
  ) async {
    final subjectDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .doc(subjectId);

    // Get all levels for this subject to calculate true totals
    final levelsSnapshot = await subjectDocRef.collection('levels').get();
    
    int totalStarsCount = 0;
    int completedLevels = 0;
    
    for (var doc in levelsSnapshot.docs) {
      // Get the actual stars (0-3) earned for this specific level
      final starsEarned = (doc.data()['stars'] ?? 0) as num;
      if (starsEarned > 0) {
        completedLevels++;
        totalStarsCount += starsEarned.toInt();
      }
    }

    // Progress is based on total levels (min 8)
    final int totalLevels = levelsSnapshot.docs.length > 8 ? levelsSnapshot.docs.length : 8;
    final int progressPercentage = ((completedLevels / totalLevels) * 100).toInt().clamp(0, 100);
    
    await subjectDocRef.set({
      'progress': progressPercentage,
      'completedLevels': completedLevels,
      'totalStars': totalStarsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    debugPrint('DEBUG: Subject $subjectId repaired. Total Stars: $totalStarsCount, Completed: $completedLevels');
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
