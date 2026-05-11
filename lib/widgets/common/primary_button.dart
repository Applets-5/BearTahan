import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          textStyle: AppTextStyles.button.copyWith(color: foregroundColor),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.r(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md, // Added horizontal padding for safety
          ),
        ),

        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AppSpacing.xl),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis, // Optional: adds '...' if still too long
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
