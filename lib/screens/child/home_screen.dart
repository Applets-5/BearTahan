import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/subject.dart';
import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';

double _fontScale(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w >= 600) return 1.1; // tablet
  if (w >= 400) return 0.9; // large phone
  return 0.78; // small phone (most Malaysian budget phones)
}

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
        return name.toLowerCase().substring(0, name.length.clamp(0, 2));
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
      child: Container(
        color: const Color(0xFFFFF8EE),
        child: subjectProgressAsync.when(
          data: (progressList) {
            return totalLevelsAsync.when(
              data: (totals) {
                final worlds = _buildSubjectWorlds(progressList, totals);
                final averageProgress = worlds.isEmpty
                    ? 0
                    : (worlds.fold<int>(
                                0,
                                (sum, world) => sum + world.progress,
                              ) /
                              worlds.length)
                          .round();

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _ForestHero(childId: effectiveChildId),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: _MemoryQuestCard(childId: effectiveChildId),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: _AdventureProgressCard(
                          progress: averageProgress,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: worlds.length,
                        itemBuilder: (context, index) {
                          final world = worlds[index];
                          return _AdventureSubjectCard(
                            world: world,
                            onTap: () => context.go(
                              Uri(
                                path: AppRouter.subject,
                                queryParameters: {
                                  'childId': widget.childId ?? '',
                                  'subjectId': world.subjectId,
                                },
                              ).toString(),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  List<_SubjectWorld> _buildSubjectWorlds(
    List<Subject> progressList,
    Map<String, int> totals,
  ) {
    return HomeScreen.subjectsList.map((subject) {
      final subjectId = HomeScreen._getSubjectId(subject.$1);
      final dbSubject = progressList.firstWhere(
        (p) => p.id == subjectId,
        orElse: () => Subject(
          id: subjectId,
          name: subject.$1,
          subtitle: subject.$2,
          icon: subject.$3,
          color: subject.$4,
          progress: 0,
        ),
      );

      final total = totals[subjectId] ?? 8;
      final calculatedProgress = total > 0
          ? (dbSubject.completedLevels / total * 100).toInt().clamp(0, 100)
          : 0;

      return _SubjectWorld.fromSubject(
        subjectId: subjectId,
        fallbackName: subject.$1,
        fallbackSubtitle: subject.$2,
        progress: calculatedProgress,
        completedLevels: dbSubject.completedLevels,
        totalStars: dbSubject.totalStars,
      );
    }).toList();
  }
}

class _ForestHero extends ConsumerWidget {
  const _ForestHero({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider(childId));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF73D7FF), Color(0xFFE6F8FF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2673D7FF),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            top: 14,
            child: Image.asset('assets/images/cloud1.png', width: 80),
          ),
          Positioned(
            right: 6,
            top: 48,
            child: Image.asset('assets/images/cloud2.png', width: 65),
          ),
          const Positioned(right: 34, bottom: 26, child: _Sparkle(size: 18)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'assets/images/grass.png',
              fit: BoxFit.fitWidth,
              height: 44,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'BearTahan',
                        style: _AdventureText.logo(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    userProfileAsync.when(
                      data: (profile) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HeroStatPill(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFFF6B35),
                            value: profile.streakCount.toString(),
                            label: 'Day Streak',
                            onTap: () {
                              context.push(
                                Uri(
                                  path: AppRouter.streak,
                                  queryParameters: {'childId': childId},
                                ).toString(),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          _HeroStatPill(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFFFC400),
                            value: profile.lifetimeStarsEarned.toString(),
                            label: 'Total Stars',
                          ),
                        ],
                      ),
                      loading: () => const _HeroStatsSkeleton(),
                      error: (_, _) => const _HeroStatsSkeleton(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.96, end: 1),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: ActiveMascotWidget(
                            childId: childId,
                            size: constraints.maxWidth >= 600
                                ? 120
                                : (constraints.maxWidth < 380 ? 72 : 88),
                            showBackground: false,
                            mood: MascotMood.cheering,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A3B7CA8),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi Explorer!',
                                  style: _AdventureText.heroTitle(context),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Let's learn something fun today!",
                                  style: _AdventureText.heroSubtitle(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatsSkeleton extends StatelessWidget {
  const _HeroStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroStatPill(
          icon: Icons.local_fire_department_rounded,
          iconColor: Color(0xFFFF6B35),
          value: '-',
          label: 'Day Streak',
        ),
        SizedBox(width: 8),
        _HeroStatPill(
          icon: Icons.star_rounded,
          iconColor: Color(0xFFFFC400),
          value: '-',
          label: 'Total Stars',
        ),
      ],
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 400;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 7 : 9, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: small ? 16 : 18),
              const SizedBox(height: 2),
              Text(value,
                  style: _AdventureText.statValue(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              Text(label,
                  style: _AdventureText.statLabel(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryQuestCard extends ConsumerWidget {
  const _MemoryQuestCard({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswerCountAsync = ref.watch(wrongAnswerCountProvider(childId));

    return wrongAnswerCountAsync.maybeWhen(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return _PressableScale(
          onTap: () => context.push('${AppRouter.memory}?childId=$childId'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF3A8), Color(0xFFFFC63B)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33FDBA2D),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const _TreasureChest(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bear\'s Memory Challenge',
                        style: _AdventureText.cardTitle(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count tricky questions to review!',
                        style: _AdventureText.cardBody(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: MediaQuery.of(context).size.width < 400 ? 38 : 46,
                  height: MediaQuery.of(context).size.width < 400 ? 38 : 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5D8F),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FF5D8F),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AdventureProgressCard extends StatelessWidget {
  const _AdventureProgressCard({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final progressValue = (progress / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Adventure Progress', style: _AdventureText.sectionTitle),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.width < 400 ? 56 : 66,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AdventureTrailPainter(progressValue),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      bottom: 8,
                      child: MascotWidget(
                        size: 44,
                        showBackground: false,
                        mood: MascotMood.idle,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CD867),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.forest_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.toDouble()),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '${value.round()}%',
                        style: _AdventureText.progressNumber(context),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "explored in Bear Forest!",
                      style: _AdventureText.smallBody(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdventureSubjectCard extends StatelessWidget {
  const _AdventureSubjectCard({required this.world, required this.onTap});

  final _SubjectWorld world;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return _PressableScale(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 126),
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: world.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: world.accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 58 : 68,
                  height: compact ? 58 : 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    world.icon,
                    color: world.accent,
                    size: compact ? 32 : 38,
                  ),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        world.title,
                        style: _AdventureText.subjectTitle(
                          context,
                          world.titleColor,
                          compact: compact,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        world.subtitle,
                        style: _AdventureText.subjectSubtitle(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: (world.progress / 100).clamp(0.0, 1.0),
                                ),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 10,
                                    color: world.accent,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.86,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${world.progress}%',
                            style: _AdventureText.progressChip(
                              context,
                              world.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  _SubjectIllustration(world: world),
                  const SizedBox(width: 10),
                ] else
                  const SizedBox(width: 8),
                _SubjectActionRail(world: world, compact: compact),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubjectActionRail extends StatelessWidget {
  const _SubjectActionRail({required this.world, required this.compact});

  final _SubjectWorld world;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 8 : 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: const Color(0xFFFFC400),
                size: compact ? 20 : 26,
              ),
              Text(
                world.totalStars.toString(),
                style: _AdventureText.starCount(context),
              ),
              const Text('Stars', style: AppTextStyles.tiny),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: compact ? 38 : 42,
          height: compact ? 38 : 42,
          decoration: BoxDecoration(
            color: world.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: compact ? 16 : 18,
          ),
        ),
      ],
    );
  }
}

class _SubjectIllustration extends StatelessWidget {
  const _SubjectIllustration({required this.world});

  final _SubjectWorld world;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 82,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 72,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Icon(world.illustrationIcon, color: world.accent, size: 62),
          ),
          Positioned(
            right: 3,
            top: 7,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectWorld {
  const _SubjectWorld({
    required this.subjectId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.illustrationIcon,
    required this.accent,
    required this.titleColor,
    required this.gradientColors,
    required this.progress,
    required this.completedLevels,
    required this.totalStars,
  });

  final String subjectId;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData illustrationIcon;
  final Color accent;
  final Color titleColor;
  final List<Color> gradientColors;
  final int progress;
  final int completedLevels;
  final int totalStars;

  factory _SubjectWorld.fromSubject({
    required String subjectId,
    required String fallbackName,
    required String fallbackSubtitle,
    required int progress,
    required int completedLevels,
    required int totalStars,
  }) {
    switch (subjectId) {
      case 'bi':
        return _SubjectWorld(
          subjectId: subjectId,
          title: 'Reading Island',
          subtitle: 'English Adventure',
          icon: Icons.menu_book_rounded,
          illustrationIcon: Icons.local_library_rounded,
          accent: const Color(0xFF3A8DFF),
          titleColor: const Color(0xFF17427E),
          gradientColors: const [Color(0xFFBDEBFF), Color(0xFFE9F8FF)],
          progress: progress,
          completedLevels: completedLevels,
          totalStars: totalStars,
        );
      case 'math':
        return _SubjectWorld(
          subjectId: subjectId,
          title: 'Number Mountain',
          subtitle: 'Math Adventure',
          icon: Icons.calculate_rounded,
          illustrationIcon: Icons.terrain_rounded,
          accent: const Color(0xFFA855F7),
          titleColor: const Color(0xFF402065),
          gradientColors: const [Color(0xFFE3C8FF), Color(0xFFF3E8FF)],
          progress: progress,
          completedLevels: completedLevels,
          totalStars: totalStars,
        );
      case 'bc':
        return _SubjectWorld(
          subjectId: subjectId,
          title: 'Panda Language Garden',
          subtitle: 'Mandarin',
          icon: Icons.translate_rounded,
          illustrationIcon: Icons.yard_rounded,
          accent: const Color(0xFF57B846),
          titleColor: const Color(0xFF1E5F1E),
          gradientColors: const [Color(0xFFD8F8BE), Color(0xFFF0FFE8)],
          progress: progress,
          completedLevels: completedLevels,
          totalStars: totalStars,
        );
      case 'bm':
        return _SubjectWorld(
          subjectId: subjectId,
          title: 'Story Jungle',
          subtitle: 'Bahasa Melayu',
          icon: Icons.edit_rounded,
          illustrationIcon: Icons.forest_rounded,
          accent: const Color(0xFFFF7A2F),
          titleColor: const Color(0xFF7A2C13),
          gradientColors: const [Color(0xFFFFDFAC), Color(0xFFFFF2D8)],
          progress: progress,
          completedLevels: completedLevels,
          totalStars: totalStars,
        );
      case 'sci':
        return _SubjectWorld(
          subjectId: subjectId,
          title: 'Discovery Grove',
          subtitle: 'Science Explorer',
          icon: Icons.science_rounded,
          illustrationIcon: Icons.eco_rounded,
          accent: const Color(0xFF16A085),
          titleColor: const Color(0xFF0D5F51),
          gradientColors: const [Color(0xFFC7F7E8), Color(0xFFE9FFF6)],
          progress: progress,
          completedLevels: completedLevels,
          totalStars: totalStars,
        );
      default:
        return _SubjectWorld(
          subjectId: subjectId,
          title: fallbackName,
          subtitle: fallbackSubtitle,
          icon: Icons.explore_rounded,
          illustrationIcon: Icons.auto_awesome_rounded,
          accent: const Color(0xFF8CD867),
          titleColor: const Color(0xFF275A24),
          gradientColors: const [Color(0xFFE5FFD8), Color(0xFFFFFFFF)],
          progress: progress,
          completedLevels: completedLevels,
          totalStars: totalStars,
        );
    }
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _TreasureChest extends StatelessWidget {
  const _TreasureChest();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final double size = MediaQuery.of(context).size.width < 400 ? 52 : 64;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.91,
                height: size * 0.78,
                decoration: BoxDecoration(
                  color: const Color(0xFFC98B58),
                  borderRadius: BorderRadius.circular(size * 0.19),
                  border: Border.all(color: const Color(0xFF8B4B25), width: 3),
                ),
              ),
              Positioned(
                top: size * 0.08,
                child: Container(
                  width: size * 0.87,
                  height: size * 0.37,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA733),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(size * 0.26),
                    ),
                    border: Border.all(
                      color: const Color(0xFFFFD84D),
                      width: 3,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: size * 0.21,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA78BFA),
                    borderRadius: BorderRadius.circular(size * 0.08),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.star_rounded, color: Colors.white),
                ),
              ),
              Positioned(left: 6, top: 6, child: _Sparkle(size: size * 0.17)),
              Positioned(
                right: 4,
                bottom: 10,
                child: _Sparkle(size: size * 0.15),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome_rounded, size: size, color: Colors.white);
  }
}

class _AdventureTrailPainter extends CustomPainter {
  _AdventureTrailPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final trailPaint = Paint()
      ..color = const Color(0xFFFFE1A3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = const Color(0xFF8CD867)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(26, size.height * 0.62)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.22,
        size.width * 0.58,
        size.height * 0.92,
        size.width - 32,
        size.height * 0.56,
      );

    canvas.drawPath(path, trailPaint);
    for (final metric in path.computeMetrics()) {
      final length = metric.length * progress.clamp(0.0, 1.0);
      canvas.drawPath(metric.extractPath(0, length), progressPaint);
    }

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.42, size.height * 0.54),
      5,
      dotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.61),
      5,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AdventureTrailPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _AdventureText {
  const _AdventureText._();

  static TextStyle logo(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontSize: (32 * _fontScale(context)).clamp(0, 36),
      height: 1,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF4B2416),
      letterSpacing: 0,
    );
  }

  static TextStyle heroTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      fontSize: (22 * _fontScale(context)).clamp(0.0, 23.0),
      height: 1.06,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF4B2416),
      letterSpacing: 0,
    );
  }

  static TextStyle heroSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontSize: (13 * _fontScale(context)).clamp(0.0, 14.0),
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF4A3A32),
    );
  }

  static TextStyle statValue(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: 20 * _fontScale(context),
      height: 1,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF4B2416),
    );
  }

  static TextStyle statLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      fontSize: 10 * _fontScale(context),
      fontWeight: FontWeight.w800,
      color: const Color(0xFF6F5B50),
    );
  }

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

  static TextStyle rewardLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      fontSize: 13 * _fontScale(context),
      fontWeight: FontWeight.w900,
      color: const Color(0xFF8B4B25),
    );
  }

  static TextStyle get sectionTitle => AppTextStyles.cardTitle.copyWith(
    color: const Color(0xFF4B2416),
    fontSize: 17,
  );

  static TextStyle progressNumber(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontSize: (26 * _fontScale(context)).clamp(0.0, 28.0),
      height: 0.95,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF57B846),
    );
  }

  static TextStyle smallBody(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      fontSize: 14 * _fontScale(context),
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF4A3A32),
    );
  }

  static TextStyle subjectTitle(
    BuildContext context,
    Color color, {
    bool compact = false,
  }) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: (compact ? 18 : 22) * _fontScale(context),
      height: 1.08,
      fontWeight: FontWeight.w900,
      color: color,
    );
  }

  static TextStyle subjectSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14 * _fontScale(context),
      fontWeight: FontWeight.w800,
      color: const Color(0xFF4A3A32),
    );
  }

  static TextStyle progressChip(BuildContext context, Color color) {
    return Theme.of(context).textTheme.labelMedium!.copyWith(
      fontSize: 13 * _fontScale(context),
      fontWeight: FontWeight.w900,
      color: color,
    );
  }

  static TextStyle starCount(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: 20 * _fontScale(context),
      height: 1,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF4B2416),
    );
  }
}
