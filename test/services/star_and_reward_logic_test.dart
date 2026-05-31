import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/models/reward.dart';
import 'package:bear_tahan/models/subject.dart';

void main() {
  late FirestoreService firestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  const parentId = 'test_parent';
  const childId = 'test_child';
  const subjectId = 'bm';
  const levelId = 'level1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('Star Logic Tests', () {
    test(
      'updateLevelProgress should award stars and update subject aggregation',
      () async {
        // 1. Initial State: 0 stars
        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({'name': 'Bear', 'starBalance': 0});

        // 2. Complete a level with 2 stars
        await firestoreService.updateLevelProgress(
          parentId,
          childId,
          subjectId,
          levelId,
          2,
        );

        // Verify Child Balance
        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        expect(childDoc.data()?['starBalance'], 2);

        // Verify Subject Aggregation
        final subjectDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('subjectProgress')
            .doc(subjectId)
            .get();

        expect(subjectDoc.data()?['totalStars'], 2);
        expect(subjectDoc.data()?['completedLevels'], 1);
        // (1 completed level / 8 total) * 100 = 12%
        expect(subjectDoc.data()?['progress'], 12);

        // Verify Star History (Earn)
        final history = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('starHistory')
            .get();

        expect(history.docs.length, 1);
        expect(history.docs.first.data()['type'], 'earn');
        expect(history.docs.first.data()['amount'], 2);
      },
    );

    test('updateLevelProgress should only award improvement stars', () async {
      // Initial: already has 2 stars on this level
      final levelRef = fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('subjectProgress')
          .doc(subjectId)
          .collection('levels')
          .doc(levelId);

      await levelRef.set({'stars': 2});

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'starBalance': 10, 'name': 'Bear'});

      // Complete same level with 3 stars (+1 improvement)
      await firestoreService.updateLevelProgress(
        parentId,
        childId,
        subjectId,
        levelId,
        3,
      );

      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      // 10 + (3-2) = 11
      expect(childDoc.data()?['starBalance'], 11);

      final history = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('starHistory')
          .get();

      expect(
        history.docs.first.data()['amount'],
        1,
      ); // Only the improvement recorded
    });

    test('syncSubjectAggregation should correct inaccurate totals', () async {
      // Setup legacy/broken data (Progress is 25% but totalStars is missing)
      final subjectRef = fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('subjectProgress')
          .doc(subjectId);

      await subjectRef.set({'progress': 25});

      // Add two levels with actual data
      await subjectRef.collection('levels').doc('L1').set({'stars': 3});
      await subjectRef.collection('levels').doc('L2').set({'stars': 2});

      // Run Repair
      await firestoreService.syncSubjectAggregation(
        parentId,
        childId,
        subjectId,
      );

      final doc = await subjectRef.get();
      expect(doc.data()?['totalStars'], 5);
      expect(doc.data()?['completedLevels'], 2);
      expect(doc.data()?['progress'], 25); // (2/8)*100
    });
  });

  group('Reward Logic Tests', () {
    test('declineReward should refund stars and reset status', () async {
      final reward = Reward(
        id: 'r1',
        title: 'Ice Cream',
        description: 'Yummy',
        cost: 50,
        status: 'pending',
        claimedByChildId: childId,
      );

      final rewardRef = fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('rewards')
          .doc(reward.id);

      await rewardRef.set(reward.toFirestore());

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'starBalance': 10}); // Balance after deduction

      // Execute Decline
      await firestoreService.declineReward(parentId, reward);

      // Verify Refund
      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      expect(childDoc.data()?['starBalance'], 60); // 10 + 50 refund

      // Verify Status
      final rewardDoc = await rewardRef.get();
      expect(rewardDoc.data()?['status'], 'available');
      expect(rewardDoc.data()?['claimedByChildId'], isNull);

      // Verify Refund History
      final history = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('starHistory')
          .where('type', isEqualTo: 'earn')
          .get();

      expect(history.docs.last.data()['description'], contains('Refund'));
      expect(history.docs.last.data()['amount'], 50);
    });

    test('approveReward should mark as redeemed', () async {
      final reward = Reward(
        id: 'r1',
        title: 'Movie',
        description: 'Fun',
        cost: 100,
        status: 'pending',
        claimedByChildId: childId,
      );

      final rewardRef = fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('rewards')
          .doc(reward.id);

      await rewardRef.set(reward.toFirestore());

      // Execute Approve
      await firestoreService.approveReward(parentId, reward);

      // Verify Status
      final rewardDoc = await rewardRef.get();
      expect(rewardDoc.data()?['status'], 'redeemed');
    });
  });
}
