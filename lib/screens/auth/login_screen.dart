import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/mascot_widget.dart';
import '../../widgets/common/primary_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxPhoneWidth,
              ),
              child: Column(
                children: [
                  const MascotWidget(size: 116),
                  const SizedBox(height: AppSpacing.xxl),
                  const Text('BearTahan', style: AppTextStyles.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Fun lessons, quests, and star rewards for young learners.',
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Child name',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Parent PIN',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Start Learning',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.go(AppRouter.childHome),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(AppRouter.parentDashboard),
                    child: const Text('Parent Mode'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
