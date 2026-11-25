
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// EXPLORE LIPA COLOR PALETTE
class AppColors {
  static const Color forest = Color(0xFF17452F);
  static const Color green = Color(0xFF347A50);
  static const Color sage = Color(0xFFEAF2E9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7F4);
  static const Color charcoal = Color(0xFF26352B);
  static const Color grey = Color(0xFF858D86);
  static const Color border = Color(0xFFE2E8E1);
}

// EXPLORE LIPA APP THEME
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        secondary: AppColors.green,
        surface: AppColors.white,
      ),

      // TYPOGRAPHY
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),

        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),

        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),

        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          color: AppColors.charcoal,
        ),

        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          color: AppColors.charcoal,
        ),
      ),

      // TEXT FIELD DESIGN
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.forest,
            width: 1.5,
          ),
        ),
      ),

      // BUTTON DESIGN
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
