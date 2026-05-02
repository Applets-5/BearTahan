import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common/progress_bar_card.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('Daily Learning Goal', style: AppTextStyles.screenTitle),
          const Text(
            'Choose a lightweight target for each day.',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.lg),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Lessons')),
              ButtonSegment(value: 1, label: Text('Minutes')),
            ],
            selected: {selected},
            onSelectionChanged: (value) =>
                setState(() => selected = value.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.flag),
              hintText: 'Daily target',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const ProgressBarCard(
            title: 'Today',
            subtitle: '2 of 5 lessons completed',
            progress: .4,
            icon: Icons.today,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save),
            label: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }
}
