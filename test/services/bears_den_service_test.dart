import 'package:bear_tahan/models/bears_den_result.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreService service;
  const parentId = 'parent';
  const childId = 'child';
  final now = DateTime(2026, 6, 13, 12);

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = FirestoreService(firestore: firestore, auth: MockFirebaseAuth());
    await firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .set({'availableStars': 5, 'lifetimeStarsEarned': 8});
  });

  test('awards two stars for a perfect session', () async {
    final result = await service.completeBearsDenSession(
      parentId,
      childId,
      score: 5,
      total: 5,
      now: now,
    );

    expect(result.performanceStars, 2);
    expect(result.awardedStars, 2);
    expect(result.status, BearsDenAwardStatus.awarded);

    final child = await firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .get();
    expect(child.data()?['availableStars'], 7);
    expect(child.data()?['lifetimeStarsEarned'], 10);
    expect(child.data()?['bearsDenStarDate'], '2026-06-13');

    final level = await child.reference
        .collection('subjectProgress')
        .doc('bi')
        .collection('levels')
        .doc('bears_den')
        .get();
    expect(level.data()?['stars'], 2);

    final transactions = await child.reference
        .collection('starTransactions')
        .get();
    expect(transactions.docs.single.data()['source'], 'bears_den');
  });

  test('awards one star at the 70 percent threshold', () async {
    final result = await service.completeBearsDenSession(
      parentId,
      childId,
      score: 4,
      total: 5,
      now: now,
    );
    expect(result.performanceStars, 1);
    expect(result.awardedStars, 1);
  });

  test('does not award below the threshold', () async {
    final result = await service.completeBearsDenSession(
      parentId,
      childId,
      score: 3,
      total: 5,
      now: now,
    );
    expect(result.status, BearsDenAwardStatus.notEarned);
    expect(result.awardedStars, 0);
  });

  test('enforces the calendar-day cap', () async {
    await service.completeBearsDenSession(
      parentId,
      childId,
      score: 5,
      total: 5,
      now: now,
    );
    final second = await service.completeBearsDenSession(
      parentId,
      childId,
      score: 5,
      total: 5,
      now: now,
    );

    expect(second.status, BearsDenAwardStatus.dailyCap);
    expect(second.awardedStars, 0);
  });

  test('same-day replay improves mastery without paying twice', () async {
    await service.completeBearsDenSession(
      parentId,
      childId,
      score: 4,
      total: 5,
      now: now,
    );
    final second = await service.completeBearsDenSession(
      parentId,
      childId,
      score: 5,
      total: 5,
      now: now,
    );

    final level = await firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .doc('bi')
        .collection('levels')
        .doc('bears_den')
        .get();

    expect(second.status, BearsDenAwardStatus.dailyCap);
    expect(second.awardedStars, 0);
    expect(level.data()?['stars'], 2);
  });

  test('lower replay does not reduce mastery', () async {
    await service.completeBearsDenSession(
      parentId,
      childId,
      score: 5,
      total: 5,
      now: now,
    );
    await service.completeBearsDenSession(
      parentId,
      childId,
      score: 4,
      total: 5,
      now: now.add(const Duration(days: 1)),
    );

    final level = await firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('subjectProgress')
        .doc('bi')
        .collection('levels')
        .doc('bears_den')
        .get();
    expect(level.data()?['stars'], 2);
  });

  test('loads exact question IDs in requested order', () async {
    await firestore.collection('questions').doc('bi_c1_l1_q01').set({
      'text': 'First',
      'options': ['A', 'B'],
      'correctAnswerIndex': 0,
    });
    await firestore.collection('questions').doc('bi_c2_l1_q01').set({
      'text': 'Second',
      'options': ['A', 'B'],
      'correctAnswerIndex': 1,
    });

    final questions = await service.getQuestionsByIds([
      'bi_c2_l1_q01',
      'missing',
      'bi_c1_l1_q01',
    ]);

    expect(questions.map((question) => question.id), [
      'bi_c2_l1_q01',
      'bi_c1_l1_q01',
    ]);
  });
}
