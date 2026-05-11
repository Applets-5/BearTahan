import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/level_tile.dart';
import '../../widgets/common/locked_level_tile.dart';

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key, this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _SubjectHeader(
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
                if (index > 4) {
                  return LockedLevelTile(
                    title: 'Level ${index + 1}',
                    subtitle: 'Complete previous level to unlock',
                  );
                }
                final boss = index == 4;
                return LevelTile(
                  title: boss ? 'Chapter Summary' : 'Level ${index + 1}',
                  subtitle: boss
                      ? 'Boss challenge'
                      : 'Practice words and sounds',
                  stars: index < 2
                      ? 3
                      : index == 2
                      ? 1
                      : 0,
                  isBoss: boss,
                  onTap: () => context.push(
                    boss
                        ? AppRouter.chapterFor(childId)
                        : AppRouter.levelSessionFor(childId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.onBack});
  final VoidCallback onBack;

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
        color: AppColors.subjectBm,
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
            const Text('Bahasa Melayu', style: AppTextStyles.whiteTitle),
            const Text(
              '3/12 levels completed',
              style: AppTextStyles.whiteSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.r(AppRadius.sm),
              child: const LinearProgressIndicator(
                value: .25,
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
