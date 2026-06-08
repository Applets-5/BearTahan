import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/level_winding_path.dart';

class SubjectScreen extends ConsumerStatefulWidget {
  const SubjectScreen({super.key, this.childId, this.subjectId = 'bm'});

  final String? childId;
  final String subjectId;

  @override
  ConsumerState<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends ConsumerState<SubjectScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _didScroll = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLevel(Map<String, int> starMap) {
    if (_didScroll) return;
    _didScroll = true;

    int activeIndex = 0;
    for (int i = 0; i < 8; i++) {
      final levelId = 'l${i + 1}';
      final stars = starMap[levelId] ?? 0;
      bool isUnlocked = i == 0 || (starMap['l$i'] ?? 0) > 0;
      bool isCompleted = stars > 0;

      if (isUnlocked && !isCompleted) {
        activeIndex = i;
        break;
      }
    }

    // Rough estimate of scroll offset
    double offset = (activeIndex * 160.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveChildId = widget.childId ?? '';
    final starsAsync = ref.watch(
      levelStarsProvider((
        childId: effectiveChildId,
        subjectId: widget.subjectId,
      )),
    );
    final chaptersAsync = ref.watch(subjectChaptersProvider(widget.subjectId));

    return Scaffold(
      body: starsAsync.when(
        data: (starMap) {
          return chaptersAsync.when(
            data: (chapters) {
              // Calculate progress based on dynamic chapters
              int totalPossibleLevels = chapters.fold(0, (sum, c) => sum + c.levelIds.length);
              int completedCount = starMap.values.where((s) => s > 0).length;
              double progress = totalPossibleLevels > 0 ? completedCount / totalPossibleLevels : 0;

              // Trigger auto-scroll once
              _scrollToActiveLevel(starMap);

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _SubjectHeader(
                      completedCount: completedCount,
                      totalCount: totalPossibleLevels,
                      progress: progress,
                      subjectId: widget.subjectId,
                      onBack: () => context.go(AppRouter.childHomeFor(widget.childId)),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: LevelWindingPath(
                      starMap: starMap,
                      chapters: chapters,
                      subjectId: widget.subjectId,
                      childId: widget.childId,
                      onLevelTap: (levelId, isBoss, chapterId) {
                        // levelId is already namespaced with the chapter (e.g., 'c1_l4' or 'c1_summary')
                        String prefix = '${widget.subjectId}_${levelId}_';
                        
                        // If it's a summary level, query all questions from the chapter
                        if (levelId.toLowerCase().contains('summary')) {
                          prefix = '${widget.subjectId}_${chapterId}_';
                        }

                        context.push(
                          AppRouter.levelSessionFor(
                            widget.childId,
                            levelPrefix: prefix,
                            subjectId: widget.subjectId,
                            levelId: levelId, // Pass the explicit levelId so progress saves under 'c1_summary', 'c1_l4', etc.
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading chapters: $err')),
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
      case 'bi':
        return 'English';
      case 'bc':
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
      case 'bi':
        return AppColors.subjectEnglish;
      case 'bc':
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
