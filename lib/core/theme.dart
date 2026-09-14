import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Executive Slate Design System Colors
  static const Color primarySlate = Color(0xFF0F172A); // Deep Slate
  static const Color secondaryBlue = Color(0xFF2563EB); // Royal Blue
  static const Color secondaryBlueDark = Color(0xFF1D4ED8);
  static const Color tertiaryEmerald = Color(0xFF10B981); // Emerald Green
  static const Color emeraldLight = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);
  static const Color emeraldText = Color(0xFF047857);

  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFDE68A);
  static const Color amberText = Color(0xFFB45309);

  static const Color crimsonError = Color(0xFFEF4444);
  static const Color crimsonLight = Color(0xFFFEF2F2);
  static const Color crimsonBorder = Color(0xFFFECACA);
  static const Color crimsonText = Color(0xFFB91C1C);

  static const Color canvasBackground = Color(0xFFF8FAFC);
  static const Color cardSurface = Colors.white;
  static const Color borderSlate = Color(0xFFE2E8F0);
  static const Color borderInput = Color(0xFFCBD5E1);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0B1C30);
  static const Color textSlate = Color(0xFF1E293B);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvasBackground,
      colorScheme: const ColorScheme.light(
        primary: secondaryBlue,
        onPrimary: Colors.white,
        secondary: primarySlate,
        onSecondary: Colors.white,
        surface: cardSurface,
        onSurface: textDark,
        error: crimsonError,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: textDark,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.015,
          color: textDark,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: textDark,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSlate,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.01,
          color: textDark,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.02,
          color: textMuted,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
          color: textMuted,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSlate, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderInput, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderInput, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondaryBlue, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(
          color: textMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.01,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: borderSlate, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSlate,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
