import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/star_transaction.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class StarHistoryScreen extends ConsumerWidget {
  const StarHistoryScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(parentIdProvider);
    final transactionsAsync = ref.watch(
      starTransactionsProvider((parentId: parentId, childId: childId)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Star History', style: AppTextStyles.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: transactionsAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No history yet. Start learning to earn stars!',
                style: AppTextStyles.body,
              ),
            );
          }

          // Group transactions by day
          final Map<String, List<StarTransaction>> grouped = {};
          for (var tx in transactions) {
            final dayKey = DateFormat('EEEE, dd MMM yyyy').format(tx.timestamp);
            grouped.putIfAbsent(dayKey, () => []).add(tx);
          }

          final dayKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: dayKeys.length,
            itemBuilder: (context, index) {
              final dayKey = dayKeys[index];
              final dayTransactions = grouped[dayKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      dayKey,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.mutedText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...dayTransactions.map((tx) => _StarLogTile(transaction: tx)),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _StarLogTile extends StatelessWidget {
  const _StarLogTile({required this.transaction});
  final StarTransaction transaction;

  String _getFormattedDescription() {
    final desc = transaction.description;
    final levelId = transaction.levelId;

    if (levelId != null && levelId.isNotEmpty) {
      if (levelId == 'bears_den') return "Bear's Den Challenge";
      if (levelId == 'memory_challenge') return "Memory Challenge";
      if (levelId == 'chapter_summary') return "Chapter Summary";
      if (levelId == 'revision') return "Revision Session";

      // Format levelId like c1_l1 -> Chapter 1, Level 1
      final parts = levelId.split('_');
      if (parts.length >= 2) {
        final chapter = parts[0].replaceAll('c', 'Chapter ');
        final level = parts[1].replaceAll('l', 'Level ');
        return '$chapter, $level';
      }
    }

    // Fallback for descriptions that contain (C1_L1) style text
    if (desc.contains('(') && desc.contains(')')) {
      final startIndex = desc.indexOf('(') + 1;
      final endIndex = desc.indexOf(')');
      final idPart = desc.substring(startIndex, endIndex).toLowerCase();
      final parts = idPart.split('_');
      if (parts.length >= 2) {
        final chapter = parts[0].replaceAll('c', 'Chapter ');
        final level = parts[1].replaceAll('l', 'Level ');
        return '$chapter, $level';
      }
    }

    return desc;
  }

  String _getSubjectName(String? id) {
    if (id == null) return '';
    switch (id) {
      case 'bm':
        return 'Bahasa Melayu';
      case 'bi':
        return 'English';
      case 'bc':
        return 'Mandarin';
      case 'math':
        return 'Mathematics';
      case 'sci':
        return 'Science';
      default:
        return id.toUpperCase();
    }
  }

  Color _getIndicatorColor() {
    if (transaction.type == 'spend') return Colors.grey;
    if (transaction.subjectId != null) {
      switch (transaction.subjectId) {
        case 'bm':
          return AppColors.subjectBm;
        case 'bi':
          return AppColors.subjectEnglish;
        case 'bc':
          return AppColors.subjectMandarin;
        case 'math':
          return AppColors.subjectMath;
        case 'sci':
          return AppColors.subjectScience;
      }
    }
    return AppColors.star;
  }

  @override
  Widget build(BuildContext context) {
    final isEarn = transaction.type == 'earn';
    final timeOfDay = DateFormat('hh:mm a').format(transaction.timestamp);
    final subjectName = _getSubjectName(transaction.subjectId);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getIndicatorColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getFormattedDescription(), style: AppTextStyles.bodyBold),
                if (subjectName.isNotEmpty)
                  Text(
                    subjectName,
                    style: AppTextStyles.tiny.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEarn
                        ? '+${transaction.amount}'
                        : '-${transaction.amount.abs()}',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isEarn ? AppColors.accent : AppColors.destructive,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star, size: 12, color: AppColors.star),
                ],
              ),
              Text(
                timeOfDay,
                style: AppTextStyles.tiny.copyWith(color: AppColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
