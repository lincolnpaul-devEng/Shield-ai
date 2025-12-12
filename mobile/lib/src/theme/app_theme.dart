import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
        secondary: AppColors.accent,
        error: AppColors.error,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnSurface,
        primaryContainer: AppColors.lightGreen,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        color: AppColors.lightGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.lightOnSurface),
        titleSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.lightOnSurface),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.lightOnSurface),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark).copyWith(
        secondary: AppColors.accent,
        error: AppColors.error,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        color: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkOnSurface),
        titleSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkOnSurface),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.darkOnSurface),
      ),
    );
  }
}
