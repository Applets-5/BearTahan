import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/progress_bar_card.dart';
import '../../widgets/common/star_balance_chip.dart';
import '../../widgets/common/subject_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const subjects = [
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: MascotWidget(message: 'Pick a subject to start!'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ProgressBarCard(
                title: 'Daily Goal',
                subtitle: '2 more lessons to go today',
                progress: .4,
                icon: Icons.flag_rounded,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final s = subjects[index];
                return SubjectCard(
                  name: s.$1,
                  subtitle: s.$2,
                  icon: s.$3,
                  color: s.$4,
                  progress: s.$5,
                  onTap: () => context.go(AppRouter.subject),
                );
              },
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemCount: subjects.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
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
          const StarBalanceChip(count: 120),
        ],
      ),
    );
  }
}
