import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/subject.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
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

  Widget _buildDailyGoalCard(BuildContext context, dynamic profile) {
    final goal = profile.dailyGoal;

    String todayKey() {
      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      return '${now.year}-$month-$day';
    }

    if (goal == null || !goal.isValid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flag_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Goal', style: _AdventureText.cardTitle(context)),
                  const SizedBox(height: 2),
                  Text(
                    'No daily goal set for ${profile.name}',
                    style: _AdventureText.cardBody(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final todayProgress = goal.lastUpdatedDate == todayKey()
        ? goal.todayProgress
        : 0;
    final progress = (todayProgress / goal.target).clamp(0.0, 1.0);
    final icon = goal.type == 'minutes'
        ? Icons.timer_rounded
        : Icons.flag_rounded;
    final bool isComplete = todayProgress >= goal.target;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isComplete ? AppColors.muted : const Color(0xFFFFE7B0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete ? Icons.stars_rounded : icon,
              color: isComplete ? AppColors.primary : const Color(0xFFE67817),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Daily Goal',
                        style: _AdventureText.cardTitle(context),
                      ),
                    ),
                    Text(
                      '$todayProgress/${goal.target}',
                      style: _AdventureText.progressChip(
                        context,
                        isComplete
                            ? AppColors.primary
                            : const Color(0xFFE67817),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    color: isComplete
                        ? AppColors.primary
                        : const Color(0xFFFFA733),
                    backgroundColor: isComplete
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF1D6),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isComplete
                      ? 'Goal completed! $todayProgress/${goal.target} ${goal.unitLabel}'
                      : '${profile.name} has completed $todayProgress of ${goal.target} ${goal.unitLabel} today',
                  style: _AdventureText.cardBody(context),
                ),
              ],
            ),
          ),
        ],
      ),
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
                            onTap: () {
                              context.push(
                                Uri(
                                  path: AppRouter.parentStarHistory,
                                  queryParameters: {'childId': selectedChildId},
                                ).toString(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: StatCard(
                            icon: Icons.menu_book,
                            label: 'Lessons',
                            value: totalCompletedLevels.toString(),
                            color: AppColors.primary,
                            onTap: () {
                              context.push(
                                Uri(
                                  path: AppRouter.lessonHistory,
                                  queryParameters: {'childId': selectedChildId},
                                ).toString(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final bool hasActivityToday =
                                  profile.lastActivityDate != null &&
                                  profile.lastActivityDate!.year ==
                                      DateTime.now().year &&
                                  profile.lastActivityDate!.month ==
                                      DateTime.now().month &&
                                  profile.lastActivityDate!.day ==
                                      DateTime.now().day;

                              return StatCard(
                                icon: Icons.whatshot,
                                label: 'Streak',
                                value: '${profile.streakCount}d',
                                color: hasActivityToday
                                    ? AppColors.destructive
                                    : Colors.grey,
                                onTap: () {
                                  context.push(
                                    Uri(
                                      path: AppRouter.parentStreak,
                                      queryParameters: {
                                        'childId': selectedChildId,
                                      },
                                    ).toString(),
                                  );
                                },
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
                    _buildDailyGoalCard(context, profile),
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
                              subjectId: s['id'] ?? '',
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
      ],
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({
    required this.subjectId,
    required this.label,
    required this.score,
    required this.completedLevels,
    required this.totalStars,
    required this.color,
    this.isLast = false,
  });
  final String subjectId;
  final String label;
  final double score;
  final int completedLevels;
  final int totalStars;
  final Color color;
  final bool isLast;

  String _getCurrentChapter() {
    if (score >= 1.0) return 'Completed';

    if (subjectId == 'bi') {
      if (completedLevels < 4) return 'Chapter 0';
      if (completedLevels < 11) return 'Chapter 1';
      return 'Chapter 2';
    }

    // Default assumes ~6 levels per chapter
    final chapterNum = (completedLevels / 6).floor() + 1;
    return 'Chapter $chapterNum';
  }

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
                  Text(_getCurrentChapter(), style: AppTextStyles.tiny),
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

double _fontScale(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 600) return 1.1; // tablet
  if (w >= 400) return 0.9; // large phone
  return 0.78; // small phone (most Malaysian budget phones)
}

class _AdventureText {
  const _AdventureText._();

  static TextStyle cardTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: (16 * _fontScale(context)).clamp(0.0, 17.0),
      height: 1.1,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF4B2416),
    );
  }

  static TextStyle cardBody(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: (12 * _fontScale(context)).clamp(0.0, 13.0),
      fontWeight: FontWeight.w800,
      color: const Color(0xFF5C341E),
    );
  }

  static TextStyle progressChip(BuildContext context, Color color) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      fontSize: 13 * _fontScale(context),
      fontWeight: FontWeight.w900,
      color: color,
    );
  }
}
