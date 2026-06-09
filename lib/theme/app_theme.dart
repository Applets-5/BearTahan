import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFFFFBF0);
  static const foreground = Color(0xFF22263A);
  static const card = Color(0xFFFFFFFF);
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0x1A7C3AED);
  static const secondary = Color(0xFFFFCC33);
  static const secondaryLight = Color(0x33FFCC33);
  static const secondaryText = Color(0xFF523214);
  static const muted = Color(0xFFF0F2F6);
  static const mutedText = Color(0xFF737986);
  static const accent = Color(0xFF22C78F);
  static const accentLight = Color(0x2622C78F);
  static const destructive = Color(0xFFE93F3F);
  static const destructiveLight = Color(0x1AE93F3F);
  static const border = Color(0xFFE3E7EF);
  static const star = Color(0xFFFFC400);
  static const navInactive = Color(0xFFA0A5B1);
  static const mascotBubble = Color(0xFFE5F7FF);
  static const subjectBm = Color(0xFF2C95EA);
  static const subjectEnglish = Color(0xFFE63375);
  static const subjectMandarin = Color(0xFFF37B21);
  static const subjectMath = Color(0xFF7C3AED);
  static const subjectScience = Color(0xFF22C78F);
  static const imagePlaceholder = Color(0xFFE5E7EB);
}

class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
  static const bottomNavHeight = 78.0;
  static const maxPhoneWidth = 430.0;
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 32.0;
  static BorderRadius r(double value) => BorderRadius.circular(value);
}

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.foreground,
  );
  static const screenTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.foreground,
  );
  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: AppColors.foreground,
  );
  static const bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.foreground,
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
  );
  static const small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedText,
  );
  static const tiny = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    color: AppColors.mutedText,
  );
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );
  static const nav = TextStyle(fontSize: 11, fontWeight: FontWeight.w900);
  static const whiteTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );
  static const whiteBodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );
  static const whiteBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  static const whiteSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Colors.white70,
  );
}

class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x1422263A), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A22263A), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const strong = [
    BoxShadow(color: Color(0x1F22263A), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.destructive,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.foreground,
        centerTitle: false,
        titleTextStyle: AppTextStyles.screenTitle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.r(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.r(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
