import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const background = Color(0xFFF7F7F6);
  static const ink = Color(0xFF17181C);
  static const primary = Color(0xFF3654F4);

  // 스타일별 색상
  static const fairyTaleBg = Color(0xFFFDECC8);
  static const fairyTaleText = Color(0xFF8A5A0F);
  static const novelBg = Color(0xFFE6DEFA);
  static const novelText = Color(0xFF5A3A9E);
  static const cardBg = Color(0xFFD7F3EE);
  static const cardText = Color(0xFF0B6E64);
}

abstract final class AppTextStyles {
  static TextStyle display(double size) =>
      GoogleFonts.doHyeon(fontSize: size, color: AppColors.ink);
}

final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
          onSurface: AppColors.ink,
          brightness: Brightness.light,
        ),
        textTheme: Typography.blackMountainView.apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Color(0xFF8E8E93),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}
