import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class LevelSessionScreen extends StatefulWidget {
  const LevelSessionScreen({super.key});

  @override
  State<LevelSessionScreen> createState() => _LevelSessionScreenState();
}

class _LevelSessionScreenState extends State<LevelSessionScreen> {
  int? selected;
  final options = const ['Kucing', 'Rumah', 'Buku', 'Bola'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close, color: AppColors.mutedText),
                  ),
                  const Expanded(
                    child: LinearProgressIndicator(
                      value: .45,
                      minHeight: AppSpacing.md,
                      color: AppColors.subjectBm,
                      backgroundColor: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(Icons.star, color: AppColors.star),
                  const Text('3/10', style: AppTextStyles.bodyBold),
                ],
              ),
              const Spacer(),
              const Text(
                'What word matches this picture?',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 104,
                width: 104,
                decoration: BoxDecoration(
                  color: AppColors.imagePlaceholder,
                  borderRadius: AppRadius.r(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.image,
                  color: AppColors.mutedText,
                  size: 48,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ...List.generate(options.length, _option),
              const Spacer(),
              if (selected != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: selected == 1
                        ? AppColors.accentLight
                        : AppColors.destructiveLight,
                    borderRadius: AppRadius.r(AppRadius.lg),
                  ),
                  child: Text(
                    selected == 1
                        ? 'Correct! Well done!'
                        : 'Not quite! The answer is "Rumah".',
                    style: AppTextStyles.bodyBold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go(AppRouter.completion),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(int index) {
    final picked = selected == index;
    final correct = selected != null && index == 1;
    final color = correct
        ? AppColors.accentLight
        : picked
        ? AppColors.destructiveLight
        : AppColors.card;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: selected == null ? () => setState(() => selected = index) : null,
        borderRadius: AppRadius.r(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.r(AppRadius.lg),
            border: Border.all(
              color: correct
                  ? AppColors.accent
                  : picked
                  ? AppColors.destructive
                  : AppColors.border,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.muted,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(options[index], style: AppTextStyles.bodyBold),
            ],
          ),
        ),
      ),
    );
  }
}
