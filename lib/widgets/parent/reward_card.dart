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
    this.timestamp,
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
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final redeemed = status == 'redeemed';
    final approved = status == 'approved';
    final rejected = status == 'rejected';
    final available = status == 'available';
    final hasEnough = currentStars != null && currentStars! >= cost;

    // High-fidelity design colors - Precise Hex Codes
    const Color titleColor = Color(0xFF333333); // Dark Charcoal
    const Color subtitleColor = Color(0xFF666666); // Medium Slate Grey
    const Color goldenYellow = Color(0xFFFCC667); // Golden Yellow
    const Color brandColor = AppColors.primary;
    const Color greyTrack = Color(0xFFE6E6E6); // Unfilled track

    Color cardColor = Colors.white;
    Color borderColor = AppColors.border;
    Color progressValueColor = brandColor;
    Color progressTrackColor = greyTrack;
    Color? buttonColor;
    Color buttonTextColor = Colors.white;
    String finalPrimaryLabel = primaryLabel ?? 'Claim';
    Widget? buttonIcon;

    if (redeemed || approved) {
      cardColor = Colors.white;
      borderColor = brandColor;
      progressValueColor = AppColors.mutedText;
    } else if (rejected) {
      cardColor = Colors.white;
      borderColor = AppColors.destructive;
    } else if (pending) {
      cardColor = const Color(0xFFFFFCEB); // Yellow - Pending
      borderColor = goldenYellow;
      progressValueColor = brandColor;
    } else if (hasEnough && available) {
      cardColor = AppColors.primaryContainer; // Warm cream-tan container
      borderColor = brandColor;
      progressValueColor = brandColor;
      buttonColor = brandColor;
    } else {
      // White - Locked / In-Progress
      cardColor = const Color(0xFFFFFFFF);
      borderColor = AppColors.border;
      progressValueColor = brandColor;
      buttonColor = AppColors.muted;
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
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.0),
        border: showBorder
            ? Border.all(color: borderColor.withValues(alpha: 0.5), width: 1.0)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: titleColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        timestamp!,
                        style: AppTextStyles.tiny.copyWith(
                          color: subtitleColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: goldenYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$cost',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: titleColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  description,
                  style: AppTextStyles.small.copyWith(
                    color: subtitleColor,
                    height: 1.3,
                  ),
                ),
              ),
              if (status != 'available') ...[
                const SizedBox(width: 8),
                _StatusPill(
                  label: status.toUpperCase(),
                  color: pending
                      ? goldenYellow
                      : (rejected
                            ? AppColors.destructive
                            : (approved
                                  ? AppColors.accent
                                  : AppColors.mutedText)),
                  textColor: Colors.white,
                ),
              ],
            ],
          ),
          if (currentStars != null && !redeemed) ...[
            const SizedBox(height: 16),
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
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: progressTrackColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressValueColor),
              ),
            ),
          ],
          if (onPrimary != null || onSecondary != null) ...[
            const SizedBox(height: 20),
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
                        disabledBackgroundColor: buttonColor?.withValues(
                          alpha: 0.5,
                        ),
                        disabledForegroundColor: buttonTextColor.withValues(
                          alpha: 0.7,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (onPrimary != null && onSecondary != null)
                  const SizedBox(width: 12),
                if (onSecondary != null && secondaryLabel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: secondaryEnabled ? onSecondary : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
  const _StatusPill({required this.label, required this.color, this.textColor});

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Text(
        label,
        style: AppTextStyles.tiny.copyWith(
          color: textColor ?? AppColors.mutedText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
