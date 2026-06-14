import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/outfit_quest.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/child/lucky_draw_dialog.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/missing_child_profile.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key, this.childId});

  final String? childId;

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> {
  bool _hasRefreshedProgress = false;

  Future<void> _refreshQuestProgress(String parentId, String childId) async {
    if (_hasRefreshedProgress || parentId.isEmpty || childId.isEmpty) return;
    _hasRefreshedProgress = true;

    try {
      await ref
          .read(firestoreServiceProvider)
          .evaluateAndUpdateQuestProgress(parentId, childId);
    } catch (e) {
      debugPrint('Failed to refresh quest progress: $e');
    }
  }

  Future<void> _setActiveOutfit(
    OutfitQuest quest,
    String parentId,
    String childId,
  ) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .setActiveOutfit(parentId, childId, quest.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${quest.name} is now your active outfit!')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to equip outfit: $e')));
    }
  }

  Future<void> _unlockOrEquipOutfit(
    OutfitQuest quest,
    OutfitQuestProgress progress,
    String parentId,
    String childId,
  ) async {
    final progressReached = progress.currentValue >= progress.targetValue;
    final canUnlock = quest.isStarter || progressReached;
    final unlocked = quest.isStarter || progress.isUnlocked;

    if (unlocked) {
      await _setActiveOutfit(quest, parentId, childId);
      return;
    }

    if (!canUnlock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the quest progress first.')),
      );
      return;
    }

    await _showLuckyDraw(quest: quest, parentId: parentId, childId: childId);
  }

  Future<void> _showLuckyDraw({
    required OutfitQuest quest,
    required String parentId,
    required String childId,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return LuckyDrawDialog(
          quest: quest,

          // This will run when user clicks DONE
          onEquipNow: () async {
            Navigator.of(dialogContext).pop();

            try {
              await ref
                  .read(firestoreServiceProvider)
                  .unlockQuestOutfit(parentId, childId, quest.id);

              if (!mounted) return;

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${quest.name} unlocked!')),
              );
            } catch (e) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to unlock outfit: $e')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _showQuestDetails({
    required OutfitQuest quest,
    required OutfitQuestProgress progress,
    required bool unlocked,
    required bool canUnlock,
    required bool active,
    required String parentId,
    required String childId,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _QuestDetailsDialog(
          quest: quest,
          progress: progress,
          unlocked: unlocked,
          canUnlock: canUnlock,
          active: active,
          onEquip: (unlocked || canUnlock) && !active
              ? () {
                  Navigator.of(dialogContext).pop();
                  _unlockOrEquipOutfit(quest, progress, parentId, childId);
                }
              : null,
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeChildId = GoRouterState.of(
      context,
    ).uri.queryParameters['childId'];

    final providerChildId = ref.watch(childIdProvider);

    final childId = routeChildId?.isNotEmpty == true
        ? routeChildId!
        : widget.childId?.isNotEmpty == true
        ? widget.childId!
        : providerChildId ?? '';

    if (childId.isEmpty) {
      return const MissingChildProfile(
        message: 'Select a child profile to view quests.',
      );
    }

    final parentId = ref.watch(parentIdProvider);
    final questsAsync = ref.watch(outfitQuestsProvider);
    final progressAsync = ref.watch(
      questProgressProvider((parentId: parentId, childId: childId)),
    );
    final profileAsync = ref.watch(userProfileProvider(childId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshQuestProgress(parentId, childId);
    });

    return SafeArea(
      child: questsAsync.when(
        data: (quests) {
          final progressMap = progressAsync.value ?? const {};
          final activeOutfitId =
              profileAsync.value?.activeMascotOutfit ?? 'scholar_bear';

          final unlockedCount = quests.where((quest) {
            final progress = progressMap[quest.id];
            return quest.isStarter || progress?.isUnlocked == true;
          }).length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final horizontalPadding = screenWidth < 380
                  ? AppSpacing.md
                  : AppSpacing.lg;

              final contentWidth = screenWidth > 900
                  ? 900.0
                  : screenWidth - (horizontalPadding * 2);

              final crossAxisCount = contentWidth >= 760 ? 3 : 2;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.xl,
                  horizontalPadding,
                  AppSpacing.xxl + AppSpacing.bottomNavHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _QuestHeader(
                          unlockedCount: unlockedCount,
                          totalCount: quests.length,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                mainAxisExtent: 315,
                              ),
                          itemCount: quests.length,
                          itemBuilder: (context, index) {
                            final quest = quests[index];

                            final progress =
                                progressMap[quest.id] ??
                                OutfitQuestProgress(
                                  outfitId: quest.id,
                                  currentValue: quest.isStarter
                                      ? quest.target
                                      : 0,
                                  targetValue: quest.target,
                                  isUnlocked: quest.isStarter,
                                );

                            final progressReached =
                                progress.currentValue >= progress.targetValue;
                            final canUnlock =
                                quest.isStarter || progressReached;
                            final unlocked =
                                quest.isStarter || progress.isUnlocked;
                            final active =
                                activeOutfitId == quest.id && unlocked;

                            return _QuestOutfitCard(
                              quest: quest,
                              progress: progress,
                              unlocked: unlocked,
                              canUnlock: canUnlock,
                              active: active,
                              onOpenDetails: () => _showQuestDetails(
                                quest: quest,
                                progress: progress,
                                unlocked: unlocked,
                                canUnlock: canUnlock,
                                active: active,
                                parentId: parentId,
                                childId: childId,
                              ),
                              onEquip: (unlocked || canUnlock) && !active
                                  ? () => _unlockOrEquipOutfit(
                                      quest,
                                      progress,
                                      parentId,
                                      childId,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Unable to load quests: $error')),
      ),
    );
  }
}

class _QuestHeader extends StatelessWidget {
  const _QuestHeader({required this.unlockedCount, required this.totalCount});

  final int unlockedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progressValue = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Quests & Outfits',
                style: AppTextStyles.screenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '$unlockedCount/$totalCount outfits unlocked',
          style: AppTextStyles.small.copyWith(
            color: AppColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: AppRadius.r(AppRadius.xxl),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 8,
            color: AppColors.primary,
            backgroundColor: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

class _QuestOutfitCard extends StatelessWidget {
  const _QuestOutfitCard({
    required this.quest,
    required this.progress,
    required this.unlocked,
    required this.canUnlock,
    required this.active,
    required this.onOpenDetails,
    required this.onEquip,
  });

  final OutfitQuest quest;
  final OutfitQuestProgress progress;
  final bool unlocked;
  final bool canUnlock;
  final bool active;
  final VoidCallback onOpenDetails;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final buttonLabel = unlocked ? 'Equip' : '🎁 Unlock';

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.r(AppRadius.xl),
      child: InkWell(
        onTap: onOpenDetails,
        borderRadius: AppRadius.r(AppRadius.xl),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primaryLight
                    : unlocked || canUnlock
                    ? AppColors.card
                    : AppColors.muted,
                borderRadius: AppRadius.r(AppRadius.xl),
                border: Border.all(
                  color: active ? AppColors.primaryLight : AppColors.border,
                  width: 1,
                ),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _OutfitImage(quest: quest, locked: !unlocked),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    quest.name,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: unlocked || canUnlock
                          ? AppColors.foreground
                          : AppColors.mutedText,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _QuestTag(text: quest.description),
                  const SizedBox(height: AppSpacing.sm),
                  if (!quest.isStarter) ...[
                    _QuestProgressSection(progress: progress),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (active)
                    const _SmallStatusButton(
                      label: '✅ Active',
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                    )
                  else if (unlocked || canUnlock)
                    _SmallStatusButton(
                      label: buttonLabel,
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      onTap: onEquip,
                    )
                  else
                    Text(
                      '🔒 Locked',
                      style: AppTextStyles.tiny.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (active)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuestDetailsDialog extends StatelessWidget {
  const _QuestDetailsDialog({
    required this.quest,
    required this.progress,
    required this.unlocked,
    required this.canUnlock,
    required this.active,
    required this.onEquip,
    required this.onClose,
  });

  final OutfitQuest quest;
  final OutfitQuestProgress progress;
  final bool unlocked;
  final bool canUnlock;
  final bool active;
  final VoidCallback? onEquip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final actionLabel = unlocked ? 'Equip' : '🎁 Unlock';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.r(AppRadius.xl),
          boxShadow: AppShadows.strong,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.mutedText,
                    size: 22,
                  ),
                ),
              ),
              _OutfitImage(quest: quest, locked: !unlocked),
              const SizedBox(height: AppSpacing.md),
              Text(
                quest.name,
                style: AppTextStyles.bodyBold.copyWith(
                  fontSize: 18,
                  color: AppColors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _QuestTag(text: quest.description),
              if (!quest.isStarter) ...[
                const SizedBox(height: AppSpacing.md),
                _QuestProgressSection(progress: progress),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                _detailMessage(quest),
                style: AppTextStyles.small.copyWith(color: AppColors.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: active
                        ? const _SmallStatusButton(
                            label: '✅ Active',
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                          )
                        : unlocked || canUnlock
                        ? _SmallStatusButton(
                            label: actionLabel,
                            backgroundColor: AppColors.primary,
                            textColor: Colors.white,
                            onTap: onEquip,
                          )
                        : const _SmallStatusButton(
                            label: '🔒 Locked',
                            backgroundColor: AppColors.muted,
                            textColor: AppColors.mutedText,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SmallStatusButton(
                      label: 'Close',
                      backgroundColor: AppColors.card,
                      textColor: AppColors.mutedText,
                      borderColor: AppColors.border,
                      onTap: onClose,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _detailMessage(OutfitQuest quest) {
    switch (quest.id) {
      case 'scholar_bear':
        return 'This is your starter outfit.';
      case 'chef_bear':
        return 'Complete 5 BM lessons to unlock this outfit.';
      case 'astro_bear':
        return 'Score 100% on 3 Maths quizzes to unlock this outfit.';
      case 'pirate_bear':
        return 'Complete 10 English lessons to find the treasure!';
      case 'super_bear':
        return 'Earn 500 total stars to unlock this outfit.';
      case 'explorer_bear':
        return 'Complete all Science topics to unlock this outfit.';
      default:
        return quest.description;
    }
  }
}

class _OutfitImage extends StatelessWidget {
  const _OutfitImage({required this.quest, required this.locked});

  final OutfitQuest quest;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final imagePath = MascotWidget.outfitImages[quest.id] ?? quest.imagePath;

    final image = Image.asset(
      imagePath,
      height: 105,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.pets_rounded, color: AppColors.mutedText, size: 72),
    );

    final biggerImage = Transform.translate(
      offset: const Offset(0, -6),
      child: Transform.scale(scale: 1.35, child: image),
    );

    return SizedBox(
      height: 115,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          locked
              ? Opacity(
                  opacity: 0.75,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      AppColors.mutedText.withValues(alpha: 0.55),
                      BlendMode.srcIn,
                    ),
                    child: biggerImage,
                  ),
                )
              : biggerImage,
          if (locked)
            Positioned(
              bottom: 0,
              child: Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.card,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.mutedText,
                  size: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestTag extends StatelessWidget {
  const _QuestTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: AppRadius.r(AppRadius.xxl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestProgressSection extends StatelessWidget {
  const _QuestProgressSection({required this.progress});

  final OutfitQuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final targetValue = progress.targetValue <= 0 ? 1 : progress.targetValue;
    final currentValue = progress.currentValue.clamp(0, targetValue).toInt();
    final progressValue = (currentValue / targetValue).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Progress',
                style: AppTextStyles.tiny.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$currentValue / $targetValue',
              style: AppTextStyles.tiny.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.r(AppRadius.xxl),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            color: AppColors.primary,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}

class _SmallStatusButton extends StatelessWidget {
  const _SmallStatusButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasShadow = onTap != null || label.contains('Active');
    final Color shadowColor = hasShadow
        ? Color.lerp(backgroundColor, Colors.black, 0.25)!
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 4, right: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor!),
            ),
            child: Text(
              label,
              style: AppTextStyles.tiny.copyWith(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
