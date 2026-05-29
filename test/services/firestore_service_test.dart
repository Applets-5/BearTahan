import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bear_tahan/services/firestore_service.dart';
import 'package:bear_tahan/models/reward.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockTransaction extends Mock implements Transaction {}

class FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late FirestoreService firestoreService;
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late MockTransaction mockTransaction;
  late MockDocumentSnapshot mockSnapshot;

  setUpAll(() {
    registerFallbackValue(FakeDocumentReference());
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    mockTransaction = MockTransaction();
    mockSnapshot = MockDocumentSnapshot();

    firestoreService = FirestoreService(firestore: mockFirestore);
  });

  group('FirestoreService Tests', () {
    test('markNotificationAsRead should update isRead field', () async {
      const parentId = 'p123';
      const notificationId = 'n456';

      when(
        () => mockFirestore.collection('parents'),
      ).thenReturn(mockCollection);
      when(() => mockCollection.doc(parentId)).thenReturn(mockDocument);
      when(
        () => mockDocument.collection('notifications'),
      ).thenReturn(mockCollection);
      when(() => mockCollection.doc(notificationId)).thenReturn(mockDocument);
      when(() => mockDocument.update(any())).thenAnswer((_) async => {});

      await firestoreService.markNotificationAsRead(parentId, notificationId);

      verify(() => mockDocument.update({'isRead': true})).called(1);
    });

    test('claimReward throws exception if stars are insufficient', () async {
      const parentId = 'p1';
      const childId = 'c1';
      final reward = Reward(
        id: 'r1',
        title: 'Treat',
        description: 'Yum',
        cost: 100,
      );

      // Using a more generic mock approach for runTransaction
      when(
        () => mockFirestore.runTransaction<void>(
          any(),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((invocation) async {
        final handler =
            invocation.positionalArguments[0] as TransactionHandler<void>;
        await handler(mockTransaction);
      });

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDocument);
      when(() => mockDocument.collection(any())).thenReturn(mockCollection);

      when(
        () => mockTransaction.get(any()),
      ).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.data()).thenReturn({'starBalance': 50});

      try {
        await firestoreService.claimReward(parentId, childId, reward, 'Aina');
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Insufficient stars'));
      }
    });
  });
}
