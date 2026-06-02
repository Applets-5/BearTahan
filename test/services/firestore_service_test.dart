import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/models/reward.dart';

void main() {
  late FirestoreService firestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('FirestoreService Tests', () {
    test('claimReward should deduct stars and create a notification', () async {
      const parentId = 'p1';
      const childId = 'c1';
      const childName = 'Aina';

      // Setup initial data in fake firestore
      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'starBalance': 150});

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

      // Execute claim
      await firestoreService.claimReward(parentId, childId, reward, childName);

      // Verify star deduction
      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      expect(childDoc.data()?['starBalance'], 50);

      // Verify reward status update
      final rewardDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('rewards')
          .doc(reward.id)
          .get();
      expect(rewardDoc.data()?['status'], 'pending');

      // Verify notification creation
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
    });

    test('claimReward should throw error if insufficient stars', () async {
      const parentId = 'p1';
      const childId = 'c1';

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'starBalance': 50});

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

        expect(goal['todayProgress'], 3);
      },
    );
  });
}
