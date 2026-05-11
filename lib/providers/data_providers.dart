import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

// Mock UID for now
final userIdProvider = Provider((ref) => 'mock_student_123');

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final uid = ref.watch(userIdProvider);
  return ref.watch(firestoreServiceProvider).streamUserProfile(uid);
});

final subjectProgressProvider = StreamProvider<List<Subject>>((ref) {
  final uid = ref.watch(userIdProvider);
  return ref.watch(firestoreServiceProvider).streamSubjectProgress(uid);
});
