import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class RewardCard extends StatelessWidget {
  const RewardCard({
    super.key,
    required this.title,
    required this.description,
    required this.cost,
    this.status = 'available',
    this.onPrimary,
    this.primaryLabel,
    this.primaryEnabled = true,
    this.onSecondary,
    this.secondaryLabel,
    this.secondaryEnabled = true,
    this.onEdit,
    this.onDelete,
    this.currentStars,
    this.showBorder = true,
    this.childName,
  });

  final String title;
  final String description;
  final int cost;
  final String status;
  final VoidCallback? onPrimary;
  final String? primaryLabel;
  final bool primaryEnabled;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;
  final bool secondaryEnabled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int? currentStars;
  final bool showBorder;
  final String? childName;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final redeemed = status == 'redeemed';
    final available = status == 'available';
    final hasEnough = currentStars != null && currentStars! >= cost;

    // High-fidelity design colors - Precise Hex Codes
    const Color titleColor = Color(0xFF333333); // Dark Charcoal
    const Color subtitleColor = Color(0xFF666666); // Medium Slate Grey
    const Color tealGreen = Color(0xFF20B2AA); // Teal Green
    const Color goldenYellow = Color(0xFFFCC667); // Golden Yellow
    const Color vibrantPurple = Color(0xFF7F33DE); // Vibrant Purple (Button)
    const Color trackPurple = Color(0xFF8A2BE2); // Vibrant Purple (Progress)
    const Color thistlePurple = Color(0xFFD8BFD8); // Pale Lavender
    const Color greyTrack = Color(0xFFE6E6E6); // Unfilled track

    Color cardColor = Colors.white;
    Color borderColor = AppColors.border;
    Color progressValueColor = tealGreen;
    Color progressTrackColor = greyTrack;
    Color? buttonColor;
    Color? buttonTextColor = Colors.white;
    String finalPrimaryLabel = primaryLabel ?? 'Claim';
    Widget? buttonIcon;

    if (redeemed) {
      cardColor = AppColors.muted;
      progressValueColor = AppColors.mutedText;
    } else if (pending) {
      cardColor = const Color(0xFFFFFCEB); // Yellow - Pending
      borderColor = goldenYellow;
      progressValueColor = tealGreen;
    } else if (hasEnough && available) {
      cardColor = const Color(0xFFEBFAF3); // Green - Available
      borderColor = tealGreen;
      progressValueColor = tealGreen;
      buttonColor = vibrantPurple;
    } else {
      // White - Locked / In-Progress
      cardColor = const Color(0xFFFFFFFF);
      borderColor = AppColors.border;
      progressValueColor = trackPurple;
      buttonColor = thistlePurple;
      buttonTextColor = titleColor.withValues(alpha: 0.7);

      if (currentStars != null) {
        final remaining = cost - currentStars!;
        finalPrimaryLabel = 'Need $remaining more';
        buttonIcon = const Icon(Icons.lock, size: 16);
      }
    }

    // Progress calculation
    double progress = 0;
    if (currentStars != null && cost > 0) {
      progress = (currentStars! / cost).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.all(24.0), // Generous padding
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.0), // Highly rounded
        border: showBorder ? Border.all(color: borderColor, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(color: titleColor),
                    ),
                    if (childName != null)
                      Text(
                        'For: $childName',
                        style: AppTextStyles.tiny.copyWith(color: tealGreen, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              if (status != 'available')
                _StatusPill(
                  label: status,
                  color: pending ? goldenYellow : AppColors.muted,
                  textColor: pending ? Colors.white : null,
                ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit' && onEdit != null) onEdit!();
                    if (value == 'delete' && onDelete != null) onDelete!();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  child: const Icon(Icons.more_vert, color: subtitleColor),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: AppTextStyles.small.copyWith(color: subtitleColor),
          ),
          const SizedBox(height: AppSpacing.md),
          if (currentStars == null) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: goldenYellow),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '$cost stars required',
                  style: AppTextStyles.bodyBold.copyWith(color: titleColor),
                ),
              ],
            ),
          ],
          if (currentStars != null && !redeemed) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${currentStars!}/$cost',
                      style: AppTextStyles.tiny.copyWith(
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 12, color: goldenYellow),
                  ],
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTextStyles.tiny.copyWith(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12, // Slightly thicker for a playful feel
                backgroundColor: progressTrackColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressValueColor),
              ),
            ),
          ],
          if (onPrimary != null || onSecondary != null) ...[
            const SizedBox(height: 24.0),
            Row(
              children: [
                if (onPrimary != null && primaryLabel != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: primaryEnabled && (hasEnough || !available)
                          ? onPrimary
                          : null,
                      icon: buttonIcon,
                      label: Text(finalPrimaryLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        disabledBackgroundColor: buttonColor,
                        disabledForegroundColor: buttonTextColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (onPrimary != null && onSecondary != null)
                  const SizedBox(width: AppSpacing.md),
                if (onSecondary != null && secondaryLabel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: secondaryEnabled ? onSecondary : null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(secondaryLabel!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.color, this.textColor});
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.muted,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Text(label, style: AppTextStyles.tiny.copyWith(color: textColor)),
    );
  }
}
