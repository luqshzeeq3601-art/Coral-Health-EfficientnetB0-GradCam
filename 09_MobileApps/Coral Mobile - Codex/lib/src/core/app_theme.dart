import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const page = Color(0xFFF7F5F1); // Soft warm off-white sand tone
  static const ink = Color(0xFF061449);
  static const muted = Color(0xFF6D789D);
  static const line = Color(0xFFDCE8F7);
  static const primary = Color(0xFF0057E6);
  static const primarySoft = Color(0xFFEAF4FF);
  static const cyan = Color(0xFF0EA5FF);
  static const violet = Color(0xFF6848F5);
  static const green = Color(0xFF16B979);

  // Semantic classification tokens from docs/design/design.md
  static const healthy = Color(0xFF00685F);
  static const healthySoft = Color(0xFFF0FDFA);
  static const bleached = Color(0xFFD97706);
  static const bleachedSoft = Color(0xFFFEF3E8);
  static const dead = Color(0xFFDC2626);
  static const deadSoft = Color(0xFFFDF0F0);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.page,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rethinkSans(
          fontSize:
              24, // docs/design/design.md display headers: Rethink Sans, Max size 24px on mobile
          height: 1.05,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.rethinkSans(
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.rethinkSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
          letterSpacing: 0,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
