import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/progress_bar_card.dart';
import '../../widgets/parent/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool expanded = false;
  String child = 'Aina';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Dashboard', style: AppTextStyles.screenTitle),
              ),
              TextButton.icon(
                onPressed: () => setState(() => expanded = !expanded),
                icon: const Icon(Icons.child_care),
                label: Text(child),
              ),
            ],
          ),
          if (expanded)
            _ChildPicker(
              onPick: (value) => setState(() {
                child = value;
                expanded = false;
              }),
            ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.star,
                  label: 'Available',
                  value: '120',
                  color: AppColors.star,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.menu_book,
                  label: 'Lessons',
                  value: '24',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  label: 'Streak',
                  value: '5d',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const ProgressBarCard(
            title: 'Daily Goal',
            subtitle: '2 more to go today',
            progress: .4,
            icon: Icons.flag_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Subject Progress', style: AppTextStyles.bodyBold),
          const SizedBox(height: AppSpacing.md),
          const _SubjectProgress(
            label: 'Bahasa Melayu',
            score: .62,
            color: AppColors.subjectBm,
          ),
          const _SubjectProgress(
            label: 'English',
            score: .48,
            color: AppColors.subjectEnglish,
          ),
          const _SubjectProgress(
            label: 'Mathematics',
            score: .74,
            color: AppColors.subjectMath,
          ),
          const _SubjectProgress(
            label: 'Science',
            score: .35,
            color: AppColors.subjectScience,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _RecentActivity(),
        ],
      ),
    );
  }
}

class _ChildPicker extends StatelessWidget {
  const _ChildPicker({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: ['Aina', 'Daniel']
            .map(
              (name) => ListTile(
                title: Text(name, style: AppTextStyles.bodyBold),
                subtitle: const Text('Age 7', style: AppTextStyles.small),
                onTap: () => onPick(name),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SubjectProgress extends StatelessWidget {
  const _SubjectProgress({
    required this.label,
    required this.score,
    required this.color,
  });
  final String label;
  final double score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.small)),
              Text('${(score * 100).round()}%', style: AppTextStyles.tiny),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: score,
            minHeight: AppSpacing.sm,
            color: color,
            backgroundColor: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Activity', style: AppTextStyles.bodyBold),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Completed Math Level 3       +2 stars',
            style: AppTextStyles.small,
          ),
          Text(
            'Claimed Extra Screen Time   -40 stars',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}
