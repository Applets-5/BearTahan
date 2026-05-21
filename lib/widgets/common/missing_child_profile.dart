import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

class MissingChildProfile extends StatelessWidget {
  const MissingChildProfile({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.child_care_rounded,
              size: 64,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.go(AppRouter.selectProfile),
              icon: const Icon(Icons.group_rounded),
              label: const Text('Select Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
