import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primaryBg = Color(0xFF0A0A0A);
  static const Color secondarySurface = Color(0xFF121212);
  static const Color accent = Color(0xFFFF5A1F);
  static const Color accentLight = Color(0xFFFF6B35);
  static const Color accentDark = Color(0xFFFF3D00);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color cardSurface = Color(0xFFEDEDED);
  static const Color shadowDark = Colors.black;
  static const Color shadowLight = Colors.white;
}

class AppShadows {
  static List<BoxShadow> neumorphic(
      {double offset = 4, double blur = 10, double darkAlpha = 0.5, double lightAlpha = 0.05}) {
    return [
      BoxShadow(
        color: AppColors.shadowDark.withValues(alpha: darkAlpha),
        offset: Offset(offset, offset),
        blurRadius: blur,
      ),
      BoxShadow(
        color: AppColors.shadowLight.withValues(alpha: lightAlpha),
        offset: Offset(-offset * 0.75, -offset * 0.75),
        blurRadius: blur * 0.6,
      ),
    ];
  }
}

class AppTextStyles {
  static TextStyle heading = GoogleFonts.aBeeZee(
    color: AppColors.textPrimary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle body = GoogleFonts.aBeeZee(
    color: AppColors.textPrimary,
  );

  static TextStyle bodySecondary = GoogleFonts.aBeeZee(
    color: AppColors.textSecondary,
  );

  static TextStyle inter = GoogleFonts.inter(
    color: AppColors.textPrimary,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.primaryBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        centerTitle: true,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.secondarySurface,
      ),
    );
  }
}
