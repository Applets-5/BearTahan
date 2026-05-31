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
    this.onSecondary,
    this.secondaryLabel,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String description;
  final int cost;
  final String status;
  final VoidCallback? onPrimary;
  final String? primaryLabel;
  final VoidCallback? onSecondary;
  final String? secondaryLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final redeemed = status == 'redeemed';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: redeemed
            ? AppColors.muted
            : pending
            ? AppColors.secondaryLight
            : AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        border: Border.all(
          color: pending ? AppColors.secondary : AppColors.border,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.bodyBold)),
              if (status != 'available') _StatusPill(label: status),
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
                  child: const Icon(Icons.more_vert),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(description, style: AppTextStyles.small),
          const SizedBox(height: AppSpacing.sm),
          Text('Cost: $cost stars', style: AppTextStyles.tiny),
          if (onPrimary != null || onSecondary != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (onPrimary != null && primaryLabel != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onPrimary,
                      child: Text(primaryLabel!),
                    ),
                  ),
                if (onPrimary != null && onSecondary != null)
                  const SizedBox(width: AppSpacing.md),
                if (onSecondary != null && secondaryLabel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSecondary,
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
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Text(label, style: AppTextStyles.tiny),
    );
  }
}
