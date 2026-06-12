import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/subject.dart';
import '../../models/chapter_data.dart';
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
  double _lastScrollOffset = 0;
  double _upwardScrollIntent = 0;
  bool _didScroll = false;
  bool _isStickyHeaderBuilt = false;
  bool _isStickyHeaderVisible = false;

  static const double _scrollDirectionThreshold = 3.0;
  static const double _stickyRevealOffset = 150.0;
  static const double _stickyRevealIntentDistance = 36.0;
  static const Duration _stickyAnimationDuration = Duration(milliseconds: 420);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;

    if (currentOffset <= 0) {
      if (_isStickyHeaderBuilt || _isStickyHeaderVisible) {
        setState(() {
          _isStickyHeaderBuilt = false;
          _isStickyHeaderVisible = false;
        });
      }
      _upwardScrollIntent = 0;
      _lastScrollOffset = currentOffset;
      return;
    }

    final delta = currentOffset - _lastScrollOffset;
    _lastScrollOffset = currentOffset;

    if (delta.abs() < _scrollDirectionThreshold) return;

    final isScrollingTowardTop = delta < 0;

    if (isScrollingTowardTop) {
      _upwardScrollIntent += -delta;
      if (currentOffset > _stickyRevealOffset &&
          _upwardScrollIntent >= _stickyRevealIntentDistance) {
        _showStickyHeader();
      }
    } else {
      _upwardScrollIntent = 0;
      _hideStickyHeader();
    }
  }

  void _showStickyHeader() {
    if (_isStickyHeaderBuilt && _isStickyHeaderVisible) return;

    if (!_isStickyHeaderBuilt) {
      setState(() => _isStickyHeaderBuilt = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_isStickyHeaderBuilt) return;
        setState(() => _isStickyHeaderVisible = true);
      });
      return;
    }

    setState(() => _isStickyHeaderVisible = true);
  }

  void _hideStickyHeader() {
    if (!_isStickyHeaderBuilt || !_isStickyHeaderVisible) return;

    setState(() => _isStickyHeaderVisible = false);
    Future<void>.delayed(_stickyAnimationDuration, () {
      if (!mounted || _isStickyHeaderVisible) return;
      setState(() => _isStickyHeaderBuilt = false);
    });
  }

  void _scrollToActiveLevel({
    required Map<String, int> starMap,
    required List<ChapterData> chapters,
    required bool allChaptersComplete,
  }) {
    if (_didScroll || chapters.isEmpty) return;
    _didScroll = true;

    int activeVisualIndex = 0;
    int currentVisualIndex = 0;
    bool foundActive = false;

    for (var chapter in chapters) {
      // Each chapter starts with a divider (takes 1 visual index)
      currentVisualIndex++;

      for (int i = 0; i < chapter.levelIds.length; i++) {
        final levelId = chapter.levelIds[i];
        final stars = starMap[levelId] ?? 0;

        bool isUnlocked;
        if (chapters.first == chapter && i == 0) {
          isUnlocked = true;
        } else {
          String? prevLevelId;
          if (i > 0) {
            prevLevelId = chapter.levelIds[i - 1];
          } else {
            final chapterIdx = chapters.indexOf(chapter);
            if (chapterIdx > 0) {
              final prevChapter = chapters[chapterIdx - 1];
              prevLevelId = prevChapter.levelIds.last;
            }
          }
          isUnlocked = prevLevelId != null && (starMap[prevLevelId] ?? 0) > 0;
        }

        bool isCompleted = stars > 0;

        if (isUnlocked && !isCompleted) {
          activeVisualIndex = currentVisualIndex;
          foundActive = true;
          break;
        }
        currentVisualIndex++;
      }
      if (foundActive) break;
    }

    // Rough estimate of scroll offset matching LevelWindingPath's verticalStep
    const double verticalStep = 160.0;
    const double headerHeight = 220.0; // Estimate of _SubjectHeader height
    double offset;

    if (!foundActive && allChaptersComplete) {
      // All levels complete, scroll to revision section at bottom
      offset = (currentVisualIndex * verticalStep) + headerHeight + 100;
    } else {
      offset = (activeVisualIndex * verticalStep) + headerHeight - 100;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Clamp offset to scroll bounds
        double maxScroll = _scrollController.position.maxScrollExtent;
        double targetOffset = offset.clamp(0.0, maxScroll);

        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
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

    final subjectProgressAsync = ref.watch(
      subjectProgressProvider(effectiveChildId),
    );

    return Scaffold(
      body: starsAsync.when(
        data: (starMap) {
          return chaptersAsync.when(
            data: (chapters) {
              return subjectProgressAsync.when(
                data: (progressList) {
                  // ... (rest of data logic)
                  final dbSubject = progressList.firstWhere(
                    (s) => s.id == widget.subjectId,
                    orElse: () => Subject(
                      id: widget.subjectId,
                      name: '',
                      subtitle: '',
                      icon: Icons.help,
                      color: Colors.grey,
                      progress: 0,
                    ),
                  );

                  final bool showRevision = dbSubject.allChaptersComplete;
                  final String revisionLevelId = '${widget.subjectId}_revision';

                  final Set<String> validLevelIds = chapters
                      .expand((c) => c.levelIds)
                      .toSet();
                  if (showRevision) {
                    validLevelIds.add(revisionLevelId);
                  }

                  // Calculate progress based on dynamic chapters and filter out ghost levels
                  int totalPossibleLevels = validLevelIds.length;
                  int completedCount = starMap.entries
                      .where(
                        (e) => validLevelIds.contains(e.key) && e.value > 0,
                      )
                      .length;
                  double progress = totalPossibleLevels > 0
                      ? completedCount / totalPossibleLevels
                      : 0;

                  // Trigger auto-scroll once
                  _scrollToActiveLevel(
                    starMap: starMap,
                    chapters: chapters,
                    allChaptersComplete: showRevision,
                  );

                  return Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _SubjectHeader(
                              completedCount: completedCount,
                              totalCount: totalPossibleLevels,
                              progress: progress,
                              subjectId: widget.subjectId,
                              onBack: () => context.go(
                                AppRouter.childHomeFor(widget.childId),
                              ),
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
                                String prefix =
                                    '${widget.subjectId}_${levelId}_';

                                // If it's a summary level, route to the Chapter intro screen instead of direct session
                                if (levelId.toLowerCase().contains('summary')) {
                                  context.push(
                                    AppRouter.chapterFor(
                                      widget.childId,
                                      subjectId: widget.subjectId,
                                      chapterId: chapterId,
                                    ),
                                  );
                                  return;
                                }

                                context.push(
                                  AppRouter.levelSessionFor(
                                    widget.childId,
                                    levelPrefix: prefix,
                                    subjectId: widget.subjectId,
                                    levelId:
                                        levelId, // Pass the explicit levelId so progress saves under 'c1_summary', 'c1_l4', etc.
                                  ),
                                );
                              },
                            ),
                          ),
                          if (showRevision)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xl,
                                  0,
                                  AppSpacing.xl,
                                  AppSpacing.xxxl,
                                ),
                                child: Column(
                                  children: [
                                    const Divider(height: 40),
                                    const Text(
                                      'CHALLENGE UNLOCKED!',
                                      style: AppTextStyles.cardTitle,
                                    ),
                                    const Text(
                                      'Mix and review everything you learned!',
                                      style: AppTextStyles.small,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _RevisionNode(
                                      levelId: revisionLevelId,
                                      stars: starMap[revisionLevelId] ?? 0,
                                      onTap: () {
                                        context.push(
                                          AppRouter.levelSessionFor(
                                            widget.childId,
                                            levelPrefix:
                                                '${widget.subjectId}_', // Prefix for all subject questions
                                            subjectId: widget.subjectId,
                                            levelId: revisionLevelId,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_isStickyHeaderBuilt)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: AnimatedSlide(
                            offset: _isStickyHeaderVisible
                                ? Offset.zero
                                : const Offset(0, -1),
                            duration: _stickyAnimationDuration,
                            curve: Curves.easeOutQuart,
                            child: _SubjectHeader(
                              subjectId: widget.subjectId,
                              completedCount: completedCount,
                              totalCount: totalPossibleLevels,
                              progress: progress,
                              onBack: () => context.go(
                                AppRouter.childHomeFor(widget.childId),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading progress: $err')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading chapters: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.subjectId,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.onBack,
  });

  final String subjectId;
  final int completedCount;
  final int totalCount;
  final double progress;
  final VoidCallback onBack;

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
      case 'sci':
        return 'Science';
      default:
        return 'Subject';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          label: const Text('Back', style: AppTextStyles.whiteSmall),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
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
    );
  }
}

class _RevisionNode extends StatelessWidget {
  const _RevisionNode({
    required this.levelId,
    required this.stars,
    required this.onTap,
  });

  final String levelId;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.strong,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 50),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('REVISION', style: AppTextStyles.bodyBold),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Icon(
                Icons.star_rounded,
                color: index < stars ? AppColors.star : Colors.grey[300],
                size: 24,
              );
            }),
          ),
        ],
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
      case 'sci':
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
        child: _HeaderContent(
          subjectId: subjectId,
          completedCount: completedCount,
          totalCount: totalCount,
          progress: progress,
          onBack: onBack,
        ),
      ),
    );
  }
}
