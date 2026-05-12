import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  ConsumerState<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends ConsumerState<ParentSettingsScreen> {
  bool sound = true;
  bool claims = true;
  bool goals = true;

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear local state
      ref.read(childIdProvider.notifier).update(null);
      
      // Sign out of Google to clear the chosen account
      await GoogleSignIn().signOut();
      // Sign out of Firebase to clear the session
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        // Route back to the login screen
        context.go(AppRouter.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('Settings', style: AppTextStyles.screenTitle),
          const SizedBox(height: AppSpacing.lg),
          const _SettingsCard(
            title: 'Editing profile',
            icon: Icons.person,
            children: [
              TextField(decoration: InputDecoration(hintText: 'Aina')),
              SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: InputDecoration(hintText: 'Age 7'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          _SwitchCard(
            title: 'Sound Effects',
            subtitle: 'Play feedback sounds in quizzes',
            value: sound,
            onChanged: (v) => setState(() => sound = v),
          ),
          _SwitchCard(
            title: 'Reward Claims',
            subtitle: 'Notify when a child claims rewards',
            value: claims,
            onChanged: (v) => setState(() => claims = v),
          ),
          _SwitchCard(
            title: 'Daily Goals',
            subtitle: 'Notify when daily goal is met',
            value: goals,
            onChanged: (v) => setState(() => goals = v),
          ),
          const _SettingsCard(
            title: 'Change Parent PIN',
            icon: Icons.key,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'New 4-digit PIN'),
                obscureText: true,
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: InputDecoration(hintText: 'Confirm PIN'),
                obscureText: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRouter.childHome),
            icon: const Icon(Icons.logout),
            label: const Text('Switch to Kid Mode'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Text(
              'Log Out Master Account',
              style: TextStyle(color: Colors.redAccent),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.delete),
            label: const Text('Delete All Data'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles.bodyBold),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyBold),
                Text(subtitle, style: AppTextStyles.tiny),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
