import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/models/reward.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late FirestoreService firestoreService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    firestoreService = FirestoreService(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('FirestoreService Tests', () {
    test(
      'claimReward should create pending claim without deducting stars',
      () async {
        const parentId = 'p1';
        const childId = 'c1';
        const childName = 'Aina';

        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({'availableStars': 150, 'lifetimeStarsEarned': 150});

        final reward = Reward(
          id: 'r1',
          title: 'Extra Screen Time',
          description: '30 mins extra',
          cost: 100,
          status: 'available',
        );

        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('rewards')
            .doc(reward.id)
            .set(reward.toFirestore());

        await firestoreService.claimReward(
          parentId,
          childId,
          reward,
          childName,
        );

        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        expect(childDoc.data()?['availableStars'], 150);
        expect(childDoc.data()?['lifetimeStarsEarned'], 150);

        final rewardDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('rewards')
            .doc(reward.id)
            .get();
        expect(rewardDoc.data()?['status'], 'available');

        final claimDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('rewardClaims')
            .get();
        expect(claimDoc.docs.length, 1);
        expect(claimDoc.docs.first.data()['status'], 'pending');
        expect(claimDoc.docs.first.data()['rewardId'], reward.id);
        expect(claimDoc.docs.first.data()['rewardName'], 'Extra Screen Time');
        expect(claimDoc.docs.first.data()['starCost'], 100);

        final notifications = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('notifications')
            .get();
        expect(notifications.docs.length, 1);
        expect(
          notifications.docs.first.data()['title'],
          contains('Aina wants to redeem Extra Screen Time'),
        );
        expect(
          notifications.docs.first.data()['payload']['type'],
          'reward_claimed',
        );
      },
    );

    test('claimReward should throw error if insufficient stars', () async {
      const parentId = 'p1';
      const childId = 'c1';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'availableStars': 50, 'lifetimeStarsEarned': 50});

      final reward = Reward(
        id: 'r1',
        title: 'Big Toy',
        description: 'Something expensive',
        cost: 100,
      );

      expect(
        () => firestoreService.claimReward(parentId, childId, reward, 'Aina'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insufficient stars'),
          ),
        ),
      );
    });

    test('claimReward should block duplicate pending claim', () async {
      const parentId = 'p1';
      const childId = 'c1';
      final reward = Reward(
        id: 'r1',
        title: 'Ice Cream',
        description: 'Treat',
        cost: 20,
      );

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'availableStars': 50});

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('rewardClaims')
          .doc('existing_pending_claim')
          .set({'status': 'pending', 'rewardId': reward.id});

      expect(
        () => firestoreService.claimReward(parentId, childId, reward, 'Aina'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('already pending'),
          ),
        ),
      );
    });

    for (final status in ['approved', 'rejected', 'expired']) {
      test('claimReward should allow claim after $status claim', () async {
        const parentId = 'p1';
        const childId = 'c1';
        final reward = Reward(
          id: 'r1',
          title: 'Ice Cream',
          description: 'Treat',
          cost: 20,
        );

        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({'availableStars': 50, 'lifetimeStarsEarned': 50});

        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('rewardClaims')
            .doc('resolved_claim')
            .set({
              'status': status,
              'rewardId': reward.id,
              'rewardName': reward.title,
              'starCost': reward.cost,
            });

        await firestoreService.claimReward(parentId, childId, reward, 'Aina');

        final claimDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('rewardClaims')
            .get();

        expect(claimDoc.docs.length, 2);
        expect(
          claimDoc.docs.where((doc) => doc.data()['status'] == status).length,
          1,
        );
        final pendingClaims = claimDoc.docs
            .where((doc) => doc.data()['status'] == 'pending')
            .toList();
        expect(pendingClaims.length, 1);
        expect(pendingClaims.first.data()['rewardId'], reward.id);
        expect(pendingClaims.first.data()['rewardName'], reward.title);
      });
    }

    test('claimReward should preserve repeated claim history', () async {
      const parentId = 'p1';
      const childId = 'c1';
      final reward = Reward(
        id: 'r1',
        title: 'Game Time',
        description: '15 minutes',
        cost: 20,
      );

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'availableStars': 80, 'lifetimeStarsEarned': 80});

      final claimsRef = fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('rewardClaims');

      await claimsRef.doc('first_claim').set({
        'status': 'approved',
        'rewardId': reward.id,
        'rewardName': reward.title,
        'starCost': reward.cost,
      });
      await claimsRef.doc('second_claim').set({
        'status': 'rejected',
        'rewardId': reward.id,
        'rewardName': reward.title,
        'starCost': reward.cost,
      });

      await firestoreService.claimReward(parentId, childId, reward, 'Aina');

      final claims = await claimsRef.get();
      expect(claims.docs.length, 3);
      expect(
        claims.docs.where((doc) => doc.data()['status'] == 'approved').length,
        1,
      );
      expect(
        claims.docs.where((doc) => doc.data()['status'] == 'rejected').length,
        1,
      );
      expect(
        claims.docs.where((doc) => doc.data()['status'] == 'pending').length,
        1,
      );
    });

    test('markNotificationAsRead should update isRead field', () async {
      const parentId = 'p1';
      const notificationId = 'n1';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .doc(notificationId)
          .set({'title': 'Test', 'isRead': false});

      await firestoreService.markNotificationAsRead(parentId, notificationId);

      final doc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .doc(notificationId)
          .get();

      expect(doc.data()?['isRead'], true);
    });

    test(
      'flagWrongAnswer should create and increment wrong answer record',
      () async {
        const parentId = 'p1';
        const childId = 'c1';
        const questionId = 'bc_c1_l1_trace_ren';

        await firestoreService.flagWrongAnswer(
          parentId,
          childId,
          questionId: questionId,
          subjectId: 'bc',
          levelId: 'l1',
          questionText: 'Trace 人',
        );
        await firestoreService.flagWrongAnswer(
          parentId,
          childId,
          questionId: questionId,
          subjectId: 'bc',
          levelId: 'l1',
          questionText: 'Trace 人',
        );

        final doc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('wrongAnswerBank')
            .doc(questionId)
            .get();

        expect(doc.exists, true);
        expect(doc.data()?['questionId'], questionId);
        expect(doc.data()?['subjectId'], 'bc');
        expect(doc.data()?['levelId'], 'l1');
        expect(doc.data()?['questionText'], 'Trace 人');
        expect(doc.data()?['reviewCount'], 2);
        expect(doc.data()?['addedAt'], isNotNull);
        expect(doc.data()?['lastWrongAt'], isNotNull);
      },
    );

    test('updateDailyGoal should store goal on child document', () async {
      const parentId = 'p1';
      const childId = 'c1';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'name': 'Aina'});

      await firestoreService.updateDailyGoal(
        parentId,
        childId,
        type: 'lessons',
        target: 3,
      );

      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      final goal = childDoc.data()?['dailyGoal'] as Map<String, dynamic>;

      expect(goal['type'], 'lessons');
      expect(goal['target'], 3);
      expect(goal['todayProgress'], 0);
    });

    test('updateDailyGoal resets progress when goal type changes', () async {
      const parentId = 'p1';
      const childId = 'c1';
      final today = DateTime.now();
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({
            'dailyGoal': {
              'type': 'lessons',
              'target': 3,
              'todayProgress': 2,
              'todaySeconds': 0,
              'lastUpdatedDate': todayKey,
              'lastNotifiedDate': todayKey,
            },
          });

      await firestoreService.updateDailyGoal(
        parentId,
        childId,
        type: 'minutes',
        target: 10,
      );

      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      final goal = childDoc.data()?['dailyGoal'] as Map<String, dynamic>;

      expect(goal['type'], 'minutes');
      expect(goal['target'], 10);
      expect(goal['todayProgress'], 0);
      expect(goal['todaySeconds'], 0);
      expect(goal['lastNotifiedDate'], isNull);
    });

    test(
      'recordAttempt should increment lesson goal and notify once when completed',
      () async {
        const parentId = 'p1';
        const childId = 'c1';

        await fakeFirestore.collection('parents').doc(parentId).set({
          'dailyGoals': true,
        });
        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({
              'name': 'Aina',
              'dailyGoal': {'type': 'lessons', 'target': 2},
            });

        await firestoreService.recordAttempt(
          parentId,
          childId,
          subjectId: 'bm',
          levelId: 'l1',
          score: 1,
          total: 1,
          stars: 3,
          timeInSeconds: 30,
        );
        await firestoreService.recordAttempt(
          parentId,
          childId,
          subjectId: 'bm',
          levelId: 'l2',
          score: 1,
          total: 1,
          stars: 3,
          timeInSeconds: 30,
        );
        await firestoreService.recordAttempt(
          parentId,
          childId,
          subjectId: 'bm',
          levelId: 'l3',
          score: 1,
          total: 1,
          stars: 3,
          timeInSeconds: 30,
        );

        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        final goal = childDoc.data()?['dailyGoal'] as Map<String, dynamic>;
        expect(goal['todayProgress'], 3);

        final notifications = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('notifications')
            .get();

        expect(notifications.docs.length, 1);
        expect(notifications.docs.first.data()['type'], 'goal_complete');
      },
    );

    test(
      'recordAttempt should increment minute goal using elapsed time',
      () async {
        const parentId = 'p1';
        const childId = 'c1';

        await fakeFirestore.collection('parents').doc(parentId).set({
          'dailyGoals': true,
        });
        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({
              'name': 'Aina',
              'dailyGoal': {'type': 'minutes', 'target': 5},
            });

        await firestoreService.recordAttempt(
          parentId,
          childId,
          subjectId: 'bm',
          levelId: 'l1',
          score: 1,
          total: 1,
          stars: 3,
          timeInSeconds: 125,
        );

        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        final goal = childDoc.data()?['dailyGoal'] as Map<String, dynamic>;

        expect(goal['todayProgress'], 2);
        expect(goal['todaySeconds'], 125);
      },
    );

    test('minute goal accumulates seconds across attempts', () async {
      const parentId = 'p1';
      const childId = 'c1';
      await fakeFirestore.collection('parents').doc(parentId).set({});
      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({
            'dailyGoal': {'type': 'minutes', 'target': 2},
          });

      await firestoreService.updateDailyGoalProgress(
        parentId,
        childId,
        timeInSeconds: 59,
      );
      await firestoreService.updateDailyGoalProgress(
        parentId,
        childId,
        timeInSeconds: 1,
      );

      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      final goal = childDoc.data()?['dailyGoal'] as Map<String, dynamic>;
      expect(goal['todayProgress'], 1);
      expect(goal['todaySeconds'], 60);
    });

    test(
      'recordReviewQuestionAnswered awards milestone and removes bank entry atomically',
      () async {
        const parentId = 'p1';
        const childId = 'c1';
        const questionId = 'bc_c1_l2_q01';
        final childRef = fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId);

        await childRef.set({
          'reviewQuestionCounter': 19,
          'availableStars': 4,
          'lifetimeStarsEarned': 7,
        });
        await childRef.collection('wrongAnswerBank').doc(questionId).set({
          'questionId': questionId,
          'subjectId': 'bc',
          'reviewCount': 1,
        });

        await firestoreService.recordReviewQuestionAnswered(
          parentId,
          childId,
          questionId,
        );

        final child = await childRef.get();
        expect(child.data()?['reviewQuestionCounter'], 0);
        expect(child.data()?['availableStars'], 5);
        expect(child.data()?['lifetimeStarsEarned'], 8);

        final bankEntry = await childRef
            .collection('wrongAnswerBank')
            .doc(questionId)
            .get();
        expect(bankEntry.exists, false);

        final transactions = await childRef
            .collection('starTransactions')
            .get();
        expect(transactions.docs, hasLength(1));
        expect(transactions.docs.single.data()['type'], 'earn');
        expect(transactions.docs.single.data()['source'], 'review_milestone');
      },
    );

    test(
      'recordReviewQuestionAnswered ignores an already removed question',
      () async {
        const parentId = 'p1';
        const childId = 'c1';
        final childRef = fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId);
        await childRef.set({
          'reviewQuestionCounter': 5,
          'availableStars': 2,
          'lifetimeStarsEarned': 2,
        });

        await firestoreService.recordReviewQuestionAnswered(
          parentId,
          childId,
          'missing_question',
        );

        final child = await childRef.get();
        expect(child.data()?['reviewQuestionCounter'], 5);
        expect(child.data()?['availableStars'], 2);
      },
    );

    test(
      'evaluateAndUpdateQuestProgress preserves demo eligibility without unlocking',
      () async {
        const parentId = 'p1';
        const childId = 'c1';
        final childRef = fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId);

        await childRef.set({'lifetimeStarsEarned': 61});
        await fakeFirestore.collection('outfitQuests').doc('super_bear').set({
          'name': 'Super Bear',
          'description': 'Earn 500 total stars',
          'imagePath': 'assets/images/bear5.png',
          'conditionType': 'total_stars',
          'target': 500,
          'displayOrder': 4,
        });
        await childRef.collection('questProgress').doc('super_bear').set({
          'currentValue': 61,
          'targetValue': 500,
          'isUnlocked': false,
          'demoEligibilityOverride': true,
        });

        await firestoreService.evaluateAndUpdateQuestProgress(
          parentId,
          childId,
        );

        final progress = await childRef
            .collection('questProgress')
            .doc('super_bear')
            .get();
        expect(progress.data()?['currentValue'], 500);
        expect(progress.data()?['targetValue'], 500);
        expect(progress.data()?['isUnlocked'], false);
        expect(progress.data()?['demoEligibilityOverride'], true);
        expect(progress.data()?['unlockedAt'], isNull);
      },
    );

    test(
      'evaluateAndUpdateQuestProgress keeps real progress without demo override',
      () async {
        const parentId = 'p1';
        const childId = 'c1';
        final childRef = fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId);

        await childRef.set({'lifetimeStarsEarned': 61});
        await fakeFirestore.collection('outfitQuests').doc('super_bear').set({
          'name': 'Super Bear',
          'description': 'Earn 500 total stars',
          'imagePath': 'assets/images/bear5.png',
          'conditionType': 'total_stars',
          'target': 500,
          'displayOrder': 4,
        });

        await firestoreService.evaluateAndUpdateQuestProgress(
          parentId,
          childId,
        );

        final progress = await childRef
            .collection('questProgress')
            .doc('super_bear')
            .get();
        expect(progress.data()?['currentValue'], 61);
        expect(progress.data()?['isUnlocked'], false);
      },
    );

    test('unlockQuestOutfit removes a consumed demo override', () async {
      const parentId = 'p1';
      const childId = 'c1';
      final progressRef = fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('questProgress')
          .doc('chef_bear');

      await progressRef.set({
        'currentValue': 5,
        'targetValue': 5,
        'isUnlocked': false,
        'demoEligibilityOverride': true,
      });

      await firestoreService.unlockQuestOutfit(parentId, childId, 'chef_bear');

      final progress = await progressRef.get();
      expect(progress.data()?['isUnlocked'], true);
      expect(progress.data()?['unlockedAt'], isNotNull);
      expect(progress.data()?.containsKey('demoEligibilityOverride'), false);
    });

    test('addChild should create a new child document', () async {
      const parentId = 'p1';
      final childData = {'name': 'Ali', 'age': 7, 'grade': 'Standard 1'};

      await firestoreService.addChild(parentId, childData);

      final children = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .get();

      expect(children.docs.length, 1);
      final data = children.docs.first.data();
      expect(data['name'], 'Ali');
      expect(data['age'], 7);
      expect(data['grade'], 'Standard 1');
      expect(data['availableStars'], 0);
      expect(data['activeOutfitID'], 'scholar_bear');
    });

    test('updateChild should modify existing child document', () async {
      const parentId = 'p1';
      const childId = 'c1';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'name': 'Ali', 'age': 7, 'grade': 'Standard 1'});

      await firestoreService.updateChild(parentId, childId, {
        'name': 'Ali bin Abu',
        'age': 8,
      });

      final doc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      expect(doc.data()?['name'], 'Ali bin Abu');
      expect(doc.data()?['age'], 8);
      expect(doc.data()?['grade'], 'Standard 1');
    });

    test('deleteChild should reject unsafe client-side deletion', () async {
      const parentId = 'p1';
      const childId = 'c1';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'name': 'Ali'});

      expect(
        () => firestoreService.deleteChild(parentId, childId),
        throwsUnsupportedError,
      );

      final doc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();

      expect(doc.exists, true);
    });
  });
}
