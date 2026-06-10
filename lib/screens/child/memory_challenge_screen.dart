import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/data_providers.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class MemoryChallengeScreen extends ConsumerWidget {
  const MemoryChallengeScreen({super.key, this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveChildId = childId ?? '';
    final profileAsync = ref.watch(userProfileProvider(effectiveChildId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Memory Challenge'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: profileAsync.when(
          data: (profile) {
            final progress = (profile.reviewQuestionCounter / 20).clamp(0.0, 1.0);
            return Column(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Review tricky questions',
                  style: AppTextStyles.title,
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Practise missed items and earn bonus stars after every 20 reviews.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                ClipRRect(
                  borderRadius: AppRadius.r(AppRadius.xl),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: AppSpacing.md,
                    color: AppColors.primary,
                    backgroundColor: AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${profile.reviewQuestionCounter}/20 reviews to next star',
                  style: AppTextStyles.small,
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Start Review',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.go(
                    AppRouter.levelSessionFor(
                      effectiveChildId,
                      isMemoryChallenge: true,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
