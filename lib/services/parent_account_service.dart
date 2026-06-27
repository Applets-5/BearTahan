import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentAccountService {
  ParentAccountService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<void> createOrUpdateParentDocument(
    User user, {
    String? name,
    Map<String, dynamic>? extraData,
  }) async {
    await _db.collection('parents').doc(user.uid).set({
      'uid': user.uid,
      'name': name ?? user.displayName ?? 'Parent',
      'email': user.email,
      'role': 'parent',
      'createdAt': FieldValue.serverTimestamp(),
      ...?extraData,
    }, SetOptions(merge: true));
  }

  Future<void> createParentDocumentIfMissing(User user, {String? name}) async {
    final parentDoc = await _db.collection('parents').doc(user.uid).get();
    if (parentDoc.exists) return;

    await createOrUpdateParentDocument(user, name: name);
  }
}
