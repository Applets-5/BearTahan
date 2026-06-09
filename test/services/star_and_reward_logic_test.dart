import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/models/reward_claim.dart';

void main() {
  late FirestoreService firestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  const parentId = 'test_parent';
  const childId = 'test_child';
  const subjectId = 'bm';
  const levelId = 'c1_l1';

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
            .set({'name': 'Bear', 'availableStars': 0});

        // 2. Complete a level with 2 stars (8/10 = 80% = 2 stars)
        await firestoreService.updateLevelProgress(
          parentId,
          childId,
          subjectId,
          levelId,
          8,
          10,
        );

        // Verify Child Balance
        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        expect(childDoc.data()?['availableStars'], 2);
        expect(childDoc.data()?['lifetimeStarsEarned'], 2);

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
        // (1 completed level / 10 total) * 100 = 10%
        expect(subjectDoc.data()?['progress'], 10);

        // Verify Star History (Earn)
        final history = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('starTransactions')
            .get();

        expect(history.docs.length, 1);
        expect(history.docs.first.data()['type'], 'earn');
        expect(history.docs.first.data()['amount'], 2);
        expect(history.docs.first.data()['source'], 'level_completion');
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
          .set({
            'availableStars': 10,
            'lifetimeStarsEarned': 10,
            'name': 'Bear',
          });

      // Complete same level with 3 stars (+1 improvement) (10/10 = 100% = 3 stars)
      await firestoreService.updateLevelProgress(
        parentId,
        childId,
        subjectId,
        levelId,
        10,
        10,
      );

      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      // 10 + (3-2) = 11
      expect(childDoc.data()?['availableStars'], 11);
      expect(childDoc.data()?['lifetimeStarsEarned'], 11);

      final history = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('starTransactions')
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
      await subjectRef.collection('levels').doc('c1_l1').set({'stars': 3});
      await subjectRef.collection('levels').doc('c1_l2').set({'stars': 2});

      // Run Repair
      await firestoreService.syncSubjectAggregation(
        parentId,
        childId,
        subjectId,
      );

      final doc = await subjectRef.get();
      expect(doc.data()?['totalStars'], 5);
      expect(doc.data()?['completedLevels'], 2);
      expect(doc.data()?['progress'], 20); // (2/10)*100
    });
  });

  group('Reward Logic Tests', () {
    test('rejectRewardClaim should not change stars', () async {
      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .set({'availableStars': 60, 'lifetimeStarsEarned': 60});

      final claim = RewardClaim(
        id: 'r1',
        parentId: parentId,
        childId: childId,
        childName: 'Bear',
        rewardId: 'r1',
        rewardName: 'Ice Cream',
        rewardDescription: 'Yummy',
        starCost: 50,
        status: 'pending',
        claimedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('rewardClaims')
          .doc(claim.id)
          .set(claim.toFirestore());

      await firestoreService.rejectRewardClaim(parentId, claim);

      final childDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .get();
      expect(childDoc.data()?['availableStars'], 60);
      expect(childDoc.data()?['lifetimeStarsEarned'], 60);

      final claimDoc = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('rewardClaims')
          .doc(claim.id)
          .get();
      expect(claimDoc.data()?['status'], 'rejected');

      final history = await fakeFirestore
          .collection('parents')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .collection('starTransactions')
          .get();
      expect(history.docs, isEmpty);
    });

    test(
      'approveRewardClaim should deduct available stars and write spend',
      () async {
        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({'availableStars': 150, 'lifetimeStarsEarned': 200});

        final claim = RewardClaim(
          id: 'r1',
          parentId: parentId,
          childId: childId,
          childName: 'Bear',
          rewardId: 'r1',
          rewardName: 'Movie',
          rewardDescription: 'Fun',
          starCost: 100,
          status: 'pending',
          claimedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('rewardClaims')
            .doc(claim.id)
            .set(claim.toFirestore());

        await firestoreService.approveRewardClaim(parentId, claim);

        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();
        expect(childDoc.data()?['availableStars'], 50);
        expect(childDoc.data()?['lifetimeStarsEarned'], 200);

        final claimDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('rewardClaims')
            .doc(claim.id)
            .get();
        expect(claimDoc.data()?['status'], 'approved');

        final history = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('starTransactions')
            .get();
        expect(history.docs.length, 1);
        expect(history.docs.first.data()['type'], 'spend');
        expect(history.docs.first.data()['source'], 'reward_redemption');
        expect(history.docs.first.data()['amount'], 100);
      },
    );

    test(
      'approveRewardClaim should initialize lifetime stars for older child docs',
      () async {
        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .set({'availableStars': 3});

        final claim = RewardClaim(
          id: 'r1',
          parentId: parentId,
          childId: childId,
          childName: 'Bear',
          rewardId: 'r1',
          rewardName: 'Sticker',
          rewardDescription: 'Fun',
          starCost: 1,
          status: 'pending',
          claimedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .collection('rewardClaims')
            .doc(claim.id)
            .set(claim.toFirestore());

        await firestoreService.approveRewardClaim(parentId, claim);

        final childDoc = await fakeFirestore
            .collection('parents')
            .doc(parentId)
            .collection('children')
            .doc(childId)
            .get();

        expect(childDoc.data()?['availableStars'], 2);
        expect(childDoc.data()?['lifetimeStarsEarned'], 3);
      },
    );
  });
}
