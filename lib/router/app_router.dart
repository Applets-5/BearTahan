import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/parent_register_screen.dart';
import '../screens/child/chapter_screen.dart';
import '../screens/child/completion_screen.dart';
import '../screens/child/home_screen.dart';
import '../screens/child/level_session_screen.dart';
import '../screens/child/memory_challenge_screen.dart';
import '../screens/child/profile_screen.dart';
import '../screens/child/quests_screen.dart';
import '../screens/child/reward_list_screen.dart';
import '../screens/child/subject_screen.dart';
import '../screens/child/mascot_selection_screen.dart';
import '../screens/parent/dashboard_screen.dart';
import '../screens/parent/goal_setting_screen.dart';
import '../screens/parent/parent_notifications_screen.dart';
import '../screens/parent/parent_settings_screen.dart';
import '../screens/parent/reward_management_screen.dart';
import '../screens/shared/no_internet_screen.dart';
import '../screens/shared/tutorial_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/bottom_nav_bar.dart';
import '../screens/auth/profile_selection_screen.dart';
import '../screens/auth/create_profile_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  static const login = '/login';
  static const parentRegister = '/parent-register';
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

  static String subjectFor(String? childId) => withChildId(subject, childId);

  static String chapterFor(String? childId) => withChildId(chapter, childId);

  static String levelSessionFor(String? childId) =>
      withChildId(levelSession, childId);

  static String completionFor(String? childId) =>
      withChildId(completion, childId);
  static const selectProfile = '/select-profile';
  static const createProfile = '/create-profile';
  static const subject = '/subject';
  static const chapter = '/chapter';
  static const levelSession = '/level-session';
  static const completion = '/completion';
  static const quests = '/quests';
  static const rewards = '/rewards';
  static const profile = '/profile';
  static const memory = '/memory-challenge';
  static const parentDashboard = '/parent-dashboard';
  static const parentRewards = '/parent-rewards';
  static const parentGoals = '/parent-goals';
  static const parentNotifications = '/parent-notifications';
  static const parentSettings = '/parent-settings';
  static const noInternet = '/no-internet';
  static const tutorial = '/tutorial';
  static const comingSoon = '/coming-soon';

  static final router = GoRouter(
    initialLocation: login,
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    // THE AUTH GATE: This intercepts every navigation request
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;

      // Is the user trying to access the login or register page?
      final isAuthRoute =
          state.uri.path == login || state.uri.path == parentRegister;

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
        path: login,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: parentRegister,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ParentRegisterScreen()),
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
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const QuestsScreen()),
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
        ],
      ),
      GoRoute(
        path: mascotSelection,
        pageBuilder: (context, state) {
          final childId =
              state.uri.queryParameters['childId'] ?? 'demo_child_001';

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
          return _noTransitionPage(state, SubjectScreen(childId: childId));
        },
      ),
      GoRoute(
        path: chapter,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          return _noTransitionPage(state, ChapterScreen(childId: childId));
        },
      ),
      GoRoute(
        path: levelSession,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          return _noTransitionPage(state, LevelSessionScreen(childId: childId));
        },
      ),
      GoRoute(
        path: completion,
        pageBuilder: (context, state) {
          final childId = state.uri.queryParameters['childId'];
          return _noTransitionPage(state, CompletionScreen(childId: childId));
        },
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
