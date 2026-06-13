import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/subject.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/progress_bar_card.dart';
import '../../widgets/parent/stat_card.dart';
import 'bear_ai_tab.dart';
import '../../features/bears_den/chapter_insights_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final selectedChildId = ref.watch(childIdProvider);

    return childrenAsync.when(
      data: (children) {
        if (children.isEmpty) {
          return const Center(
            child: Text('No children found. Add one in settings.'),
          );
        }

        // Auto-select first child if none selected
        if (selectedChildId == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(childIdProvider.notifier).update(children.first.uid);
          });
          return const Center(child: CircularProgressIndicator());
        }

        final selectedChild = children.firstWhere(
          (c) => c.uid == selectedChildId,
          orElse: () => children.first,
        );

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              toolbarHeight: 70,
              backgroundColor: AppColors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (id) {
                      ref.read(childIdProvider.notifier).update(id);
                    },
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.r(AppRadius.lg),
                    ),
                    itemBuilder: (context) => children.map((child) {
                      return PopupMenuItem<String>(
                        value: child.uid,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.face,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(child.name, style: AppTextStyles.bodyBold),
                                Text(
                                  'Streak: ${child.streakCount} days',
                                  style: AppTextStyles.tiny,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: AppRadius.r(AppRadius.xl),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.child_care,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            selectedChild.name,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: AppRadius.r(AppRadius.lg),
                  ),
                  child: TabBar(
                    isScrollable: false,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.r(AppRadius.md),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.mutedText,
                    labelStyle: AppTextStyles.bodyBold,
                    unselectedLabelStyle: AppTextStyles.body,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'BearAI'),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(selectedChildId: selectedChildId),
                BearAITab(childId: selectedChildId),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading children: $e')),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final String selectedChildId;

  const _OverviewTab({required this.selectedChildId});

  Widget _buildDailyGoalCard(dynamic profile) {
    final goal = profile.dailyGoal;
    if (goal == null || !goal.isValid) {
      return ProgressBarCard(
        title: 'Daily Goal',
        subtitle: 'No daily goal set for ${profile.name}',
        progress: 0,
        icon: Icons.flag_outlined,
      );
    }

    final double progress = (goal.todayProgress / goal.target).clamp(0.0, 1.0);
    final String unit = goal.unitLabel;
    final bool isComplete = goal.todayProgress >= goal.target;

    return ProgressBarCard(
      title: 'Daily Goal',
      subtitle: isComplete
          ? 'Goal completed! ${goal.todayProgress}/$goal.target $unit'
          : '${profile.name} has completed ${goal.todayProgress} of $goal.target $unit today',
      progress: progress,
      icon: isComplete ? Icons.stars_rounded : Icons.flag_rounded,
      color: isComplete ? AppColors.star : AppColors.primary,
    );
  }

  final List<Map<String, dynamic>> _defaultSubjects = const [
    {'id': 'bm', 'name': 'Bahasa Melayu', 'color': AppColors.subjectBm},
    {'id': 'bi', 'name': 'English', 'color': AppColors.subjectEnglish},
    {'id': 'math', 'name': 'Mathematics', 'color': AppColors.subjectMath},
    {'id': 'sci', 'name': 'Science', 'color': AppColors.subjectScience},
    {'id': 'bc', 'name': 'Mandarin', 'color': AppColors.subjectMandarin},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childProfileAsync = ref.watch(userProfileProvider(selectedChildId));
    final subjectsAsync = ref.watch(subjectProgressProvider(selectedChildId));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        childProfileAsync.when(
          data: (profile) {
            return subjectsAsync.when(
              data: (subjects) {
                // Merge real data with default subjects to ensure all are shown
                final List<Map<String, dynamic>>
                displaySubjects = _defaultSubjects.map((defaultSub) {
                  final realSub = subjects.cast<Subject?>().firstWhere(
                    (s) => s?.id == defaultSub['id'],
                    orElse: () => null,
                  );

                  // Self-healing: if the subject exists but is missing aggregation, trigger a sync
                  if (realSub != null &&
                      (realSub.totalStars == 0 && realSub.progress > 0)) {
                    debugPrint(
                      'DEBUG: Self-healing triggered for ${realSub.id} on dashboard',
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final parentId = ref.read(parentIdProvider);
                      ref
                          .read(firestoreServiceProvider)
                          .syncSubjectAggregation(
                            parentId,
                            selectedChildId,
                            realSub.id,
                          );
                    });
                  }

                  return {
                    'name': defaultSub['name'],
                    'progress': realSub != null ? realSub.progress : 0,
                    'completedLevels': realSub != null
                        ? realSub.completedLevels
                        : 0,
                    'totalStars': realSub != null ? realSub.totalStars : 0,
                    'color': defaultSub['color'],
                  };
                }).toList();

                // Aggregated stats for top cards
                int totalCompletedLevels = displaySubjects.fold(
                  0,
                  (sum, s) => sum + (s['completedLevels'] as int),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.auto_awesome,
                            label: 'Stars Earned',
                            value: profile.lifetimeStarsEarned.toString(),
                            color: AppColors.star,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatCard(
                            icon: Icons.menu_book,
                            label: 'Lessons',
                            value: totalCompletedLevels.toString(),
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatCard(
                            icon: Icons.trending_up,
                            label: 'Streak',
                            value: '${profile.streakCount}d',
                            color: AppColors.accent,
                            onTap: () {
                              context.push(
                                Uri(
                                  path: AppRouter.parentStreak,
                                  queryParameters: {'childId': selectedChildId},
                                ).toString(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: AppRadius.r(AppRadius.lg),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppColors.star,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Available: ${profile.availableStars} stars',
                                  style: AppTextStyles.bodyBold,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDailyGoalCard(profile),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: AppRadius.r(AppRadius.xl),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subject Progress',
                            style: AppTextStyles.bodyBold,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...displaySubjects.map(
                            (s) => _SubjectProgress(
                              label: s['name'],
                              score: (s['progress'] as int) / 100,
                              completedLevels: s['completedLevels'],
                              totalStars: s['totalStars'],
                              color: s['color'],
                              isLast: displaySubjects.last == s,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ChapterInsightsCard(),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, st) => Text('Error loading subjects: $e'),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, st) => Text('Error loading profile: $e'),
        ),
        const SizedBox(height: AppSpacing.lg),
        _RecentActivity(childId: selectedChildId),
      ],
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({
    required this.label,
    required this.score,
    required this.completedLevels,
    required this.totalStars,
    required this.color,
    this.isLast = false,
  });
  final String label;
  final double score;
  final int completedLevels;
  final int totalStars;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.small)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$completedLevels lessons', style: AppTextStyles.tiny),
                  const Text(' • ', style: AppTextStyles.tiny),
                  Text('$totalStars '),
                  const Icon(Icons.star, size: 10, color: AppColors.star),
                  const Text(' • ', style: AppTextStyles.tiny),
                  Text('${(score * 100).round()}%', style: AppTextStyles.tiny),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.r(AppRadius.sm),
            child: LinearProgressIndicator(
              value: score,
              minHeight: AppSpacing.sm,
              color: color,
              backgroundColor: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(parentIdProvider);
    final transactionsAsync = ref.watch(
      starTransactionsProvider((parentId: parentId, childId: childId)),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: AppTextStyles.bodyBold),
              TextButton(
                onPressed: () {
                  context.push(
                    Uri(
                      path: AppRouter.starHistory,
                      queryParameters: {'childId': childId},
                    ).toString(),
                  );
                },
                child: const Text('View All', style: AppTextStyles.tiny),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: AppTextStyles.small,
                    ),
                  ),
                );
              }

              // Only show top 5 on dashboard
              final recent = transactions.take(5).toList();

              return Column(
                children: recent.map((tx) {
                  final isEarn = tx.type == 'earn';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          isEarn
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          size: 14,
                          color: isEarn
                              ? AppColors.accent
                              : AppColors.destructive,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            tx.description,
                            style: AppTextStyles.small,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          isEarn ? '+${tx.amount}' : '-${tx.amount.abs()}',
                          style: AppTextStyles.small.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isEarn
                                ? AppColors.accent
                                : AppColors.destructive,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.star, size: 12, color: AppColors.star),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Error: $err', style: AppTextStyles.tiny),
          ),
        ],
      ),
    );
  }
}
