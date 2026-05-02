import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class MascotWidget extends StatelessWidget {
  const MascotWidget({
    super.key,
    this.size = 72,
    this.message,
    this.locked = false,
  });

  final double size;
  final String? message;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final mascot = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.imagePlaceholder,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Icon(
        locked ? Icons.lock : Icons.image,
        color: AppColors.mutedText,
        size: size * .45,
      ),
    );
    if (message == null) return mascot;
    return Row(
      children: [
        mascot,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.mascotBubble,
              borderRadius: AppRadius.r(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: Text(message!, style: AppTextStyles.bodyBold),
          ),
        ),
      ],
    );
  }
}
