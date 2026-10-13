import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de MotoGastos según `design.md`: tema oscuro "glassmorphism" con
/// un rojo racing como acento, verde telemetría para estados positivos y
/// azul hielo como acento secundario.
class AppColors {
  AppColors._();

  static const Color surface = Color(0xFF0D131F);
  static const Color surfaceContainerLowest = Color(0xFF080E1A);
  static const Color surfaceContainerLow = Color(0xFF161C28);
  static const Color surfaceContainer = Color(0xFF1A202C);
  static const Color surfaceContainerHigh = Color(0xFF242A37);
  static const Color surfaceContainerHighest = Color(0xFF2F3542);

  static const Color onSurface = Color(0xFFDDE2F4);
  static const Color onSurfaceVariant = Color(0xFFE7BDB7);
  static const Color outline = Color(0xFFAD8883);

  static const Color primary = Color(0xFFFFB4AA);
  static const Color primaryContainer = Color(0xFFFF5545);
  static const Color inversePrimary = Color(0xFFC0000A);
  static const Color onPrimary = Color(0xFF690003);

  static const Color secondary = Color(0xFF47E266);
  static const Color secondaryContainer = Color(0xFF09BF49);
  static const Color secondaryFixed = Color(0xFF6CFF82);

  static const Color tertiary = Color(0xFFAAC7FF);
  static const Color tertiaryContainer = Color(0xFF3E90FF);

  static const Color error = Color(0xFFFFB4AB);

  /// Degradado del botón principal ("ignición").
  static const LinearGradient racingGradient = LinearGradient(
    colors: [primaryContainer, inversePrimary],
  );

  /// Sombra roja difusa que acompaña a los botones principales.
  static List<BoxShadow> racingGlow([double alpha = 0.45]) => [
        BoxShadow(
          color: primaryContainer.withValues(alpha: alpha),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

/// Escala tipográfica de `design.md`: Space Grotesk para títulos, etiquetas
/// y cifras de telemetría; Inter para el cuerpo de texto.
class AppText {
  AppText._();

  static TextStyle get displayHero => GoogleFonts.spaceGrotesk(
      fontSize: 32, height: 40 / 32, letterSpacing: -0.64, fontWeight: FontWeight.w700, color: AppColors.onSurface);
  static TextStyle get headlineLg => GoogleFonts.spaceGrotesk(
      fontSize: 28, height: 36 / 28, letterSpacing: -0.56, fontWeight: FontWeight.w700, color: AppColors.onSurface);
  static TextStyle get headlineMd => GoogleFonts.spaceGrotesk(
      fontSize: 22, height: 28 / 22, letterSpacing: -0.22, fontWeight: FontWeight.w600, color: AppColors.onSurface);
  static TextStyle get headlineSm => GoogleFonts.spaceGrotesk(
      fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600, color: AppColors.onSurface);
  static TextStyle get telemetryLg => GoogleFonts.spaceGrotesk(
      fontSize: 36, height: 42 / 36, letterSpacing: -1.08, fontWeight: FontWeight.w700, color: AppColors.onSurface);
  static TextStyle get telemetry => GoogleFonts.spaceGrotesk(
      fontSize: 26, height: 30 / 26, letterSpacing: -0.52, fontWeight: FontWeight.w700, color: AppColors.onSurface);
  static TextStyle get labelMd => GoogleFonts.spaceGrotesk(
      fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w500, color: AppColors.onSurface);
  static TextStyle get labelCaps => GoogleFonts.spaceGrotesk(
      fontSize: 11, height: 14 / 11, letterSpacing: 0.88, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant);
  static TextStyle get bodyLg =>
      GoogleFonts.inter(fontSize: 16, height: 24 / 16, color: AppColors.onSurface);
  static TextStyle get bodyMd =>
      GoogleFonts.inter(fontSize: 14, height: 20 / 14, color: AppColors.onSurface);
  static TextStyle get bodySm =>
      GoogleFonts.inter(fontSize: 12, height: 16 / 12, color: AppColors.onSurfaceVariant);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryContainer,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
    );

    final body = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: body.copyWith(
        headlineLarge: AppText.headlineLg,
        headlineMedium: AppText.headlineMd,
        headlineSmall: AppText.headlineSm,
        titleLarge: AppText.headlineMd,
        titleMedium: AppText.headlineSm,
        bodyLarge: AppText.bodyLg,
        bodyMedium: AppText.bodyMd,
        bodySmall: AppText.bodySm,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighest,
        contentTextStyle: AppText.bodyMd,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppText.headlineSm,
        contentTextStyle: AppText.bodyMd,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.surfaceContainerHighest),
          shape: const StadiumBorder(),
          textStyle: AppText.labelMd.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.primaryContainer),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
        labelStyle: AppText.bodySm,
        floatingLabelStyle: AppText.bodySm.copyWith(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryContainer, width: 1.5),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryContainer,
        selectionColor: Color(0x66FF5545),
        selectionHandleColor: AppColors.primaryContainer,
      ),
    );
  }
}
