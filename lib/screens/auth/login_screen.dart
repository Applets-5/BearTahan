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
                  
                  // Login Fields
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Email or Child name',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      hintText: 'Password or Parent PIN',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Login Action
                  PrimaryButton(
                    label: 'Log In / Start Learning',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.go(AppRouter.childHome),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(AppRouter.parentDashboard),
                    child: const Text('Parent Mode (Bypass for now)'),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  
                  // Registration Section
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New to BearTahan?',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRouter.parentRegister),
                        child: const Text(
                          'Create Master Account',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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