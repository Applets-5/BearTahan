import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_profile.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/progress_bar_card.dart';
import '../../widgets/parent/stat_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool expanded = false;

  final List<Map<String, dynamic>> _defaultSubjects = [
    {'id': 'bm', 'name': 'Bahasa Melayu', 'color': AppColors.subjectBm},
    {'id': 'en', 'name': 'English', 'color': AppColors.subjectEnglish},
    {'id': 'math', 'name': 'Mathematics', 'color': AppColors.subjectMath},
    {'id': 'science', 'name': 'Science', 'color': AppColors.subjectScience},
    {'id': 'bc', 'name': 'Mandarin', 'color': AppColors.subjectMandarin},
  ];

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

        final childProfileAsync = ref.watch(
          userProfileProvider(selectedChildId),
        );
        final subjectsAsync = ref.watch(
          subjectProgressProvider(selectedChildId),
        );

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Dashboard', style: AppTextStyles.screenTitle),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => expanded = !expanded),
                    icon: const Icon(Icons.child_care),
                    label: Text(selectedChild.name),
                  ),
                ],
              ),
              if (expanded)
                _ChildPicker(
                  children: children,
                  onPick: (id) {
                    ref.read(childIdProvider.notifier).update(id);
                    setState(() => expanded = false);
                  },
                ),
              const SizedBox(height: AppSpacing.md),
              childProfileAsync.when(
                data: (profile) {
                  return subjectsAsync.when(
                    data: (subjects) {
                      // Merge real data with default subjects to ensure all are shown
                      final List<Map<String, dynamic>> displaySubjects =
                          _defaultSubjects.map((defaultSub) {
                            final realSub = subjects.cast().firstWhere(
                              (s) => s.id == defaultSub['id'],
                              orElse: () => null,
                            );
                            return {
                              'name': defaultSub['name'],
                              'progress': realSub != null ? realSub.progress : 0,
                              'completedLevels':
                                  realSub != null ? realSub.completedLevels : 0,
                              'totalStars':
                                  realSub != null ? realSub.totalStars : 0,
                              'color': defaultSub['color'],
                            };
                          }).toList();

                      int totalProgress = displaySubjects.fold(
                        0,
                        (sum, s) => sum + (s['progress'] as int),
                      );
                      int avgProgress = (totalProgress / displaySubjects.length)
                          .round();

                      // Aggregated stats for top cards
                      int totalCompletedLevels = displaySubjects.fold(
                        0,
                        (sum, s) => sum + (s['completedLevels'] as int),
                      );
                      int totalStarsEarned = displaySubjects.fold(
                        0,
                        (sum, s) => sum + (s['totalStars'] as int),
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
                                  value: totalStarsEarned.toString(),
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
                                        'Spendable balance: ${profile.starBalance} stars',
                                        style: AppTextStyles.bodyBold,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ProgressBarCard(
                            title: 'Overall Progress',
                            subtitle: '$avgProgress% of all subjects completed',
                            progress: avgProgress / 100,
                            icon: Icons.flag_rounded,
                          ),
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
              const _RecentActivity(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading children: $e')),
    );
  }
}

class _ChildPicker extends StatelessWidget {
  const _ChildPicker({required this.children, required this.onPick});
  final List<UserProfile> children;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: children
            .map(
              (child) => ListTile(
                title: Text(child.name, style: AppTextStyles.bodyBold),
                subtitle: Text(
                  'Streak: ${child.streakCount} days',
                  style: AppTextStyles.small,
                ),
                onTap: () => onPick(child.uid),
              ),
            )
            .toList(),
      ),
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
                  Text('$totalStars ', style: AppTextStyles.tiny),
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

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppTextStyles.bodyBold),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Completed Math Level 3       +2 stars',
            style: AppTextStyles.small,
          ),
          Text(
            'Claimed Extra Screen Time   -40 stars',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}
