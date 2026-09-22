import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y tipografía de MotoGastos — la misma dirección visual definida
/// en el prototipo: tinta oscura, papel cálido y un acento ámbar, con
/// Space Grotesk para títulos/cifras e IBM Plex Sans para el resto.
class AppColors {
  AppColors._();

  static const Color paper = Color(0xFFF6F4EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF17181C);
  static const Color ink2 = Color(0xFF5B5D66);
  static const Color line = Color(0xFFE4E1D8);
  static const Color accent = Color(0xFFCC6B1C);
  static const Color accentSoft = Color(0xFFF3DCC0);
  static const Color accentOnDark = Color(0xFFE7B583);
  static const Color teal = Color(0xFF1F6F63);
  static const Color tealSoft = Color(0xFFDCEEE9);
  static const Color viewfinder = Color(0xFF101114);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        primary: AppColors.accent,
        surface: AppColors.paper,
      ),
    );

    final bodyTextTheme = GoogleFonts.ibmPlexSansTextTheme(base.textTheme);
    final displayTextTheme = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: bodyTextTheme.copyWith(
        headlineLarge: displayTextTheme.headlineLarge
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
        headlineMedium: displayTextTheme.headlineMedium
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w700),
        headlineSmall: displayTextTheme.headlineSmall
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
        titleLarge: displayTextTheme.titleLarge
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
        titleMedium: displayTextTheme.titleMedium
            ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
        bodyLarge: bodyTextTheme.bodyLarge?.copyWith(color: AppColors.ink),
        bodyMedium: bodyTextTheme.bodyMedium?.copyWith(color: AppColors.ink),
        bodySmall: bodyTextTheme.bodySmall?.copyWith(color: AppColors.ink2),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.ibmPlexSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
