import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user_profile.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  ConsumerState<ParentSettingsScreen> createState() =>
      _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends ConsumerState<ParentSettingsScreen> {
  void _showPinDialog(Map<String, dynamic> settings) {
    final oldPinController = TextEditingController();
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    final String? currentPin = settings['parentPin'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (sbContext, setDialogState) => AlertDialog(
          title: const Text('Change Parent PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (currentPin != null) ...[
                TextField(
                  controller: oldPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Old 4-digit PIN',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'New 4-digit PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Confirm New PIN',
                  counterText: '',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (currentPin != null && oldPinController.text != currentPin) {
                  setDialogState(() => error = 'Incorrect old PIN');
                  return;
                }
                if (pinController.text.length != 4) {
                  setDialogState(() => error = 'PIN must be 4 digits');
                  return;
                }
                if (pinController.text != confirmController.text) {
                  setDialogState(() => error = 'PINs do not match');
                  return;
                }

                final parentId = ref.read(parentIdProvider);
                try {
                  await ref.read(firestoreServiceProvider).updateParentSettings(
                    parentId,
                    {'parentPin': pinController.text},
                  );
                  if (!sbContext.mounted) return;
                  Navigator.pop(sbContext);
                  ScaffoldMessenger.of(sbContext).showSnackBar(
                    const SnackBar(content: Text('PIN updated successfully')),
                  );
                } catch (e) {
                  setDialogState(() => error = 'Error: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    final parentId = ref.read(parentIdProvider);
    if (parentId.isEmpty) return;
    try {
      await ref.read(firestoreServiceProvider).updateParentSettings(parentId, {
        key: value,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating $key: $e')));
    }
  }

  Future<void> _logout(BuildContext logoutContext) async {
    try {
      ref.read(childIdProvider.notifier).update(null);
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
      if (!logoutContext.mounted) return;
      logoutContext.go(AppRouter.login);
    } catch (e) {
      if (!logoutContext.mounted) return;
      ScaffoldMessenger.of(
        logoutContext,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(parentSettingsProvider);
    final childrenAsync = ref.watch(childrenProvider);

    return SafeArea(
      child: settingsAsync.when(
        data: (settings) {
          final sound = settings['soundEffects'] ?? true;
          final claims = settings['rewardClaims'] ?? true;
          final dailyGoals = settings['dailyGoals'] ?? true;
          final streakAtRisk = settings['streakAtRisk'] ?? true;
          final biometrics = settings['biometricsEnabled'] ?? false;
          final avatar = settings['avatarPath'] ?? '🐻';
          final name = settings['name'] ?? 'Parent';
          final username = settings['username'] ?? '';

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: [
              const Text('Settings', style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.lg),

              // Account Section
              _SectionLabel('Account'),
              _CardContainer(
                child: _SettingsRow(
                  iconText: avatar,
                  iconBgColor: const Color(0xFFEEEDFE),
                  iconColor: const Color(0xFF534AB7),
                  title: name,
                  subtitle: username.isNotEmpty
                      ? '@$username · Profile & children'
                      : 'Profile & children',
                  isAvatar: true,
                  onTap: () => context.push(AppRouter.parentProfileDetail),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.mutedText,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Children & Goals Section
              _SectionLabel('Children & Goals'),
              childrenAsync.when(
                data: (children) {
                  if (children.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No children added yet.',
                        style: AppTextStyles.small,
                      ),
                    );
                  }
                  return Column(
                    children: children.map((child) {
                      return _ChildGoalCard(childProfile: child);
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Notifications Section
              _SectionLabel('Notifications'),
              _CardContainer(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.emoji_events_rounded,
                      iconBgColor: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      title: 'Daily quests',
                      subtitle: 'Alert when quest is completed',
                      trailing: Switch.adaptive(
                        value: dailyGoals,
                        onChanged: (v) => _updateSetting('dailyGoals', v),
                        activeTrackColor: const Color(0xFF534AB7),
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.card_giftcard_rounded,
                      iconBgColor: const Color(0xFFFAEEDA),
                      iconColor: const Color(0xFF854F0B),
                      title: 'Reward claims',
                      subtitle: 'Alert when child claims a reward',
                      showTopBorder: true,
                      trailing: Switch.adaptive(
                        value: claims,
                        onChanged: (v) => _updateSetting('rewardClaims', v),
                        activeTrackColor: const Color(0xFF534AB7),
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.local_fire_department_rounded,
                      iconBgColor: const Color(0xFFE6F1FB),
                      iconColor: const Color(0xFF185FA5),
                      title: 'Streak at risk',
                      subtitle: 'Evening reminder before midnight',
                      showTopBorder: true,
                      trailing: Switch.adaptive(
                        value: streakAtRisk,
                        onChanged: (v) => _updateSetting('streakAtRisk', v),
                        activeTrackColor: const Color(0xFF534AB7),
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.volume_up_rounded,
                      iconBgColor: const Color(0xFFEEEDFE),
                      iconColor: const Color(0xFF534AB7),
                      title: 'Sound effects',
                      subtitle: 'Quiz feedback sounds',
                      showTopBorder: true,
                      trailing: Switch.adaptive(
                        value: sound,
                        onChanged: (v) => _updateSetting('soundEffects', v),
                        activeTrackColor: const Color(0xFF534AB7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Security Section
              _SectionLabel('Security'),
              _CardContainer(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.key_rounded,
                      iconBgColor: const Color(0xFFEEEDFE),
                      iconColor: const Color(0xFF534AB7),
                      title: 'Change parent PIN',
                      subtitle: '4-digit access code',
                      onTap: () => _showPinDialog(settings),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.fingerprint_rounded,
                      iconBgColor: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      title: 'Biometric login',
                      subtitle: 'Face ID / Fingerprint',
                      showTopBorder: true,
                      trailing: Switch.adaptive(
                        value: biometrics,
                        onChanged: (v) =>
                            _updateSetting('biometricsEnabled', v),
                        activeTrackColor: const Color(0xFF534AB7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Session Section
              _SectionLabel('Session'),
              _CardContainer(
                child: Column(
                  children: [
                    _SettingsRow(
                      icon: Icons.swap_horiz_rounded,
                      iconBgColor: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      title: 'Switch to kid mode',
                      onTap: () {
                        final childId = ref.read(childIdProvider);
                        if (childId == null || childId.isEmpty) {
                          context.go(AppRouter.selectProfile);
                          return;
                        }
                        context.go(AppRouter.childHomeFor(childId));
                      },
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.logout_rounded,
                      iconBgColor: const Color(0xFFFCEBEB),
                      iconColor: const Color(0xFFA32D2D),
                      title: 'Log out',
                      titleColor: const Color(0xFFA32D2D),
                      showTopBorder: true,
                      onTap: () => _logout(context),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // About Section
              _SectionLabel('About'),
              _CardContainer(
                child: _SettingsRow(
                  icon: Icons.info_outline_rounded,
                  iconBgColor: const Color(0xFFE6F1FB),
                  iconColor: const Color(0xFF185FA5),
                  title: 'Credits & licences',
                  onTap: () {
                    showLicensePage(context: context);
                  },
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.mutedText,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: AppRadius.r(AppRadius.lg),
      ),
      child: ClipRRect(borderRadius: AppRadius.r(AppRadius.lg), child: child),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String? iconText;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool showTopBorder;
  final bool isAvatar;

  const _SettingsRow({
    this.icon,
    this.iconText,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.trailing,
    this.onTap,
    this.showTopBorder = false,
    this.isAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      decoration: BoxDecoration(
        border: showTopBorder
            ? const Border(top: BorderSide(color: AppColors.border, width: 0.5))
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: isAvatar ? 14 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: isAvatar ? 44 : 32,
            height: isAvatar ? 44 : 32,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(isAvatar ? 22 : 8),
            ),
            alignment: Alignment.center,
            child: iconText != null
                ? Text(
                    iconText!,
                    style: TextStyle(fontSize: isAvatar ? 22 : 16),
                  )
                : Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isAvatar ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? AppColors.foreground,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }
}

class _ChildGoalCard extends ConsumerStatefulWidget {
  final UserProfile childProfile;
  const _ChildGoalCard({required this.childProfile});

  @override
  ConsumerState<_ChildGoalCard> createState() => _ChildGoalCardState();
}

class _ChildGoalCardState extends ConsumerState<_ChildGoalCard> {
  bool _isExpanded = false;
  late String _type;
  late int _val;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.childProfile.dailyGoal;
    _type = goal?.type ?? 'lessons';
    _val = goal?.target ?? (_type == 'lessons' ? 3 : 20);
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      _val = type == 'lessons' ? 3 : 20;
    });
  }

  void _step(int dir) {
    setState(() {
      if (_type == 'lessons') {
        _val = (_val + dir).clamp(1, 10);
      } else {
        _val = (_val + (dir * 5)).clamp(5, 120);
      }
    });
  }

  Future<void> _saveGoal() async {
    final parentId = ref.read(parentIdProvider);
    if (parentId.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final now = DateTime.now().toIso8601String();
      await ref.read(firestoreServiceProvider).updateChild(
        parentId,
        widget.childProfile.uid,
        {
          'dailyGoal': {
            'type': _type,
            'target': _val,
            'todayProgress': 0, // Reset progress on goal change
            'lastUpdatedDate': now,
          },
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goal updated successfully')),
      );
      setState(() => _isExpanded = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving goal: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.childProfile.dailyGoal;
    final currentTarget = goal?.target ?? 3;
    final currentType = goal?.type ?? 'lessons';
    final unitLabel = currentType == 'lessons' ? 'lessons' : 'min';
    final avatar = widget.childProfile.avatarPath ?? '🐻';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: AppRadius.r(AppRadius.lg),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: _isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(16))
                : BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE1F5EE),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(avatar, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.childProfile.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        Text(
                          '${widget.childProfile.grade ?? "Standard 1"} · Goal: $currentTarget $unitLabel/day',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  /* Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.mutedText,
                    size: 20,
                  ), */
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily quest type',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _GoalPill(
                          label: 'Lessons',
                          isActive: _type == 'lessons',
                          onTap: () => _setType('lessons'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _GoalPill(
                          label: 'Minutes',
                          isActive: _type == 'minutes',
                          onTap: () => _setType('minutes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _StepBtn(
                              icon: Icons.remove,
                              onTap: () => _step(-1),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              alignment: Alignment.center,
                              child: Text(
                                '$_val',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                              ),
                            ),
                            Text(
                              _type == 'lessons' ? 'lessons' : 'min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _StepBtn(icon: Icons.add, onTap: () => _step(1)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 32,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveGoal,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF534AB7),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _GoalPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF534AB7) : AppColors.card,
          border: Border.all(
            color: isActive ? const Color(0xFF534AB7) : AppColors.border,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFFEEEDFE) : AppColors.mutedText,
          ),
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border, width: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppColors.mutedText),
      ),
    );
  }
}
