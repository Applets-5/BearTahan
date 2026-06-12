import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/subject.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/progress_bar_card.dart';
import '../../widgets/common/star_balance_chip.dart';
import '../../widgets/common/subject_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.childId});

  final String? childId;

  static const subjectsList = [
    (
      'Bahasa Melayu',
      'Membaca & Menulis',
      Icons.edit_rounded,
      AppColors.subjectBm,
      45,
    ),
    (
      'English',
      'Reading & Writing',
      Icons.menu_book_rounded,
      AppColors.subjectEnglish,
      30,
    ),
    (
      'Mandarin',
      'Chinese characters',
      Icons.translate_rounded,
      AppColors.subjectMandarin,
      20,
    ),
    (
      'Mathematics',
      'Numbers & shapes',
      Icons.calculate_rounded,
      AppColors.subjectMath,
      55,
    ),
    (
      'Science',
      'Explore & discover',
      Icons.science_rounded,
      AppColors.subjectScience,
      25,
    ),
  ];

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();

  static String _getSubjectId(String name) {
    switch (name) {
      case 'Bahasa Melayu':
        return 'bm';
      case 'English':
        return 'bi';
      case 'Mandarin':
        return 'bc';
      case 'Mathematics':
        return 'math';
      case 'Science':
        return 'sci';
      default:
        return name.toLowerCase().substring(0, math.min(name.length, 2));
    }
  }
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final effectiveChildId = widget.childId ?? '';
    if (effectiveChildId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final subjectProgressAsync = ref.watch(
      subjectProgressProvider(effectiveChildId),
    );
    final totalLevelsAsync = ref.watch(allSubjectsTotalLevelsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(childId: effectiveChildId)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: ActiveMascotWidget(
                childId: widget.childId,
                message: 'Pick a subject to start!',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _MemoryChallengeBanner(childId: effectiveChildId),
          ),
          SliverToBoxAdapter(child: _DailyGoalCard(childId: effectiveChildId)),
          subjectProgressAsync.when(
            data: (progressList) {
              return totalLevelsAsync.when(
                data: (totals) {
                  // Calculate average progress
                  int totalProgress = 0;
                  for (var s in HomeScreen.subjectsList) {
                    final id = HomeScreen._getSubjectId(s.$1);
                    final dbS = progressList.firstWhere(
                      (p) => p.id == id,
                      orElse: () => Subject(
                        id: id,
                        name: s.$1,
                        subtitle: s.$2,
                        icon: s.$3,
                        color: s.$4,
                        progress: 0,
                      ),
                    );

                    final total = totals[id] ?? 8;
                    final calculatedProgress = total > 0
                        ? (dbS.completedLevels / total * 100).toInt().clamp(
                            0,
                            100,
                          )
                        : 0;
                    totalProgress += calculatedProgress;
                  }
                  final avgProgress =
                      (totalProgress / HomeScreen.subjectsList.length).round();

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: ProgressBarCard(
                        title: 'Overall Progress',
                        subtitle: '$avgProgress% of all subjects completed',
                        progress: avgProgress / 100,
                        icon: Icons.flag_rounded,
                      ),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (err, _) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: LinearProgressIndicator(),
              ),
            ),
            error: (err, _) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          subjectProgressAsync.when(
            data: (progressList) {
              return totalLevelsAsync.when(
                data: (totals) {
                  return SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final s = HomeScreen.subjectsList[index];
                        // Match progress from DB using ID
                        final subjectId = HomeScreen._getSubjectId(s.$1);
                        final dbSubject = progressList.firstWhere(
                          (dbS) => dbS.id == subjectId,
                          orElse: () => Subject(
                            id: subjectId,
                            name: s.$1,
                            subtitle: s.$2,
                            icon: s.$3,
                            color: s.$4,
                            progress: 0,
                          ),
                        );

                        final total = totals[subjectId] ?? 8;
                        final calculatedProgress = total > 0
                            ? (dbSubject.completedLevels / total * 100)
                                  .toInt()
                                  .clamp(0, 100)
                            : 0;

                        return SubjectCard(
                          name: s.$1,
                          subtitle: s.$2,
                          icon: s.$3,
                          color: s.$4,
                          progress: calculatedProgress,
                          completedLevels: dbSubject.completedLevels,
                          totalStars: dbSubject.totalStars,
                          onTap: () => context.go(
                            Uri(
                              path: AppRouter.subject,
                              queryParameters: {
                                'childId': widget.childId ?? '',
                                'subjectId': subjectId,
                              },
                            ).toString(),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemCount: HomeScreen.subjectsList.length,
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $err')),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends ConsumerWidget {
  const _DailyGoalCard({required this.childId});

  final String childId;

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(childId));

    return userProfileAsync.maybeWhen(
      data: (profile) {
        final goal = profile.dailyGoal;
        if (goal == null || !goal.isValid) {
          return const SizedBox.shrink();
        }

        final todayProgress = goal.lastUpdatedDate == _todayKey()
            ? goal.todayProgress
            : 0;
        final progress = (todayProgress / goal.target)
            .clamp(0.0, 1.0)
            .toDouble();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: ProgressBarCard(
            title: 'Daily Goal',
            subtitle:
                '$todayProgress of ${goal.target} ${goal.unitLabel} completed today',
            progress: progress,
            icon: goal.type == 'minutes' ? Icons.timer : Icons.flag_rounded,
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(childId));

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
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppColors.destructive,
                  size: AppSpacing.lg,
                ),
                userProfileAsync.when(
                  data: (profile) => Text(
                    ' ${profile.streakCount} days',
                    style: AppTextStyles.bodyBold,
                  ),
                  loading: () =>
                      const Text(' - days', style: AppTextStyles.bodyBold),
                  error: (_, _) =>
                      const Text(' 0 days', style: AppTextStyles.bodyBold),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          userProfileAsync.when(
            data: (profile) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarBalanceChip(
                  count: profile.lifetimeStarsEarned,
                  label: 'Total',
                ),
                const SizedBox(width: AppSpacing.sm),
                StarBalanceChip(
                  count: profile.availableStars,
                  label: 'Available',
                ),
              ],
            ),
            loading: () => const StarBalanceChip(count: 0),
            error: (_, _) => const StarBalanceChip(count: 0),
          ),
        ],
      ),
    );
  }
}

class _MemoryChallengeBanner extends ConsumerWidget {
  const _MemoryChallengeBanner({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswerCountAsync = ref.watch(wrongAnswerCountProvider(childId));

    return wrongAnswerCountAsync.maybeWhen(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Material(
            color: AppColors.secondary,
            borderRadius: AppRadius.r(AppRadius.lg),
            child: InkWell(
              onTap: () => context.push(
                '${AppRouter.memory}?childId=$childId',
              ),
              borderRadius: AppRadius.r(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Bear's Memory Challenge",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$count tricky questions to review!",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
