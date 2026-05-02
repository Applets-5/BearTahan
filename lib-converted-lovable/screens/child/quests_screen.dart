import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> {
  int selected = 0;
  static const mascots = [
    ('Scholar Bear', 'Starter outfit', true),
    ('Chef Bear', 'Complete 5 BM lessons', true),
    ('Astro Bear', 'Score 100% in 3 Math quizzes', false),
    ('Pirate Bear', 'Complete 10 English lessons', false),
    ('Super Bear', 'Earn 500 stars total', false),
    ('Explorer Bear', 'Complete all Science topics', false),
  ];

  @override
  Widget build(BuildContext context) {
    final unlocked = mascots.where((m) => m.$3).length;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quests & Outfits',
                    style: AppTextStyles.screenTitle,
                  ),
                  Text(
                    '$unlocked/${mascots.length} outfits unlocked',
                    style: AppTextStyles.small,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LinearProgressIndicator(
                    value: unlocked / mascots.length,
                    minHeight: AppSpacing.sm,
                    color: AppColors.primary,
                    backgroundColor: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: .82,
              ),
              itemCount: mascots.length,
              itemBuilder: (context, i) => _MascotCard(
                data: mascots[i],
                active: selected == i,
                onTap: mascots[i].$3
                    ? () => setState(() => selected = i)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotCard extends StatelessWidget {
  const _MascotCard({
    required this.data,
    required this.active,
    required this.onTap,
  });
  final (String, String, bool) data;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.r(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryLight
              : data.$3
              ? AppColors.card
              : AppColors.muted,
          borderRadius: AppRadius.r(AppRadius.lg),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            MascotWidget(size: 72, locked: !data.$3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.$1,
              style: AppTextStyles.bodyBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              data.$2,
              style: AppTextStyles.tiny,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(
              data.$3
                  ? active
                        ? 'Active'
                        : 'Set Active'
                  : 'Locked',
              style: AppTextStyles.tiny.copyWith(
                color: active ? AppColors.primary : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
