import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class SteampunkTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkWalnut,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.magicPurple,
          surface: AppColors.deepPurple,
          onPrimary: AppColors.darkWalnut,
          onSecondary: AppColors.parchment,
          onSurface: AppColors.parchment,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.brightGold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: AppColors.parchment,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.parchment,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.woodMid,
            foregroundColor: AppColors.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.gold, width: 1),
            ),
          ),
        ),
      );
}
