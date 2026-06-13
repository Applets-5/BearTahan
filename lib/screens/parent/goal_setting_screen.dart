import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/parent/daily_goal_ring_card.dart';

class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  final _targetController = TextEditingController();
  String _goalType = 'lessons';
  String? _hydratedChildId;
  bool _isSaving = false;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _saveGoal(String childId) async {
    final target = int.tryParse(_targetController.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a positive daily target')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final parentId = ref.read(parentIdProvider);
      await ref
          .read(firestoreServiceProvider)
          .updateDailyGoal(parentId, childId, type: _goalType, target: target);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Daily goal saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving goal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);
    final selectedChildId = ref.watch(childIdProvider);

    return SafeArea(
      child: childrenAsync.when(
        data: (children) {
          if (children.isEmpty) {
            return const Center(
              child: Text('Add a child profile before setting goals.'),
            );
          }

          final effectiveChildId = selectedChildId ?? children.first.uid;
          final selectedChild = children.firstWhere(
            (child) => child.uid == effectiveChildId,
            orElse: () => children.first,
          );
          final profileAsync = ref.watch(
            userProfileProvider(selectedChild.uid),
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text(
                'Daily Learning Quest',
                style: AppTextStyles.screenTitle,
              ),
              const Text(
                'Set a daily mission to help your child stay consistent.',
                style: AppTextStyles.small,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: selectedChild.uid,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.child_care),
                  labelText: 'Child',
                ),
                items: children
                    .map(
                      (child) => DropdownMenuItem(
                        value: child.uid,
                        child: Text(child.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  ref.read(childIdProvider.notifier).update(value);
                  setState(() => _hydratedChildId = null);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              profileAsync.when(
                data: (profile) {
                  final goal = profile.dailyGoal;
                  if (_hydratedChildId != profile.uid) {
                    _hydratedChildId = profile.uid;
                    _goalType = goal?.type == 'minutes' ? 'minutes' : 'lessons';
                    _targetController.text = goal?.target.toString() ?? '';
                  }

                  final progress = goal == null || goal.target <= 0
                      ? 0.0
                      : (goal.todayProgress / goal.target)
                            .clamp(0.0, 1.0)
                            .toDouble();
                  final unit = goal?.unitLabel ?? _goalType;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'lessons',
                            label: Text('Lessons'),
                            icon: Icon(Icons.menu_book),
                          ),
                          ButtonSegment(
                            value: 'minutes',
                            label: Text('Minutes'),
                            icon: Icon(Icons.timer),
                          ),
                        ],
                        selected: {_goalType},
                        onSelectionChanged: (value) =>
                            setState(() => _goalType = value.first),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.flag),
                          hintText: _goalType == 'minutes'
                              ? 'Daily target minutes'
                              : 'Daily target lessons',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DailyGoalRingCard(
                        title: 'Mission Progress',
                        subtitle: goal == null || !goal.isValid
                            ? "Set a quest for ${profile.name} today!"
                            : "${profile.name} has finished ${goal.todayProgress}/${goal.target} $unit so far.",
                        progress: progress,
                        target: goal?.target ?? 0,
                        current: goal?.todayProgress ?? 0,
                        unit: unit,
                        icon: Icons.today,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveGoal(profile.uid),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Quest'),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error loading child goal: $e'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading children: $e')),
      ),
    );
  }
}
