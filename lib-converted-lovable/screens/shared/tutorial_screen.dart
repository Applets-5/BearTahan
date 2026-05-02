import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/primary_button.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int page = 0;
  final controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: controller,
                  onPageChanged: (value) => setState(() => page = value),
                  children: const [
                    _TutorialPage(
                      icon: Icons.menu_book,
                      title: 'Learn by subject',
                      body:
                          'Pick Bahasa Melayu, English, Mandarin, Math, or Science.',
                    ),
                    _TutorialPage(
                      icon: Icons.star,
                      title: 'Earn stars',
                      body:
                          'Complete levels and goals to collect reward stars.',
                    ),
                    _TutorialPage(
                      icon: Icons.card_giftcard,
                      title: 'Claim rewards',
                      body: 'Spend stars on rewards approved by parents.',
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _Dot(active: i == page)),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: page == 2 ? 'Get Started' : 'Next',
                onPressed: () => page == 2
                    ? context.go(AppRouter.childHome)
                    : controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 88, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(body, style: AppTextStyles.body, textAlign: TextAlign.center),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? AppSpacing.xl : AppSpacing.sm,
      height: AppSpacing.sm,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: AppRadius.r(AppRadius.sm),
      ),
    );
  }
}
