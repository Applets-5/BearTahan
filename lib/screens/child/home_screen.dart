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

class HomeScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveChildId = childId ?? '';
    final subjectProgressAsync = ref.watch(
      subjectProgressProvider(effectiveChildId),
    );

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
                childId: childId,
                message: 'Pick a subject to start!',
              ),
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
          subjectProgressAsync.when(
            data: (progressList) {
              return SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final s = subjectsList[index];
                    // Match progress from DB using ID
                    final subjectId = _getSubjectId(s.$1);
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

                    return SubjectCard(
                      name: s.$1,
                      subtitle: s.$2,
                      icon: s.$3,
                      color: s.$4,
                      progress: dbSubject.progress,
                      onTap: () => context.go(
                        Uri(
                          path: AppRouter.subject,
                          queryParameters: {
                            'childId': childId ?? '',
                            'subjectId': subjectId,
                          },
                        ).toString(),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemCount: subjectsList.length,
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

  String _getSubjectId(String name) {
    switch (name) {
      case 'Bahasa Melayu':
        return 'bm';
      case 'English':
        return 'en';
      case 'Mandarin':
        return 'bc';
      case 'Mathematics':
        return 'math';
      case 'Science':
        return 'science';
      default:
        return name.toLowerCase().substring(0, math.min(name.length, 2));
    }
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
                    ' ${profile.streakCount}',
                    style: AppTextStyles.bodyBold,
                  ),
                  loading: () =>
                      const Text(' -', style: AppTextStyles.bodyBold),
                  error: (_, _) =>
                      const Text(' 0', style: AppTextStyles.bodyBold),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          userProfileAsync.when(
            data: (profile) => StarBalanceChip(count: profile.starBalance),
            loading: () => const StarBalanceChip(count: 0),
            error: (_, _) => const StarBalanceChip(count: 0),
          ),
        ],
      ),
    );
  }
}
