import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../services/firestore_service.dart';
import '../router/app_router.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final parentIdProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

// This provider extracts the childId from the current route's query parameters
final childIdProvider = Provider<String?>((ref) {
  final router = AppRouter.router;
  final queryParams = router.routerDelegate.currentConfiguration.uri.queryParameters;
  return queryParams['childId'];
});

final userProfileProvider = StreamProvider<UserProfile>((ref) {
  final parentId = ref.watch(parentIdProvider);
  final childId = ref.watch(childIdProvider);
  
  if (childId == null || childId.isEmpty) {
    return const Stream.empty();
  }
  
  return ref.watch(firestoreServiceProvider).streamUserProfile(parentId, childId);
});

final subjectProgressProvider = StreamProvider<List<Subject>>((ref) {
  final parentId = ref.watch(parentIdProvider);
  final childId = ref.watch(childIdProvider);

  if (childId == null || childId.isEmpty) {
    return const Stream.empty();
  }

  return ref.watch(firestoreServiceProvider).streamSubjectProgress(parentId, childId);
});

final questionsProvider = FutureProvider.family<List<Question>, String>((ref, prefix) {
  return ref.watch(firestoreServiceProvider).getQuestions(prefix);
});

final levelStarsProvider = StreamProvider.family<Map<String, int>, String>((ref, subjectId) {
  final parentId = ref.watch(parentIdProvider);
  final childId = ref.watch(childIdProvider);

  if (childId == null || childId.isEmpty) {
    return const Stream.empty();
  }

  return ref.watch(firestoreServiceProvider).streamLevelStars(parentId, childId, subjectId);
});
