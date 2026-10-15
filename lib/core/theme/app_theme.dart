import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6B35);
  static const Color accent = Color(0xFFFFC857);
  static const Color success = Color(0xFF22C55E);

  // Light
  static const Color lightBackground = Color(0xFFFFF8F1);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Dark
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Task Types
  static const Color taskColor = Color(0xFFFF6B35);
  static const Color reminderColor = Color(0xFF3B82F6);
  static const Color deadlineColor = Color(0xFFEF4444);
  static const Color eventColor = Color(0xFF8B5CF6);

  static Color getTaskTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'task':
        return taskColor;
      case 'reminder':
        return reminderColor;
      case 'deadline':
        return deadlineColor;
      case 'event':
        return eventColor;
      default:
        return primary;
    }
  }

  static IconData getTaskTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'task':
        return Icons.check_circle_outline_rounded;
      case 'reminder':
        return Icons.notifications_active_outlined;
      case 'deadline':
        return Icons.alarm_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.check_box_outlined;
    }
  }
}

class AppTheme {
  static const double cardRadius = 24.0;
  static const double pillRadius = 50.0;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.lightSurface,
      onPrimary: Colors.white,
      onSecondary: AppColors.lightTextPrimary,
      onSurface: AppColors.lightTextPrimary,
      error: AppColors.deadlineColor,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.lightTextPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.lightTextSecondary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pillRadius),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.15),
      side: BorderSide.none,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.lightSurface,
      modalBackgroundColor: AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      onPrimary: Colors.white,
      onSecondary: AppColors.darkTextPrimary,
      onSurface: AppColors.darkTextPrimary,
      error: AppColors.deadlineColor,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(pillRadius),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      backgroundColor: AppColors.darkSurface,
      selectedColor: AppColors.primary.withOpacity(0.25),
      side: BorderSide.none,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      modalBackgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
