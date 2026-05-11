import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/level_tile.dart';
import '../../widgets/common/locked_level_tile.dart';

class SubjectScreen extends ConsumerWidget {
  const SubjectScreen({super.key, this.childId, this.subjectId = 'bm'});

  final String? childId;
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final starsAsync = ref.watch(levelStarsProvider(subjectId));

    return Scaffold(
      body: starsAsync.when(
        data: (starMap) {
          int completedCount = starMap.values.where((s) => s > 0).length;
          double progress = completedCount / 8;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SubjectHeader(
                  completedCount: completedCount,
                  totalCount: 8,
                  progress: progress,
                  subjectId: subjectId,
                  onBack: () => context.go(AppRouter.childHomeFor(childId)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: 8,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final levelId = 'l${index + 1}';
                    final stars = starMap[levelId] ?? 0;
                    
                    // Logic: Level 1 is always unlocked. 
                    // Others unlock if the previous level has at least 1 star.
                    bool isUnlocked = index == 0 || (starMap['l$index'] ?? 0) > 0;

                    if (!isUnlocked) {
                      final isBoss = index == 4;
                      return LockedLevelTile(
                        title: isBoss ? 'Chapter Summary' : 'Level ${index + 1}',
                        subtitle: isBoss ? 'Boss challenge' : 'Complete previous level to unlock',
                      );
                    }

                    final boss = index == 4;
                    return LevelTile(
                      title: boss ? 'Chapter Summary' : 'Level ${index + 1}',
                      subtitle: boss ? 'Boss challenge' : 'Practice words and sounds',
                      stars: stars,
                      isBoss: boss,
                      onTap: () => context.push(
                        AppRouter.levelSessionFor(
                          childId,
                          levelPrefix: '${subjectId}_c1_${levelId}_',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({
    required this.onBack,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.subjectId,
  });
  final VoidCallback onBack;
  final int completedCount;
  final int totalCount;
  final double progress;
  final String subjectId;

  String _getSubjectName() {
    switch (subjectId) {
      case 'bm':
        return 'Bahasa Melayu';
      case 'english':
        return 'English';
      case 'mandarin':
        return 'Mandarin';
      case 'math':
        return 'Mathematics';
      case 'science':
        return 'Science';
      default:
        return 'Subject';
    }
  }

  Color _getSubjectColor() {
    switch (subjectId) {
      case 'bm':
        return AppColors.subjectBm;
      case 'english':
        return AppColors.subjectEnglish;
      case 'mandarin':
        return AppColors.subjectMandarin;
      case 'math':
        return AppColors.subjectMath;
      case 'science':
        return AppColors.subjectScience;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: _getSubjectColor(),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Back', style: AppTextStyles.whiteSmall),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(_getSubjectName(), style: AppTextStyles.whiteTitle),
            Text(
              '$completedCount/$totalCount levels completed',
              style: AppTextStyles.whiteSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.r(AppRadius.sm),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppSpacing.sm,
                color: Colors.white70,
                backgroundColor: Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
