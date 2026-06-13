import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentId = ref.watch(parentIdProvider);
    final userProfileAsync = ref.watch(userProfileProvider(childId));
    final transactionsAsync = ref.watch(
      starTransactionsProvider((parentId: parentId, childId: childId)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Streak History', style: AppTextStyles.cardTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userProfileAsync.when(
        data: (profile) => transactionsAsync.when(
          data: (transactions) {
            final activeDates = transactions
                .where((tx) => tx.type == 'earn')
                .map(
                  (tx) => DateTime(
                    tx.timestamp.year,
                    tx.timestamp.month,
                    tx.timestamp.day,
                  ),
                )
                .toSet();

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _StreakHero(streakCount: profile.streakCount),
                const SizedBox(height: AppSpacing.xl),
                _StreakCalendar(activeDates: activeDates),
                const SizedBox(height: AppSpacing.xl),
                _StreakStats(streakCount: profile.streakCount),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading history: $err')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streakCount});

  final int streakCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.destructiveLight,
        borderRadius: AppRadius.r(AppRadius.xl),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: AppColors.destructive,
            size: 80,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$streakCount',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: 64,
              color: AppColors.destructive,
            ),
          ),
          const Text(
            'DAY STREAK!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.destructive,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              streakCount > 0
                  ? "You're doing great! Keep it up to earn more stars!"
                  : "Start a new streak today by completing a lesson!",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCalendar extends StatefulWidget {
  const _StreakCalendar({required this.activeDates});

  final Set<DateTime> activeDates;

  @override
  State<_StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<_StreakCalendar> {
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth = DateTime(
      _focusedDate.year,
      _focusedDate.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDate),
                style: AppTextStyles.bodyBold,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              'S',
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
            ].map((d) => Text(d, style: AppTextStyles.tiny)).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 0,
            ),
            itemCount: daysInMonth + startingWeekday,
            itemBuilder: (context, index) {
              if (index < startingWeekday) {
                return const SizedBox.shrink();
              }

              final day = index - startingWeekday + 1;
              final date = DateTime(_focusedDate.year, _focusedDate.month, day);
              final isActive = widget.activeDates.contains(date);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              if (!isActive) {
                return Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday ? AppColors.destructiveLight : null,
                    border: isToday
                        ? Border.all(color: AppColors.destructive, width: 2)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : null,
                      color: isToday
                          ? AppColors.destructive
                          : AppColors.foreground,
                    ),
                  ),
                );
              }

              // Check neighbors for continuous highlight
              final prevDate = date.subtract(const Duration(days: 1));
              final nextDate = date.add(const Duration(days: 1));

              final hasPrev =
                  widget.activeDates.contains(prevDate) &&
                  prevDate.month == date.month;

              final hasNext =
                  widget.activeDates.contains(nextDate) &&
                  nextDate.month == date.month;

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: 8,
                      bottom: 8,
                      left: hasPrev ? 0 : 6,
                      right: hasNext ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.destructive,
                      borderRadius: BorderRadius.horizontal(
                        left: hasPrev ? Radius.zero : const Radius.circular(20),
                        right: hasNext
                            ? Radius.zero
                            : const Radius.circular(20),
                      ),
                    ),
                  ),
                  Text(
                    '$day',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StreakStats extends StatelessWidget {
  const _StreakStats({required this.streakCount});

  final int streakCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            label: 'Current Streak',
            value: '$streakCount Days',
            icon: Icons.local_fire_department,
            color: AppColors.destructive,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(
          child: _StatBox(
            label: 'Consistency',
            value: 'High',
            icon: Icons.trending_up,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.r(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.bodyBold),
          Text(label, style: AppTextStyles.tiny),
        ],
      ),
    );
  }
}
