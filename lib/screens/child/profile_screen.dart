import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/parent/stat_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool showPin = false;

  @override
  Widget build(BuildContext context) {
    final childId = ref.watch(childIdProvider) ?? '';
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
                _ActivityCard(),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () => setState(() => showPin = true),
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

class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppTextStyles.bodyBold),
          SizedBox(height: AppSpacing.sm),
          Text('Completed BM Level 4     +3 stars', style: AppTextStyles.small),
          Text(
            'Daily goal met            +5 stars',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _PinModal extends StatelessWidget {
  const _PinModal({required this.onClose, required this.onEnter});
  final VoidCallback onClose;
  final VoidCallback onEnter;

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
              const Text('Parent PIN', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              const TextField(
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Enter PIN'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onEnter,
                      child: const Text('Enter'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
