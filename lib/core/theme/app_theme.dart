import 'package:flutter/material.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          secondary: AppColors.secondary,
          tertiary: AppColors.tertiary,
          surface: AppColors.surface,
          surfaceContainerLow: AppColors.surfaceContainerLow,
          surfaceContainerHighest: AppColors.surfaceContainerHighest,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          error: AppColors.error,
          errorContainer: AppColors.errorContainer,
        ),
        
        // Typography (Editorial Authority)
        fontFamily: 'Manrope', 
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 48,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
            height: 1.1,
            color: AppColors.textPrimary,
          ),
          displayMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
            color: AppColors.textPrimary,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        
        // Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100), // Full round
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Manrope',
            ),
          ),
        ),
        
        cardTheme: CardThemeData(
          color: AppColors.surfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Colors.transparent,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          elevation: 0,
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
        ),
      );
}
