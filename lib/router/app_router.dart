import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/login_screen.dart';
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
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: tutorial,
        builder: (context, state) => const TutorialScreen(),
      ),
      GoRoute(
        path: noInternet,
        builder: (context, state) => const NoInternetScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final isParent = state.uri.path.startsWith('/parent');
          return BottomNavScaffold(isParent: isParent, child: child);
        },
        routes: [
          GoRoute(
            path: childHome,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: quests,
            builder: (context, state) => const QuestsScreen(),
          ),
          GoRoute(
            path: rewards,
            builder: (context, state) => const RewardListScreen(),
          ),
          GoRoute(
            path: profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: parentDashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: parentRewards,
            builder: (context, state) => const RewardManagementScreen(),
          ),
          GoRoute(
            path: parentGoals,
            builder: (context, state) => const GoalSettingScreen(),
          ),
          GoRoute(
            path: parentNotifications,
            builder: (context, state) => const ParentNotificationsScreen(),
          ),
          GoRoute(
            path: parentSettings,
            builder: (context, state) => const ParentSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: subject,
        builder: (context, state) => const SubjectScreen(),
      ),
      GoRoute(
        path: chapter,
        builder: (context, state) => const ChapterScreen(),
      ),
      GoRoute(
        path: levelSession,
        builder: (context, state) => const LevelSessionScreen(),
      ),
      GoRoute(
        path: completion,
        builder: (context, state) => const CompletionScreen(),
      ),
      GoRoute(
        path: memory,
        builder: (context, state) => const MemoryChallengeScreen(),
      ),
      GoRoute(
        path: comingSoon,
        builder: (context, state) => const ComingSoonScreen(),
      ),
    ],
  );
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
