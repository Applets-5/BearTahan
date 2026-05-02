import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.destructiveLight,
                child: Icon(
                  Icons.wifi_off,
                  color: AppColors.destructive,
                  size: 40,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'You are offline',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'BearTahan needs an internet connection. Please reconnect to keep learning.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
