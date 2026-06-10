import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  ConsumerState<ParentSettingsScreen> createState() =>
      _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends ConsumerState<ParentSettingsScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSavingPin = false;

  Future<void> _updatePin() async {
    final parentId = ref.read(parentIdProvider);
    if (parentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before updating PIN')),
      );
      return;
    }

    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => _isSavingPin = true);
    try {
      await ref.read(firestoreServiceProvider).updateParentSettings(parentId, {
        'parentPin': _pinController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN updated successfully')),
        );
        _pinController.clear();
        _confirmPinController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating PIN: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingPin = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final parentId = ref.read(parentIdProvider);
    if (parentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before updating settings'),
        ),
      );
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).updateParentSettings(parentId, {
        key: value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating $key: $e')));
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear local state
      ref.read(childIdProvider.notifier).update(null);

      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        // Sign out of Google to clear the chosen account where the plugin exists.
        await GoogleSignIn().signOut();
      }
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
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(parentSettingsProvider);

    return SafeArea(
      child: settingsAsync.when(
        data: (settings) {
          final sound = settings['soundEffects'] ?? true;
          final claims = settings['rewardClaims'] ?? true;
          final goals = settings['dailyGoals'] ?? true;
          final biometrics = settings['biometricsEnabled'] ?? false;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text('Settings', style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: () => context.push(AppRouter.parentProfileDetail),
                borderRadius: AppRadius.r(AppRadius.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.r(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings['name'] ?? 'Parent',
                              style: AppTextStyles.bodyBold,
                            ),
                            const Text(
                              'Profile & Child Management',
                              style: AppTextStyles.tiny,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SettingsCard(
                title: 'Notifications',
                icon: Icons.notifications,
                children: [
                  _NotificationSwitch(
                    title: 'Sound Effects',
                    subtitle: 'Play feedback sounds in quizzes',
                    value: sound,
                    onChanged: (v) => _updateSetting('soundEffects', v),
                  ),
                  const Divider(),
                  _NotificationSwitch(
                    title: 'Reward Claims',
                    subtitle: 'Notify when a child claims rewards',
                    value: claims,
                    onChanged: (v) => _updateSetting('rewardClaims', v),
                  ),
                  const Divider(),
                  _NotificationSwitch(
                    title: 'Daily Goals',
                    subtitle: 'Notify when daily goal is met',
                    value: goals,
                    onChanged: (v) => _updateSetting('dailyGoals', v),
                  ),
                ],
              ),
              _SwitchCard(
                title: 'Biometric Login',
                subtitle: 'Use FaceID/Fingerprint for Parent Mode',
                value: biometrics,
                onChanged: (v) => _updateSetting('biometricsEnabled', v),
              ),
              _SettingsCard(
                title: 'Change Parent PIN',
                icon: Icons.key,
                children: [
                  TextField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      hintText: 'New 4-digit PIN',
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(hintText: 'Confirm PIN'),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _isSavingPin
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _updatePin,
                          child: const Text('Update PIN'),
                        ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  final childId = ref.read(childIdProvider);
                  if (childId == null || childId.isEmpty) {
                    context.go(AppRouter.selectProfile);
                    return;
                  }
                  context.go(AppRouter.childHomeFor(childId));
                },
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
              const SizedBox(height: AppSpacing.md),
              const _SettingsCard(
                title: 'Credits',
                icon: Icons.info_outline,
                children: [
                  Text(
                    'Chinese character data: Make Me A Hanzi (ARPHIC Public License).',
                    style: AppTextStyles.small,
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
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

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({
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
    return Row(
      children: [
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
