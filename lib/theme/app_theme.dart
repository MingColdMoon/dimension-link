import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 二次元卡通主题：圆角、柔阴影、糖果色强调。
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sakura,
      primary: AppColors.sakura,
      secondary: AppColors.starPurple,
      tertiary: AppColors.mint,
      surface: AppColors.card,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'ZCOOLKuaiLe',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'ZCOOLKuaiLe',
          fontSize: 22,
          color: AppColors.ink,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.ink, fontSize: 32, height: 1.2),
        headlineMedium: TextStyle(color: AppColors.ink, fontSize: 24, height: 1.3),
        titleLarge: TextStyle(color: AppColors.ink, fontSize: 20, height: 1.3),
        titleMedium: TextStyle(color: AppColors.ink, fontSize: 16, height: 1.4),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: AppColors.ink, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: AppColors.inkMuted, fontSize: 12, height: 1.4),
        labelLarge: TextStyle(color: AppColors.ink, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.sakura, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sakura,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontFamily: 'ZCOOLKuaiLe', fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sakuraSoft.withValues(alpha: 0.55),
        selectedColor: AppColors.sakura,
        labelStyle: const TextStyle(color: AppColors.ink, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.sakura,
        unselectedItemColor: AppColors.inkMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: AppColors.line,
    );
  }
}
