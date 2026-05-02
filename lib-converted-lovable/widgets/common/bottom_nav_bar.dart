import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../theme/app_theme.dart';

class BottomNavScaffold extends StatelessWidget {
  const BottomNavScaffold({
    super.key,
    required this.child,
    required this.isParent,
  });

  final Widget child;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(isParent: isParent),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key, required this.isParent});

  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final items = isParent ? _parentItems : _kidItems;
    final path = GoRouterState.of(context).uri.path;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final active = path == item.route;
              return _NavButton(
                item: item,
                active: active,
                onTap: () => context.go(item.route),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.navInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.r(AppRadius.md),
      child: SizedBox(
        width: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: color, size: AppSpacing.xxl),
            const SizedBox(height: AppSpacing.xs),
            Text(item.label, style: AppTextStyles.nav.copyWith(color: color)),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: 16,
              height: active ? AppSpacing.xs : 0,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.r(AppRadius.sm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label, this.route);
  final IconData icon;
  final String label;
  final String route;
}

const _kidItems = [
  _NavItem(Icons.home_rounded, 'Home', AppRouter.childHome),
  _NavItem(Icons.pets_rounded, 'Quests', AppRouter.quests),
  _NavItem(Icons.emoji_events_rounded, 'Rewards', AppRouter.rewards),
  _NavItem(Icons.person_rounded, 'Profile', AppRouter.profile),
];

const _parentItems = [
  _NavItem(Icons.bar_chart_rounded, 'Dashboard', AppRouter.parentDashboard),
  _NavItem(Icons.card_giftcard_rounded, 'Rewards', AppRouter.parentRewards),
  _NavItem(
    Icons.notifications_rounded,
    'Alerts',
    AppRouter.parentNotifications,
  ),
  _NavItem(Icons.settings_rounded, 'Settings', AppRouter.parentSettings),
];
