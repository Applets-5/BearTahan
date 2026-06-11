import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

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
              'This review activity is planned but is not available yet.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: null,
              icon: Icon(Icons.schedule_rounded),
              label: Text('Coming Soon'),
            ),
          ],
        ),
      ),
    );
  }
}
