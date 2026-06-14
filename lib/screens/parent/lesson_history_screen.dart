import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class LessonHistoryScreen extends ConsumerWidget {
  const LessonHistoryScreen({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attemptsAsync = ref.watch(attemptsProvider(childId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Lesson History', style: AppTextStyles.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: attemptsAsync.when(
        data: (attempts) {
          if (attempts.isEmpty) {
            return const Center(
              child: Text(
                'No lessons completed yet.',
                style: AppTextStyles.body,
              ),
            );
          }

          // Group attempts by day
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var attempt in attempts) {
            final timestamp = attempt['completedAt'] as Timestamp?;
            if (timestamp == null) continue;

            final date = timestamp.toDate();
            final dayKey = DateFormat('EEEE, dd MMM yyyy').format(date);
            grouped.putIfAbsent(dayKey, () => []).add(attempt);
          }

          final dayKeys = grouped.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: dayKeys.length,
            itemBuilder: (context, index) {
              final dayKey = dayKeys[index];
              final dayAttempts = grouped[dayKey]!;

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
                  ...dayAttempts.map(
                    (attempt) => _LessonLogTile(attempt: attempt),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LessonLogTile extends StatelessWidget {
  const _LessonLogTile({required this.attempt});
  final Map<String, dynamic> attempt;

  String _getSubjectName(String id) {
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

  Color _getSubjectColor(String id) {
    switch (id) {
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
      default:
        return Colors.grey;
    }
  }

  String _getDurationText(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
  }

  String _getLessonName(String levelId, String sessionType) {
    if (sessionType == 'bears_den') return "Bear's Den Challenge";
    if (sessionType == 'memory_challenge') return "Memory Challenge";
    if (sessionType == 'chapter_summary') return "Chapter Summary";
    if (sessionType == 'revision') return "Revision Session";

    // Format levelId like c1_l1 -> Chapter 1, Level 1
    final parts = levelId.split('_');
    if (parts.length >= 2) {
      final chapter = parts[0].replaceAll('c', 'Chapter ');
      final level = parts[1].replaceAll('l', 'Level ');
      return '$chapter, $level';
    }
    return levelId.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final subjectId = attempt['subjectId'] as String? ?? 'bm';
    final levelId = attempt['levelId'] as String? ?? '';
    final sessionType = attempt['sessionType'] as String? ?? 'regular';
    final timeInSeconds = attempt['timeInSeconds'] as int? ?? 0;
    final timestamp = attempt['completedAt'] as Timestamp?;
    final timeOfDay = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp.toDate())
        : '--:--';

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
              color: _getSubjectColor(subjectId),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLessonName(levelId, sessionType),
                  style: AppTextStyles.bodyBold,
                ),
                Text(
                  _getSubjectName(subjectId),
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
              Text(
                _getDurationText(timeInSeconds),
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
