import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:go_router/go_router.dart';
import '../models/chapter_data.dart';
import '../models/subject.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/reward.dart';
import '../models/reward_claim.dart';
import '../models/notification.dart';
import '../models/outfit_quest.dart';
import '../models/star_transaction.dart';
import '../services/firestore_service.dart';
import '../services/security_service.dart';
import '../services/tts_service.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());
final securityServiceProvider = Provider((ref) => SecurityService());
final ttsServiceProvider = Provider((ref) => TtsService());
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final parentIdProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user?.uid ?? '';
});

final parentSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final parentId = ref.watch(parentIdProvider);
  if (parentId.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamParentSettings(parentId);
});

final rewardsProvider = StreamProvider<List<Reward>>((ref) {
  final parentId = ref.watch(parentIdProvider);
  if (parentId.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamRewards(parentId);
});

final childrenProvider = StreamProvider<List<UserProfile>>((ref) {
  final parentId = ref.watch(parentIdProvider);
  if (parentId.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamChildren(parentId);
});

final notificationsProvider = StreamProvider<List<ParentNotification>>((ref) {
  final parentId = ref.watch(parentIdProvider);
  if (parentId.isEmpty) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).streamNotifications(parentId);
});

final outfitQuestsProvider = StreamProvider<List<OutfitQuest>>((ref) {
  return ref.watch(firestoreServiceProvider).streamOutfitQuests();
});

final questProgressProvider =
    StreamProvider.family<
      Map<String, OutfitQuestProgress>,
      ({String parentId, String childId})
    >((ref, arg) {
      if (arg.parentId.isEmpty || arg.childId.isEmpty) {
        return const Stream.empty();
      }
      return ref
          .watch(firestoreServiceProvider)
          .streamQuestProgress(arg.parentId, arg.childId);
    });

// In Riverpod 3.0, StateProvider is removed. Use NotifierProvider instead.
class ChildIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void update(String? id) => state = id;
}

final childIdProvider = NotifierProvider<ChildIdNotifier, String?>(
  ChildIdNotifier.new,
);

final userProfileProvider = StreamProvider.family<UserProfile, String>((
  ref,
  childId,
) {
  final parentId = ref.watch(parentIdProvider);

  if (childId.isEmpty) {
    return const Stream.empty();
  }

  return ref
      .watch(firestoreServiceProvider)
      .streamUserProfile(parentId, childId);
});

final subjectProgressProvider = StreamProvider.family<List<Subject>, String>((
  ref,
  childId,
) {
  final parentId = ref.watch(parentIdProvider);

  if (childId.isEmpty || parentId.isEmpty) {
    return const Stream.empty();
  }

  return ref
      .watch(firestoreServiceProvider)
      .streamSubjectProgress(parentId, childId);
});

final questionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  prefix,
) {
  return ref.watch(firestoreServiceProvider).getQuestions(prefix);
});

final levelStarsProvider =
    StreamProvider.family<
      Map<String, int>,
      ({String childId, String subjectId})
    >((ref, arg) {
      final parentId = ref.watch(parentIdProvider);

      if (arg.childId.isEmpty) {
        return const Stream.empty();
      }

      return ref
          .watch(firestoreServiceProvider)
          .streamLevelStars(parentId, arg.childId, arg.subjectId);
    });

final starTransactionsProvider =
    StreamProvider.family<
      List<StarTransaction>,
      ({String parentId, String childId})
    >((ref, arg) {
      if (arg.parentId.isEmpty || arg.childId.isEmpty) {
        return const Stream.empty();
      }
      return ref
          .watch(firestoreServiceProvider)
          .streamStarTransactions(arg.parentId, arg.childId);
    });

final subjectChaptersProvider =
    FutureProvider.family<List<ChapterData>, String>((ref, subjectId) {
      return ref.watch(firestoreServiceProvider).getSubjectChapters(subjectId);
    });

final allSubjectsTotalLevelsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final service = ref.watch(firestoreServiceProvider);
  final subjects = ['bm', 'bi', 'bc', 'math', 'sci'];
  final Map<String, int> results = {};
  for (final id in subjects) {
    final chapters = await service.getSubjectChapters(id);
    results[id] = chapters.fold(0, (sum, c) => sum + c.levelIds.length);
  }
  return results;
});

final rewardClaimsProvider =
    StreamProvider.family<
      List<RewardClaim>,
      ({String parentId, String childId})
    >((ref, arg) {
      if (arg.parentId.isEmpty || arg.childId.isEmpty) {
        return const Stream.empty();
      }
      return ref
          .watch(firestoreServiceProvider)
          .streamRewardClaims(arg.parentId, arg.childId);
    });
