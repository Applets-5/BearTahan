import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '../screens/child/chapter_screen.dart';
import '../screens/child/completion_screen.dart';
import '../screens/child/home_screen.dart';
import '../screens/child/level_session_screen.dart';
import '../screens/child/memory_challenge_screen.dart';
import '../screens/child/profile_screen.dart';
import '../screens/child/quests_screen.dart';
import '../screens/child/reward_list_screen.dart';
import '../screens/child/star_history_screen.dart';
import '../screens/child/subject_screen.dart';
import '../screens/child/mascot_selection_screen.dart';
import '../screens/parent/dashboard_screen.dart';
import '../screens/parent/goal_setting_screen.dart';
import '../screens/parent/parent_notifications_screen.dart';
import '../screens/parent/parent_settings_screen.dart';
import '../screens/parent/reward_management_screen.dart';
import '../screens/parent/parent_profile_detail_screen.dart';
import '../screens/parent/change_password_screen.dart';
import '../screens/shared/no_internet_screen.dart';
import '../screens/shared/tutorial_screen.dart';
import '../screens/shared/splash_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/bottom_nav_bar.dart';
import '../screens/auth/profile_selection_screen.dart';
import '../screens/auth/create_profile_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const parentRegister = '/parent-register';
  static const forgotPassword = '/forgot-password';
  static const mascotSelection = '/mascot-selection';
  static const childHome = '/child-home';

  static String withChildId(String path, String? childId) {
    if (childId == null || childId.isEmpty) return path;
    return Uri(path: path, queryParameters: {'childId': childId}).toString();
  }

  static String mascotSelectionFor(String childId) =>
      withChildId(mascotSelection, childId);

  static String childHomeFor(String? childId) =>
      withChildId(childHome, childId);

  static String subjectFor(String? childId, {String? subjectId}) {
    final params = <String, String>{};
    if (childId != null && childId.isNotEmpty) params['childId'] = childId;
    if (subjectId != null && subjectId.isNotEmpty) {
      params['subjectId'] = subjectId;
    }
    return Uri(path: subject, queryParameters: params).toString();
  }

  static String chapterFor(
    String? childId, {
    String? subjectId,
    String? chapterId,
  }) {
    final params = <String, String>{};
    if (childId != null && childId.isNotEmpty) params['childId'] = childId;
    if (subjectId != null && subjectId.isNotEmpty) {
      params['subjectId'] = subjectId;
    }
    if (chapterId != null && chapterId.isNotEmpty) {
      params['chapterId'] = chapterId;
    }
    return Uri(path: chapter, queryParameters: params).toString();
  }

  static String levelSessionFor(
    String? childId, {
    String? levelPrefix,
    String? subjectId,
    String? levelId,
  }) {
    final params = <String, String>{};
    if (childId != null && childId.isNotEmpty) params['childId'] = childId;
    if (levelPrefix != null && levelPrefix.isNotEmpty) {
      params['levelPrefix'] = levelPrefix;
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      params['subjectId'] = subjectId;
    }
    if (levelId != null && levelId.isNotEmpty) {
      params['levelId'] = levelId;
    }
    return Uri(path: levelSession, queryParameters: params).toString();
  }

  static String completionFor(
    String? childId, {
    int? score,
    int? total,
    int? stars,
    String? levelId,
    String? subjectId,
    bool? isEscalated,
    bool? isDailyBonus,
    List<String>? unlockedOutfits,
  }) {
    final params = <String, String>{};
    if (childId != null && childId.isNotEmpty) params['childId'] = childId;
    if (score != null) params['score'] = score.toString();
    if (total != null) params['total'] = total.toString();
    if (stars != null) params['stars'] = stars.toString();
    if (levelId != null) params['levelId'] = levelId;
    if (subjectId != null) params['subjectId'] = subjectId;
    if (isEscalated != null) params['isEscalated'] = isEscalated.toString();
    if (isDailyBonus != null) params['isDailyBonus'] = isDailyBonus.toString();
    if (unlockedOutfits != null && unlockedOutfits.isNotEmpty) {
      params['unlockedOutfits'] = unlockedOutfits.join(',');
    }
    return Uri(path: completion, queryParameters: params).toString();
  }

  static const selectProfile = '/select-profile';
  static const createProfile = '/create-profile';
  static const subject = '/subject';
  static const chapter = '/chapter';
  static const levelSession = '/level-session';
  static const completion = '/completion';
  static const quests = '/quests';
  static const rewards = '/rewards';
  static const profile = '/profile';
  static const starHistory = '/star-history';
  static const memory = '/memory-challenge';
  static const parentDashboard = '/parent-dashboard';
  static const parentRewards = '/parent-rewards';
  static const parentGoals = '/parent-goals';
  static const parentNotifications = '/parent-notifications';
  static const parentSettings = '/parent-settings';
  static const parentProfileDetail = '/parent-profile-detail';
  static const changePassword = '/change-password';
  static const noInternet = '/no-internet';
  static const tutorial = '/tutorial';
  static const comingSoon = '/coming-soon';

  static final router = GoRouter(
    initialLocation: splash,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    // THE AUTH GATE: This intercepts every navigation request
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      // Allow the splash screen to show without redirection
      if (state.uri.path == splash) {
        return null;
      }

      // Is the user trying to access the login or register page?
      final isAuthRoute =
          state.uri.path == login ||
          state.uri.path == parentRegister ||
          state.uri.path == forgotPassword;

      // If they are NOT logged in and trying to go anywhere else, force them to Login
      if (!isLoggedIn && !isAuthRoute) {
        return login;
      }

      // If they ARE logged in, but trying to view the Login/Register page, force them to the Dashboard
      if (isLoggedIn && isAuthRoute) {
        return selectProfile;
      }

      // Otherwise, let them go where they intended
      return null;
    },
    routes: [
      GoRoute(
        path: splash,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: login,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: forgotPassword,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: selectProfile,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ProfileSelectionScreen()),
      ),
      GoRoute(
        path: createProfile,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const CreateProfileScreen()),
      ),
      GoRoute(
        path: tutorial,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const TutorialScreen()),
      ),
      GoRoute(
        path: noInternet,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const NoInternetScreen()),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) {
          final isParent = state.uri.path.startsWith('/parent');
          return _noTransitionPage(
            state,
            BottomNavScaffold(isParent: isParent, child: child),
          );
        },

        routes: [
          GoRoute(
            path: childHome,
            pageBuilder: (context, state) {
              final childId = state.uri.queryParameters['childId'];
              return _noTransitionPage(state, HomeScreen(childId: childId));
            },
          ),
          GoRoute(
            path: quests,
            pageBuilder: (context, state) {
              final childId = state.uri.queryParameters['childId'];
              return _noTransitionPage(state, QuestsScreen(childId: childId));
            },
          ),
          GoRoute(
            path: rewards,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const RewardListScreen()),
          ),
          GoRoute(
            path: profile,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const ProfileScreen()),
          ),
          GoRoute(
            path: starHistory,
            pageBuilder: (context, state) {
              final childId = state.uri.queryParameters['childId'] ?? '';
              return _noTransitionPage(
                state,
                StarHistoryScreen(childId: childId),
              );
            },
          ),

          GoRoute(
            path: parentDashboard,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: parentRewards,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const RewardManagementScreen()),
          ),
          GoRoute(
            path: parentGoals,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const GoalSettingScreen()),
          ),
          GoRoute(
            path: parentNotifications,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const ParentNotificationsScreen()),
          ),
          GoRoute(
            path: parentSettings,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const ParentSettingsScreen()),
          ),
          GoRoute(
            path: parentProfileDetail,
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const ParentProfileDetailScreen()),
          ),
        ],
      ),
      GoRoute(
        path: mascotSelection,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'] ?? '';

          return _noTransitionPage(
            state,
            MascotSelectionScreen(childId: childId),
          );
        },
      ),
      GoRoute(
        path: subject,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          final subjectId = state.uri.queryParameters['subjectId'] ?? 'bm';
          return _noTransitionPage(
            state,
            SubjectScreen(childId: childId, subjectId: subjectId),
          );
        },
      ),
      GoRoute(
        path: chapter,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          final subjectId = state.uri.queryParameters['subjectId'];
          final chapterId = state.uri.queryParameters['chapterId'];
          return _noTransitionPage(
            state,
            ChapterScreen(
              childId: childId,
              subjectId: subjectId,
              chapterId: chapterId,
            ),
          );
        },
      ),
      GoRoute(
        path: levelSession,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          final levelPrefix =
              state.uri.queryParameters['levelPrefix'] ?? 'bm_c1_l1_';

          final explicitLevelId = state.uri.queryParameters['levelId'];

          // Extract subject and level from prefix (e.g., bm_c1_l1_ -> bm and l1)
          final parts = levelPrefix.split('_');
          final subjectId = parts.isNotEmpty ? parts[0] : 'bm';
          final levelId =
              explicitLevelId ??
              (parts.length >= 3 && parts[2].isNotEmpty ? parts[2] : 'l1');

          return _noTransitionPage(
            state,
            LevelSessionScreen(
              childId: childId,
              levelPrefix: levelPrefix,
              subjectId: subjectId,
              levelId: levelId,
            ),
          );
        },
      ),
      GoRoute(
        path: completion,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          final score =
              int.tryParse(state.uri.queryParameters['score'] ?? '0') ?? 0;
          final total =
              int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
          final stars = int.tryParse(state.uri.queryParameters['stars'] ?? '');
          final levelId = state.uri.queryParameters['levelId'] ?? 'l1';
          final subjectId = state.uri.queryParameters['subjectId'] ?? 'bm';
          final isEscalated =
              state.uri.queryParameters['isEscalated'] == 'true';
          final isDailyBonus =
              state.uri.queryParameters['isDailyBonus'] == 'true';
          final unlockedOutfits =
              state.uri.queryParameters['unlockedOutfits']
                  ?.split(',')
                  .where((id) => id.isNotEmpty)
                  .toList() ??
              const <String>[];

          return _noTransitionPage(
            state,
            CompletionScreen(
              childId: childId,
              score: score,
              total: total,
              stars: stars,
              levelId: levelId,
              subjectId: subjectId,
              isEscalated: isEscalated,
              isDailyBonus: isDailyBonus,
              unlockedOutfits: unlockedOutfits,
            ),
          );
        },
      ),
      GoRoute(
        path: changePassword,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ChangePasswordScreen()),
      ),
      GoRoute(
        path: memory,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const MemoryChallengeScreen()),
      ),
      GoRoute(
        path: comingSoon,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ComingSoonScreen()),
      ),
    ],
  );

  static Page<void> _noTransitionPage(GoRouterState state, Widget child) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text('Coming soon', style: AppTextStyles.cardTitle),
      ),
    );
  }
}
