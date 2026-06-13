import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chapter_data.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../models/reward_claim.dart';
import '../models/notification.dart';
import '../models/outfit_quest.dart';
import '../models/star_transaction.dart';
import '../models/level_progress_result.dart';
import '../utils/data_contracts.dart';
import '../utils/streak_utils.dart';
import '../utils/star_utils.dart';
import '../utils/quest_utils.dart';

class FirestoreService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

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
    final claimLockRef = childDocRef
        .collection('rewardClaimLocks')
        .doc(reward.id);
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
      final claimLockSnapshot = await transaction.get(claimLockRef);
      final childData = childSnapshot.data() ?? {};

      if (claimLockSnapshot.exists) {
        throw Exception('Reward claim already pending');
      }

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
      transaction.set(claimLockRef, {
        'claimId': claimDocRef.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
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
    final claimLockRef = childDocRef
        .collection('rewardClaimLocks')
        .doc(claim.rewardId);

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
      transaction.delete(claimLockRef);
    });
  }

  Future<void> revertRewardClaim(String parentId, RewardClaim claim) async {
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(claim.childId);
    final claimDocRef = childDocRef.collection('rewardClaims').doc(claim.id);
    final claimLockRef = childDocRef
        .collection('rewardClaimLocks')
        .doc(claim.rewardId);

    await _db.runTransaction((transaction) async {
      final childSnapshot = await transaction.get(childDocRef);
      final claimSnapshot = await transaction.get(claimDocRef);
      final childData = childSnapshot.data() ?? {};
      final claimData = claimSnapshot.data() ?? {};

      if (claimData['status'] == 'pending') return;

      if (claimData['status'] == 'approved') {
        final availableStars = (childData['availableStars'] ?? 0).toInt();
        final starCost = (claimData['starCost'] ?? claim.starCost).toInt();

        transaction.update(childDocRef, {
          'availableStars': availableStars + starCost,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(claimDocRef, {
        'status': 'pending',
        'resolvedAt': null,
      });

      transaction.set(claimLockRef, {
        'claimId': claim.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteRewardClaim(String parentId, RewardClaim claim) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(claim.childId)
        .collection('rewardClaims')
        .doc(claim.id)
        .delete();
  }

  Future<void> rejectRewardClaim(String parentId, RewardClaim claim) async {
    final claimDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(claim.childId)
        .collection('rewardClaims')
        .doc(claim.id);
    final claimLockRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(claim.childId)
        .collection('rewardClaimLocks')
        .doc(claim.rewardId);

    await _db.runTransaction((transaction) async {
      final claimSnapshot = await transaction.get(claimDocRef);
      if (claimSnapshot.data()?['status'] != 'pending') {
        throw Exception('Reward claim is no longer pending');
      }
      transaction.update(claimDocRef, {
        'status': 'rejected',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(claimLockRef);
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
      case 'bi':
        return 'English';
      case 'bc':
        return 'Mandarin';
      case 'math':
        return 'Mathematics';
      case 'sci':
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
      throw Exception('Please unlock this outfit first.');
    }

    await _childDocRef(parentId, childId).set({
      'activeOutfitID': outfitId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unlockQuestOutfit(
    String parentId,
    String childId,
    String outfitId,
  ) async {
    final progressDocRef = _childDocRef(
      parentId,
      childId,
    ).collection('questProgress').doc(outfitId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressDocRef);
      final data = snapshot.data() ?? {};

      final currentValue = (data['currentValue'] ?? 0).toInt();
      final targetValue = (data['targetValue'] ?? 0).toInt();
      final alreadyUnlocked = data['isUnlocked'] == true;

      if (alreadyUnlocked) return;

      if (currentValue < targetValue) {
        throw Exception('Progress has not reached the target yet.');
      }

      transaction.set(progressDocRef, {
        'isUnlocked': true,
        'unlockedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
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

    final subjectProgress = <String, Map<String, dynamic>>{};

    for (final doc in subjectProgressSnapshot.docs) {
      final subjectId = DataContracts.normalizeSubjectId(doc.id);
      final existing = subjectProgress[subjectId];
      final data = doc.data();

      if (existing == null ||
          (data['completedLevels'] ?? 0) > (existing['completedLevels'] ?? 0)) {
        subjectProgress[subjectId] = data;
      }
    }

    final attemptsSnapshot = await childDocRef.collection('attempts').get();
    final attempts = attemptsSnapshot.docs.map((doc) => doc.data()).toList();

    final existingProgressSnapshot = await childDocRef
        .collection('questProgress')
        .get();

    final existingProgress = {
      for (final doc in existingProgressSnapshot.docs) doc.id: doc.data(),
    };

    final batch = _db.batch();

    for (final quest in quests) {
      final currentValue = QuestUtils.calculateQuestCurrentValue(
        quest: quest,
        lifetimeStarsEarned: lifetimeStarsEarned,
        subjectProgress: subjectProgress,
        attempts: attempts,
      );

      final existingData = existingProgress[quest.id] ?? {};
      final alreadyUnlocked = existingData['isUnlocked'] == true;

      batch.set(
        childDocRef.collection('questProgress').doc(quest.id),
        {
          'outfitID': quest.id,
          'outfitName': quest.name,
          'conditionType': quest.conditionType,
          if (quest.subjectId != null) 'subjectId': quest.subjectId,
          'currentValue': currentValue,
          'targetValue': quest.target,

          // Progress reached only shows the Unlock button.
          // It will NOT display the bear yet.
          // isUnlocked becomes true only after lucky draw finishes.
          'isUnlocked': quest.isStarter || alreadyUnlocked,

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    // Return empty because reaching progress is not same as unlocked yet.
    return [];
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

  Future<void> flagWrongAnswer(
    String parentId,
    String childId, {
    required String questionId,
    required String subjectId,
    required String levelId,
    String? questionText,
  }) async {
    final wrongAnswerRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('wrongAnswerBank')
        .doc(questionId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(wrongAnswerRef);
      final data = snapshot.data() ?? {};
      final reviewCount = (data['reviewCount'] ?? 0).toInt();
      final now = Timestamp.now();

      transaction.set(wrongAnswerRef, {
        'questionId': questionId,
        'subjectId': subjectId,
        'levelId': levelId,
        if (questionText != null && questionText.isNotEmpty)
          'questionText': questionText,
        'reviewCount': reviewCount + 1,
        'lastWrongAt': now,
        'addedAt': data['addedAt'] ?? now,
      }, SetOptions(merge: true));
    });
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

  Future<void> addChild(String parentId, Map<String, dynamic> data) async {
    await _db.collection('parents').doc(parentId).collection('children').add({
      ...data,
      'availableStars': 0,
      'lifetimeStarsEarned': 0,
      'activeOutfitID': 'scholar_bear',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChild(
    String parentId,
    String childId,
    Map<String, dynamic> data,
  ) async {
    await _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .update(data);
  }

  Future<void> deleteChild(String parentId, String childId) async {
    throw UnsupportedError(
      'Child deletion requires the planned server-side recursive deletion flow.',
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
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .snapshots()
        .map((snapshot) {
          final subjects = <String, Subject>{};
          for (final doc in snapshot.docs) {
            final subjectId = DataContracts.normalizeSubjectId(doc.id);
            final candidate = Subject.fromFirestore(subjectId, doc.data());
            final existing = subjects[subjectId];
            if (existing == null ||
                candidate.completedLevels > existing.completedLevels) {
              subjects[subjectId] = candidate;
            }
          }
          return subjects.values.toList();
        });
  }

  Future<List<ChapterData>> getSubjectChapters(String subjectId) async {
    final snapshot = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('chapters')
        .orderBy('index')
        .get();

    if (snapshot.docs.isEmpty) {
      // Fallback for English as per Samy's requirement if DB is empty
      if (subjectId == 'bi') {
        return [
          ChapterData(
            id: 'c0',
            name: 'Chapter 0',
            levelIds: ['c0_l1', 'c0_l2', 'c0_l3', 'c0_summary'],
          ),
          ChapterData(
            id: 'c1',
            name: 'Chapter 1',
            levelIds: [
              'c1_l1',
              'c1_l2',
              'c1_l3',
              'c1_l4',
              'c1_l5',
              'c1_l6',
              'c1_summary',
            ],
          ),
          ChapterData(
            id: 'c2',
            name: 'Chapter 2',
            levelIds: [
              'c2_l1',
              'c2_l2',
              'c2_l3',
              'c2_l4',
              'c2_l5',
              'c2_l6',
              'c2_summary',
            ],
          ),
        ];
      }
      // Default fallback for other subjects (Chapters 1 and 2, 4 levels each + summary)
      return [
        ChapterData(
          id: 'c1',
          name: 'Chapter 1',
          levelIds: ['c1_l1', 'c1_l2', 'c1_l3', 'c1_l4', 'c1_l5', 'c1_summary'],
        ),
        ChapterData(
          id: 'c2',
          name: 'Chapter 2',
          levelIds: ['c2_l6', 'c2_l7', 'c2_l8', 'c2_summary'],
        ),
      ];
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final levelIds = List<String>.from(data['levelIds'] ?? []);

      // Automatically inject the chapter summary as the final boss if not explicitly listed
      if (levelIds.isNotEmpty &&
          !levelIds.last.toLowerCase().contains('summary')) {
        levelIds.add('${doc.id}_summary');
      }

      return ChapterData(
        id: doc.id,
        name: data['name'] ?? '',
        levelIds: levelIds,
      );
    }).toList();
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

  Future<void> updatePassword(String parentId, String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
      // Also update password length in Firestore for UI display
      await _db.collection('parents').doc(parentId).update({
        'passwordLength': newPassword.length,
      });
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      throw Exception('No user logged in or email missing');
    }
  }

  Future<void> deleteParentAccount(String parentId) async {
    throw UnsupportedError(
      'Account deletion requires the planned server-side recursive deletion flow.',
    );
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
      final isSameGoalType = currentGoal['type']?.toString() == type;
      final canPreserveProgress = lastUpdatedDate == today && isSameGoalType;
      final existingProgress = canPreserveProgress
          ? (currentGoal['todayProgress'] ?? 0).toInt()
          : 0;
      final existingSeconds = canPreserveProgress
          ? (currentGoal['todaySeconds'] ??
                    (currentGoal['type'] == 'minutes'
                        ? existingProgress * 60
                        : 0))
                .toInt()
          : 0;

      transaction.set(childDocRef, {
        'dailyGoal': {
          'type': type,
          'target': target,
          'todayProgress': existingProgress,
          'todaySeconds': existingSeconds,
          'lastUpdatedDate': today,
          'lastNotifiedDate': isSameGoalType
              ? currentGoal['lastNotifiedDate']
              : null,
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
      final previousSeconds = lastUpdatedDate == today
          ? (goal['todaySeconds'] ??
                    (type == 'minutes' ? previousProgress * 60 : 0))
                .toInt()
          : 0;
      final nextSeconds = type == 'minutes'
          ? previousSeconds + timeInSeconds.clamp(0, 1000000)
          : previousSeconds;
      final nextProgress = type == 'minutes'
          ? nextSeconds ~/ 60
          : previousProgress + 1;
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
        'todaySeconds': nextSeconds,
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

  Future<Map<String, dynamic>> getLevelProgress(
    String parentId,
    String childId,
    String subjectId,
    String levelId,
  ) async {
    final doc = await _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .doc(subjectId)
        .collection('levels')
        .doc(levelId)
        .get();
    return doc.data() ?? {};
  }

  Future<LevelProgressResult> updateLevelProgress(
    String parentId,
    String childId,
    String subjectId,
    String levelId,
    int score,
    int total,
  ) async {
    final childDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId);

    final normalizedSubjectId = DataContracts.normalizeSubjectId(subjectId);
    final normalizedLevelId = DataContracts.normalizeLevelId(levelId);
    final normalizedSubjectDocRef = childDocRef
        .collection('subjectProgress')
        .doc(normalizedSubjectId);
    final normalizedLevelDocRef = normalizedSubjectDocRef
        .collection('levels')
        .doc(normalizedLevelId);
    final legacyLevelId = DataContracts.legacyLevelId(normalizedLevelId);
    final legacyLevelDocRef = legacyLevelId == null
        ? null
        : normalizedSubjectDocRef.collection('levels').doc(legacyLevelId);

    int performanceStars = 0;
    int newStarsAwarded = 0;
    int dailyBonusStars = 0;
    bool didImprove = false;
    bool didEscalate = false;

    final chapters = await getSubjectChapters(normalizedSubjectId);
    final Set<String> validLevelIds = chapters
        .expand((c) => c.levelIds)
        .toSet();
    final int totalLevels = validLevelIds.length;
    final bool isValidLevel = validLevelIds.contains(normalizedLevelId);
    final bool isSummaryOrRevision =
        normalizedLevelId.contains('summary') ||
        normalizedLevelId.contains('revision');
    bool shouldForceSync = false;

    await _db.runTransaction((transaction) async {
      final levelSnapshot = await transaction.get(normalizedLevelDocRef);
      final legacyLevelSnapshot = legacyLevelDocRef == null
          ? null
          : await transaction.get(legacyLevelDocRef);
      final childSnapshot = await transaction.get(childDocRef);
      final subjectSnapshot = await transaction.get(normalizedSubjectDocRef);

      final levelData = levelSnapshot.data() ?? {};
      final int previousBestStars = [
        (levelData['stars'] ?? 0).toInt(),
        (legacyLevelSnapshot?.data()?['stars'] ?? 0).toInt(),
      ].reduce((a, b) => a > b ? a : b);

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

      // Force a full sync if aggregation fields are missing OR look suspicious
      if (!subjectData.containsKey('totalStars') ||
          !subjectData.containsKey('completedLevels') ||
          (subjectData['completedLevels'] ?? 0) > totalLevels ||
          (subjectData['completedLevels'] ?? 0) < 0 ||
          (subjectData['totalStars'] ?? 0) > (totalLevels * 3) ||
          (subjectData['totalStars'] ?? 0) < 0) {
        shouldForceSync = true;
      }

      int currentTotalStars = (subjectData['totalStars'] ?? 0).toInt();
      int currentCompletedLevels = (subjectData['completedLevels'] ?? 0)
          .toInt();

      final childUpdates = <String, dynamic>{
        'availableStars': currentAvailableStars,
        'lifetimeStarsEarned': currentLifetimeStars,
      };

      // Handle streak logic
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

      int calculatedStars = 0;
      int totalStarsToAward = 0;
      final levelUpdates = <String, dynamic>{};

      if (isSummaryOrRevision) {
        final int currentThreshold = (levelData['summaryThreshold'] ?? 0)
            .toInt();
        final DateTime? lastSummaryStarDate =
            levelData['lastSummaryStarDate'] != null
            ? (levelData['lastSummaryStarDate'] as Timestamp).toDate()
            : null;

        final result = StarUtils.calculateSummaryResult(
          score: score,
          total: total,
          currentThreshold: currentThreshold,
          lastSummaryStarDate: lastSummaryStarDate,
        );

        calculatedStars = result['stars'];
        bool earnedDailyStar = result['earnedDailyStar'];
        int newThreshold = result['newThreshold'];
        didEscalate = newThreshold > currentThreshold;

        levelUpdates['summaryThreshold'] = newThreshold;
        if (earnedDailyStar) {
          totalStarsToAward += 1;
          dailyBonusStars = 1;
          levelUpdates['lastSummaryStarDate'] = FieldValue.serverTimestamp();
        }
      } else {
        calculatedStars = StarUtils.calculateStars(
          score: score,
          total: total,
          levelId: normalizedLevelId,
        );
      }

      performanceStars = calculatedStars;
      didImprove = calculatedStars > previousBestStars;
      if (didImprove) {
        levelUpdates['stars'] = calculatedStars;
        final int improvement = calculatedStars - previousBestStars;
        newStarsAwarded = improvement;
        totalStarsToAward += improvement;

        if (isValidLevel) {
          currentTotalStars += improvement;
          if (previousBestStars == 0) {
            currentCompletedLevels++;
          }

          final int progressPercentage = totalLevels > 0
              ? ((currentCompletedLevels / totalLevels) * 100).toInt().clamp(
                  0,
                  100,
                )
              : 0;

          transaction.set(normalizedSubjectDocRef, {
            'progress': progressPercentage,
            'completedLevels': currentCompletedLevels,
            'totalStars': currentTotalStars,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (levelUpdates.isNotEmpty) {
        transaction.set(
          normalizedLevelDocRef,
          levelUpdates,
          SetOptions(merge: true),
        );
      }

      if (totalStarsToAward > 0) {
        childUpdates['availableStars'] =
            currentAvailableStars + totalStarsToAward;
        childUpdates['lifetimeStarsEarned'] =
            currentLifetimeStars + totalStarsToAward;

        // Record earn transaction
        final transactionDocRef = childDocRef
            .collection('starTransactions')
            .doc();
        final String bonusText = dailyBonusStars > 0 ? ' (Daily Bonus!)' : '';
        transaction.set(transactionDocRef, {
          'type': 'earn',
          'source': 'level_completion',
          'sourceID': '$normalizedSubjectId:$normalizedLevelId',
          'amount': totalStarsToAward,
          'description':
              'Learned ${_getSubjectName(normalizedSubjectId)} (${normalizedLevelId.toUpperCase()})$bonusText',
          'timestamp': FieldValue.serverTimestamp(),
          'subjectId': normalizedSubjectId,
          'levelId': normalizedLevelId,
        });
      }

      if (childUpdates.isNotEmpty) {
        transaction.set(childDocRef, childUpdates, SetOptions(merge: true));
      }
    });

    if (shouldForceSync) {
      try {
        await syncSubjectAggregation(parentId, childId, normalizedSubjectId);
      } catch (error) {
        debugPrint('Progress saved but aggregate sync failed: $error');
      }
    }

    return LevelProgressResult(
      performanceStars: performanceStars,
      newStarsAwarded: newStarsAwarded,
      dailyBonusStars: dailyBonusStars,
      didImprove: didImprove,
      didEscalate: didEscalate,
    );
  }

  Future<void> updateQuestionStats(
    String parentId,
    String childId,
    String questionId,
    bool isCorrect,
  ) async {
    final docRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('questionStats')
        .doc(questionId);

    await docRef.set({
      'timesSeen': FieldValue.increment(1),
      'timesWrong': isCorrect
          ? FieldValue.increment(0)
          : FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, Map<String, int>>> getQuestionStatsForUser(
    String parentId,
    String childId,
    List<String> questionIds,
  ) async {
    if (questionIds.isEmpty) return {};

    // Firestore whereIn limit is 30, but we can just get the whole subcollection
    // for this subject if needed, or do multiple queries.
    // For now, let's get the whole subcollection since it's child-specific and
    // likely won't be massive for a single subject session.
    final snapshot = await _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('questionStats')
        .get();

    final Map<String, Map<String, int>> stats = {};
    for (var doc in snapshot.docs) {
      if (questionIds.contains(doc.id)) {
        final data = doc.data();
        stats[doc.id] = {
          'timesSeen': (data['timesSeen'] ?? 0).toInt(),
          'timesWrong': (data['timesWrong'] ?? 0).toInt(),
        };
      }
    }
    return stats;
  }

  /// Performs a full scan of the levels subcollection and updates the
  /// subject aggregation document. This is used to bootstrap legacy data.
  Future<void> syncSubjectAggregation(
    String parentId,
    String childId,
    String subjectId,
  ) async {
    final normalizedSubjectId = DataContracts.normalizeSubjectId(subjectId);
    final subjectDocRef = _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .doc(normalizedSubjectId);

    // Progress is based on total levels from chapters
    final chapters = await getSubjectChapters(normalizedSubjectId);
    final Set<String> validLevelIds = chapters
        .expand((c) => c.levelIds)
        .toSet();
    final int totalLevels = validLevelIds.length;

    // Get all levels for this subject to calculate true totals
    final levelsSnapshot = await subjectDocRef.collection('levels').get();

    int totalStarsCount = 0;
    int completedLevels = 0;
    final starsByLevel = <String, int>{};

    for (var doc in levelsSnapshot.docs) {
      final normalizedLevelId = DataContracts.normalizeLevelId(doc.id);
      if (!validLevelIds.contains(normalizedLevelId)) continue;

      // Get the actual stars (0-3) earned for this specific level
      final starsEarned = (doc.data()['stars'] ?? 0) as num;
      final existing = starsByLevel[normalizedLevelId] ?? 0;
      starsByLevel[normalizedLevelId] = starsEarned.toInt() > existing
          ? starsEarned.toInt()
          : existing;
    }

    for (final starsEarned in starsByLevel.values) {
      if (starsEarned <= 0) continue;
      completedLevels++;
      totalStarsCount += starsEarned;
    }

    final bool allChaptersComplete =
        totalLevels > 0 && completedLevels >= totalLevels;

    final int progressPercentage = totalLevels > 0
        ? ((completedLevels / totalLevels) * 100).toInt().clamp(0, 100)
        : 0;

    await subjectDocRef.set({
      'progress': progressPercentage,
      'completedLevels': completedLevels,
      'totalStars': totalStarsCount,
      'allChaptersComplete': allChaptersComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, int>> streamLevelStars(
    String parentId,
    String childId,
    String subjectId,
  ) {
    final normalizedSubjectId = DataContracts.normalizeSubjectId(subjectId);
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .doc(normalizedSubjectId)
        .collection('levels')
        .snapshots()
        .map((snapshot) {
          final Map<String, int> stars = {};
          for (var doc in snapshot.docs) {
            final levelId = DataContracts.normalizeLevelId(doc.id);
            final value = (doc.data()['stars'] ?? 0).toInt();
            if (value > (stars[levelId] ?? 0)) stars[levelId] = value;
          }
          return stars;
        });
  }

  Stream<List<Map<String, dynamic>>> streamAttempts(
    String parentId,
    String childId,
  ) {
    return _db
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('attempts')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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
    String sessionType =
        'regular', // 'regular' | 'bears_den' | 'memory_challenge' | 'chapter_summary' | 'revision'
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
          'sessionType': sessionType,
          'completedAt': FieldValue.serverTimestamp(),
        });

    await updateDailyGoalProgress(
      parentId,
      childId,
      timeInSeconds: timeInSeconds,
    );
  }
}
