import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/parent/stat_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool showPin = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text('Profile', style: AppTextStyles.screenTitle),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.r(AppRadius.xl),
                  boxShadow: AppShadows.card,
                ),
                child: const Column(
                  children: [
                    MascotWidget(size: 96),
                    SizedBox(height: AppSpacing.md),
                    Text('Aina', style: AppTextStyles.cardTitle),
                    Text('Tap to edit name', style: AppTextStyles.tiny),
                  ],
                ),
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
                      icon: Icons.local_fire_department,
                      label: 'Streak',
                      value: '5d',
                      color: AppColors.destructive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityCard(),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => setState(() => showPin = true),
                icon: const Icon(Icons.login),
                label: const Text('Parent Mode'),
              ),
            ],
          ),
          if (showPin)
            _PinModal(
              onClose: () => setState(() => showPin = false),
              onEnter: () => context.go(AppRouter.parentDashboard),
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
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
          Text('Completed BM Level 4     +3 stars', style: AppTextStyles.small),
          Text(
            'Daily goal met            +5 stars',
            style: AppTextStyles.small,
          ),
        ],
      ),
    );
  }
}

class _PinModal extends StatelessWidget {
  const _PinModal({required this.onClose, required this.onEnter});
  final VoidCallback onClose;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.xxl),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.r(AppRadius.xl),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Parent PIN', style: AppTextStyles.cardTitle),
              const SizedBox(height: AppSpacing.md),
              const TextField(
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: 'Enter PIN'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onEnter,
                      child: const Text('Enter'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClose,
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
