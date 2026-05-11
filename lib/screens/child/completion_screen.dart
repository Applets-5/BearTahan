import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/primary_button.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({super.key, this.childId});

  final String? childId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActiveMascotWidget(childId: childId, size: 100),
              const SizedBox(height: AppSpacing.lg),
              const Icon(
                Icons.emoji_events_rounded,
                size: 56,
                color: AppColors.star,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Stage Clear!',
                style: AppTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const Text('Level 4: Everyday Words', style: AppTextStyles.small),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (_) =>
                      const Icon(Icons.star, size: 40, color: AppColors.star),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: AppRadius.r(AppRadius.lg),
                ),
                child: const Text(
                  '+3 stars added to your wallet!',
                  style: AppTextStyles.bodyBold,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Continue',
                onPressed: () => context.go(AppRouter.subjectFor(childId)),
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Try Again',
                backgroundColor: AppColors.muted,
                foregroundColor: AppColors.mutedText,
                onPressed: () => context.go(AppRouter.levelSessionFor(childId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
