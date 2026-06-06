import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../models/reward_claim.dart';
import '../models/notification.dart';
import '../models/outfit_quest.dart';
import '../models/star_transaction.dart';
import '../utils/streak_utils.dart';
import '../utils/quest_utils.dart';

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
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);
    final claimColRef = childDocRef.collection('rewardClaims');
    final notificationColRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('notifications');

    final existingPendingClaim = await claimColRef
        .where('rewardId', isEqualTo: reward.id)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingPendingClaim.docs.isNotEmpty) {
      throw Exception('Reward claim already pending');
    }

    final claimDocRef = claimColRef.doc();

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childDocRef);
      final childData = childSnapshot.data() ?? {};

      final int currentBalance =
          (childData['availableStars'] ??
                  childData['starBalance'] ??
                  childData['stars'] ??
                  0)
              .toInt();

      if (currentBalance < reward.cost) {
        throw Exception('Insufficient stars');
      }

      transaction.set(claimDocRef, {
        'parentId': parentId,
        'childId': childId,
        'childName': childName,
        'rewardId': reward.id,
        'rewardName': reward.title,
        'rewardDescription': reward.description,
        'starCost': reward.cost,
        'status': 'pending',
        'claimedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });

      final notification = ParentNotification(
        id: '',
        title: '$childName wants to redeem ${reward.title}',
        type: 'reward',
        timestamp: DateTime.now(),
        childId: childId,
        childName: childName,
      );
      transaction.set(notificationColRef.doc(), {
        ...notification.toFirestore(),
        'payload': {
          'type': 'reward_claimed',
          'rewardName': reward.title,
          'starCost': reward.cost,
          'childName': childName,
          'childId': childId,
        },
      });
    });
  }

  Future<void> approveRewardClaim(String parentId, RewardClaim claim) async {
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(claim.childId);
    final claimDocRef = childDocRef.collection('rewardClaims').doc(claim.id);

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childDocRef);
      final claimSnapshot = await transaction.get(claimDocRef);
      final childData = childSnapshot.data() ?? {};
      final claimData = claimSnapshot.data() ?? {};

      if (claimData['status'] != 'pending') {
        throw Exception('Reward claim is no longer pending');
      }

      final availableStars =
          (childData['availableStars'] ??
                  childData['starBalance'] ??
                  childData['stars'] ??
                  0)
              .toInt();
      final starCost = (claimData['starCost'] ?? claim.starCost).toInt();
      final lifetimeStarsEarned =
          (childData['lifetimeStarsEarned'] ??
                  childData['starBalance'] ??
                  childData['stars'] ??
                  availableStars)
              .toInt();

      if (availableStars < starCost) {
        throw Exception('Insufficient available stars');
      }

      transaction.update(childDocRef, {
        'availableStars': availableStars - starCost,
        'lifetimeStarsEarned': lifetimeStarsEarned,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final transactionDocRef = childDocRef
          .collection('starTransactions')
          .doc();
      transaction.set(transactionDocRef, {
        'type': 'spend',
        'source': 'reward_redemption',
        'sourceID': claim.rewardId,
        'amount': starCost,
        'description': '${claim.rewardName} redeemed',
        'timestamp': FieldValue.serverTimestamp(),
        'rewardId': claim.rewardId,
      });

      transaction.update(claimDocRef, {
        'status': 'approved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRewardClaim(String parentId, RewardClaim claim) async {
    final claimDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(claim.childId)
        .collection('rewardClaims')
        .doc(claim.id);

    await claimDocRef.update({
      'status': 'rejected',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<RewardClaim>> streamRewardClaims(
    String parentId,
    String childId,
  ) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('rewardClaims')
        .orderBy('claimedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RewardClaim.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
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
        .collection('starTransactions')
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

  CollectionReference<Map<String, dynamic>> get _outfitQuestsRef =>
      _db.collection('outfitQuests');

  DocumentReference<Map<String, dynamic>> _childDocRef(
    String parentId,
    String childId,
  ) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);
  }

  Future<void> seedDefaultOutfitQuests({bool overwrite = false}) async {
    final batch = _db.batch();
    var writeCount = 0;

    for (final quest in OutfitQuest.defaults) {
      final docRef = _outfitQuestsRef.doc(quest.id);
      final snapshot = await docRef.get();
      if (overwrite || !snapshot.exists) {
        batch.set(docRef, quest.toFirestore(), SetOptions(merge: true));
        writeCount++;
      }
    }

    if (writeCount > 0) {
      await batch.commit();
    }
  }

  Stream<List<OutfitQuest>> streamOutfitQuests() {
    return _outfitQuestsRef.orderBy('displayOrder').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return OutfitQuest.defaults;
      }

      return snapshot.docs
          .map((doc) => OutfitQuest.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<Map<String, OutfitQuestProgress>> streamQuestProgress(
    String parentId,
    String childId,
  ) {
    return _childDocRef(
      parentId,
      childId,
    ).collection('questProgress').snapshots().map((snapshot) {
      return {
        for (final doc in snapshot.docs)
          doc.id: OutfitQuestProgress.fromFirestore(doc.id, doc.data()),
      };
    });
  }

  Future<void> setActiveOutfit(
    String parentId,
    String childId,
    String outfitId,
  ) async {
    final progressDoc = await _childDocRef(
      parentId,
      childId,
    ).collection('questProgress').doc(outfitId).get();

    final isScholarBear = outfitId == 'scholar_bear';
    final isUnlocked =
        isScholarBear || progressDoc.data()?['isUnlocked'] == true;

    if (!isUnlocked) {
      throw Exception('This outfit is still locked.');
    }

    await _childDocRef(parentId, childId).set({
      'activeOutfitID': outfitId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<String>> evaluateAndUpdateQuestProgress(
    String parentId,
    String childId,
  ) async {
    final childDocRef = _childDocRef(parentId, childId);

    final questSnapshot = await _outfitQuestsRef.orderBy('displayOrder').get();
    final quests = questSnapshot.docs.isEmpty
        ? OutfitQuest.defaults
        : questSnapshot.docs
              .map((doc) => OutfitQuest.fromFirestore(doc.id, doc.data()))
              .toList();

    final childSnapshot = await childDocRef.get();
    final childData = childSnapshot.data() ?? {};
    final lifetimeStarsEarned =
        (childData['lifetimeStarsEarned'] ??
                childData['availableStars'] ??
                childData['starBalance'] ??
                childData['stars'] ??
                0)
            .toInt();

    final subjectProgressSnapshot = await childDocRef
        .collection('subjectProgress')
        .get();
    final subjectProgress = {
      for (final doc in subjectProgressSnapshot.docs) doc.id: doc.data(),
    };

    final attemptsSnapshot = await childDocRef.collection('attempts').get();
    final attempts = attemptsSnapshot.docs.map((doc) => doc.data()).toList();

    final existingProgressSnapshot = await childDocRef
        .collection('questProgress')
        .get();
    final existingProgress = {
      for (final doc in existingProgressSnapshot.docs) doc.id: doc.data(),
    };

    final batch = _db.batch();
    final newlyUnlocked = <String>[];

    for (final quest in quests) {
      final currentValue = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: lifetimeStarsEarned,
        subjectProgress: subjectProgress,
        attempts: attempts,
      );

      final existingData = existingProgress[quest.id] ?? {};
      final wasUnlocked = existingData['isUnlocked'] == true;
      final shouldUnlock = QuestUtils.isQuestUnlocked(
        quest: quest,
        currentValue: currentValue,
        wasUnlocked: wasUnlocked,
      );
      final isNewUnlock = QuestUtils.isNewUnlock(
        quest: quest,
        currentValue: currentValue,
        wasUnlocked: wasUnlocked,
      );

      if (isNewUnlock) {
        newlyUnlocked.add(quest.id);
      }

      batch.set(
        childDocRef.collection('questProgress').doc(quest.id),
        {
          'outfitID': quest.id,
          'outfitName': quest.name,
          'conditionType': quest.conditionType,
          if (quest.subjectId != null) 'subjectId': quest.subjectId,
          'currentValue': currentValue,
          'targetValue': quest.target,
          'isUnlocked': shouldUnlock,
          'updatedAt': FieldValue.serverTimestamp(),
          if (isNewUnlock) 'unlockedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    return newlyUnlocked;
  }

  String _todayKey([DateTime? now]) {
    final date = now ?? DateTime.now();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
          return UserProfile.fromFirestore(doc.id, data);
        });
  }

  Stream<List<Subject>> streamSubjectProgress(String parentId, String childId) {
    debugPrint(
      'DEBUG: streamSubjectProgress called - parentId: $parentId, childId: $childId',
    );
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'DEBUG: subjectProgress snapshot - docs count: ${snapshot.docs.length}',
          );
          for (var doc in snapshot.docs) {
            debugPrint(
              'DEBUG: subjectProgress doc id: ${doc.id}, data: ${doc.data()}',
            );
          }
          return snapshot.docs
              .map((doc) => Subject.fromFirestore(doc.id, doc.data()))
              .toList();
        });
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

  Future<void> updateDailyGoal(
    String parentId,
    String childId, {
    required String type,
    required int target,
  }) async {
    if (type != 'lessons' && type != 'minutes') {
      throw ArgumentError.value(type, 'type', 'Use lessons or minutes');
    }
    if (target <= 0) {
      throw ArgumentError.value(target, 'target', 'Target must be positive');
    }

    final today = _todayKey();
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childDocRef);
      final childData = childSnapshot.data() ?? {};
      final currentGoal = childData['dailyGoal'] is Map
          ? Map<String, dynamic>.from(childData['dailyGoal'] as Map)
          : <String, dynamic>{};

      final lastUpdatedDate = currentGoal['lastUpdatedDate']?.toString();
      final existingProgress = lastUpdatedDate == today
          ? (currentGoal['todayProgress'] ?? 0).toInt()
          : 0;

      transaction.set(childDocRef, {
        'dailyGoal': {
          'type': type,
          'target': target,
          'todayProgress': existingProgress,
          'lastUpdatedDate': today,
          'lastNotifiedDate': currentGoal['lastNotifiedDate'],
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateDailyGoalProgress(
    String parentId,
    String childId, {
    required int timeInSeconds,
  }) async {
    final today = _todayKey();
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);
    final parentDocRef = _db.collection('parents').doc(parentId);
    final notificationColRef = parentDocRef.collection('notifications');

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childDocRef);
      final childData = childSnapshot.data() ?? {};
      final dailyGoalData = childData['dailyGoal'];

      if (dailyGoalData is! Map) return;

      final goal = Map<String, dynamic>.from(dailyGoalData);
      final type = goal['type']?.toString();
      final target = (goal['target'] ?? 0).toInt();
      if ((type != 'lessons' && type != 'minutes') || target <= 0) return;

      final lastUpdatedDate = goal['lastUpdatedDate']?.toString();
      final previousProgress = lastUpdatedDate == today
          ? (goal['todayProgress'] ?? 0).toInt()
          : 0;
      final increment = type == 'minutes'
          ? (timeInSeconds / 60).ceil().clamp(1, 1000000).toInt()
          : 1;
      final nextProgress = previousProgress + increment;
      final wasComplete = previousProgress >= target;
      final isComplete = nextProgress >= target;

      final parentSnapshot = await transaction.get(parentDocRef);
      final parentData = parentSnapshot.data() ?? {};
      final goalNotificationsEnabled = parentData['dailyGoals'] != false;
      final lastNotifiedDate = goal['lastNotifiedDate']?.toString();
      final shouldNotify =
          goalNotificationsEnabled &&
          !wasComplete &&
          isComplete &&
          lastNotifiedDate != today;

      final updatedGoal = {
        ...goal,
        'type': type,
        'target': target,
        'todayProgress': nextProgress,
        'lastUpdatedDate': today,
        if (shouldNotify) 'lastNotifiedDate': today,
      };

      transaction.set(childDocRef, {
        'dailyGoal': updatedGoal,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (shouldNotify) {
        final childName = childData['name']?.toString() ?? 'Your child';
        final notification = ParentNotification(
          id: '',
          title: '$childName completed today\'s learning goal',
          type: 'goal_complete',
          timestamp: DateTime.now(),
          childId: childId,
          childName: childName,
        );
        transaction.set(notificationColRef.doc(), {
          ...notification.toFirestore(),
          'payload': {'type': 'goal_complete', 'childName': childName},
        });
      }
    });
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

    final levelDocRef = subjectDocRef.collection('levels').doc(levelId);

    try {
      bool shouldForceSync = false;

      await _db.runTransaction((transaction) async {
        final levelSnapshot = await transaction.get(levelDocRef);
        final childSnapshot = await transaction.get(childDocRef);
        final subjectSnapshot = await transaction.get(subjectDocRef);

        final int previousBestStars = (levelSnapshot.data()?['stars'] ?? 0)
            .toInt();
        final childData = childSnapshot.data() ?? {};
        final int currentAvailableStars =
            (childData['availableStars'] ??
                    childData['starBalance'] ??
                    childData['stars'] ??
                    0)
                .toInt();
        final int currentLifetimeStars =
            (childData['lifetimeStarsEarned'] ?? currentAvailableStars).toInt();

        final subjectData = subjectSnapshot.data() ?? {};

        // If the subject document is missing aggregation fields,
        // we should force a full sync after this transaction.
        if (!subjectData.containsKey('totalStars') ||
            !subjectData.containsKey('completedLevels')) {
          shouldForceSync = true;
        }

        int currentTotalStars = (subjectData['totalStars'] ?? 0).toInt();
        int currentCompletedLevels = (subjectData['completedLevels'] ?? 0)
            .toInt();

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

          final int progressPercentage = ((currentCompletedLevels / 8) * 100)
              .toInt();

          transaction.set(subjectDocRef, {
            'progress': progressPercentage,
            'completedLevels': currentCompletedLevels,
            'totalStars': currentTotalStars,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          childUpdates['availableStars'] = currentAvailableStars + improvement;
          childUpdates['lifetimeStarsEarned'] =
              currentLifetimeStars + improvement;

          // Record earn transaction
          final transactionDocRef = childDocRef
              .collection('starTransactions')
              .doc();
          transaction.set(transactionDocRef, {
            'type': 'earn',
            'source': 'level_completion',
            'sourceID': '$subjectId:$levelId',
            'amount': improvement,
            'description':
                'Learned ${_getSubjectName(subjectId)} (${levelId.toUpperCase()})',
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
    final int totalLevels = levelsSnapshot.docs.length > 8
        ? levelsSnapshot.docs.length
        : 8;
    final int progressPercentage = ((completedLevels / totalLevels) * 100)
        .toInt()
        .clamp(0, 100);

    await subjectDocRef.set({
      'progress': progressPercentage,
      'completedLevels': completedLevels,
      'totalStars': totalStarsCount,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint(
      'DEBUG: Subject $subjectId repaired. Total Stars: $totalStarsCount, Completed: $completedLevels',
    );
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

    await updateDailyGoalProgress(
      parentId,
      childId,
      timeInSeconds: timeInSeconds,
    );
  }
}
