import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/missing_child_profile.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/parent/stat_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool showPin = false;

  Future<void> _enterParentMode() async {
    final settingsAsync = ref.read(parentSettingsProvider);
    final settings = settingsAsync.value ?? {};
    final biometricsEnabled = settings['biometricsEnabled'] ?? false;

    if (biometricsEnabled) {
      final security = ref.read(securityServiceProvider);
      final success = await security.authenticateWithBiometrics();
      if (success && mounted) {
        context.go(AppRouter.parentDashboard);
        return;
      }
    }

    if (mounted) {
      setState(() => showPin = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeChildId = GoRouterState.of(
      context,
    ).uri.queryParameters['childId'];
    final providerChildId = ref.watch(childIdProvider);
    final childId = routeChildId?.isNotEmpty == true
        ? routeChildId!
        : providerChildId ?? '';

    if (childId.isEmpty) {
      return const MissingChildProfile(
        message: 'Select a child profile to view this page.',
      );
    }

    final userProfileAsync = ref.watch(userProfileProvider(childId));

    return SafeArea(
      child: Stack(
        children: [
          userProfileAsync.when(
            data: (profile) => ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const Text('Profile', style: AppTextStyles.screenTitle),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.r(AppRadius.xl),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      ActiveMascotWidget(childId: childId, size: 96),
                      const SizedBox(height: AppSpacing.md),
                      Text(profile.name, style: AppTextStyles.cardTitle),
                      const Text('Tap to edit name', style: AppTextStyles.tiny),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.star,
                        label: 'Available',
                        value: profile.starBalance.toString(),
                        color: AppColors.star,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final progressAsync = ref.watch(
                            subjectProgressProvider(childId),
                          );
                          return progressAsync.maybeWhen(
                            data: (list) {
                              final totalProgress = list.fold(
                                0,
                                (sum, s) => sum + s.progress,
                              );
                              return StatCard(
                                icon: Icons.menu_book,
                                label: 'Progress',
                                value:
                                    '${totalProgress ~/ (list.isEmpty ? 1 : list.length)}%',
                                color: AppColors.primary,
                              );
                            },
                            orElse: () => const StatCard(
                              icon: Icons.menu_book,
                              label: 'Progress',
                              value: '0%',
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatCard(
                        icon: Icons.local_fire_department,
                        label: 'Streak',
                        value: '${profile.streakCount}d',
                        color: AppColors.destructive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _enterParentMode,
                  icon: const Icon(Icons.login),
                  label: const Text('Parent Mode'),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('Error loading profile: $err')),
          ),
          if (showPin)
            _PinModal(
              onClose: () => setState(() => showPin = false),
              onEnter: () => context.go(AppRouter.parentDashboard),
            ),
        ],
      ),
    );
  }
}

class _PinModal extends ConsumerStatefulWidget {
  const _PinModal({required this.onClose, required this.onEnter});
  final VoidCallback onClose;
  final VoidCallback onEnter;

  @override
  ConsumerState<_PinModal> createState() => _PinModalState();
}

class _PinModalState extends ConsumerState<_PinModal> {
  final _controller = TextEditingController();
  String? _error;

  void _verify() {
    final settingsAsync = ref.read(parentSettingsProvider);
    final storedPin = settingsAsync.value?['parentPin'];
    final security = ref.read(securityServiceProvider);

    if (security.verifyPin(_controller.text, storedPin)) {
      widget.onEnter();
    } else {
      setState(() => _error = 'Invalid PIN. Try again.');
      _controller.clear();
    }
  }

  Future<void> _tryBiometrics() async {
    final security = ref.read(securityServiceProvider);

    // Check if biometrics are supported/enabled in browser first
    final available = await security.isBiometricAvailable();
    if (!available) {
      setState(() => _error = 'Biometrics not available on this browser.');
      return;
    }

    final success = await security.authenticateWithBiometrics();
    if (success) {
      widget.onEnter();
    } else {
      setState(() => _error = 'Biometric authentication failed.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xxl),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.r(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parent Security', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  errorText: _error,
                  counterText: '',
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _verify,
                      child: const Text('Enter'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClose,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: _tryBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometrics'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
