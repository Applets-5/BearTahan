import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class MemoryChallengeScreen extends StatelessWidget {
  const MemoryChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: Column(
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
            const LinearProgressIndicator(
              value: .45,
              minHeight: AppSpacing.md,
              color: AppColors.primary,
              backgroundColor: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('9/20 reviews to next star', style: AppTextStyles.small),
            const Spacer(),
            PrimaryButton(
              label: 'Start Review',
              icon: Icons.play_arrow_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
