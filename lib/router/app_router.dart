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
import '../screens/parent/dashboard_screen.dart';
import '../screens/parent/goal_setting_screen.dart';
import '../screens/parent/parent_notifications_screen.dart';
import '../screens/parent/parent_settings_screen.dart';
import '../screens/parent/reward_management_screen.dart';
import '../screens/shared/no_internet_screen.dart';
import '../screens/shared/tutorial_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common/bottom_nav_bar.dart';

class AppRouter {
  static const login = '/login';
  static const parentRegister = '/parent-register';
  static const childHome = '/child-home';
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
        return parentDashboard;
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
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const HomeScreen()),
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
        path: subject,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const SubjectScreen()),
      ),
      GoRoute(
        path: chapter,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ChapterScreen()),
      ),
      GoRoute(
        path: levelSession,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const LevelSessionScreen()),
      ),
      GoRoute(
        path: completion,
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const CompletionScreen()),
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
