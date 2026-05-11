import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_profile.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/progress_bar_card.dart';
import '../../widgets/common/star_balance_chip.dart';
import '../../widgets/common/subject_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final subjectsAsync = ref.watch(subjectProgressProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: userProfileAsync.when(
              data: (profile) => _Header(profile: profile),
              loading: () => const _HeaderSkeleton(),
              error: (e, s) => const _Header(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: userProfileAsync.when(
                data: (profile) => MascotWidget(
                  message: 'Hello ${profile.name}! Wearing my ${profile.activeMascotOutfit} today!',
                ),
                loading: () => const MascotWidget(message: 'Loading...'),
                error: (e, s) => const MascotWidget(message: 'Pick a subject to start!'),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ProgressBarCard(
                title: 'Daily Goal',
                subtitle: 'Keep it up!',
                progress: .4,
                icon: Icons.flag_rounded,
              ),
            ),
          ),
          subjectsAsync.when(
            data: (subjects) {
              if (subjects.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No subjects found.'),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final uid = ref.read(userIdProvider);
                              await ref.read(firestoreServiceProvider).seedMockData(uid);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Mock data seeded successfully!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error seeding data: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Seed Mock Data'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final s = subjects[index];
                    return SubjectCard(
                      name: s.name,
                      subtitle: s.subtitle,
                      icon: s.icon,
                      color: s.color,
                      progress: s.progress,
                      onTap: () => context.go(AppRouter.subject),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemCount: subjects.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.destructive, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Oops! Something went wrong.',
                        style: AppTextStyles.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        e.toString(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.small,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            final uid = ref.read(userIdProvider);
                            await ref.read(firestoreServiceProvider)
                                .seedMockData(uid);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Mock data seeded successfully!')),
                              );
                            }
                          } catch (err) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error seeding data: $err')),
                              );
                            }
                          }
                        },
                        child: const Text('Try Seeding Mock Data'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UserProfile? profile;

  const _Header({this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('BearTahan', style: AppTextStyles.screenTitle),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.destructiveLight,
              borderRadius: AppRadius.r(AppRadius.xl),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.destructive,
                  size: AppSpacing.lg,
                ),
                Text(' 5', style: AppTextStyles.bodyBold),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StarBalanceChip(count: profile?.starBalance ?? 0),
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const _Header();
  }
}
