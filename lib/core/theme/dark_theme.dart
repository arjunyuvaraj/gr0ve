import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';

extension AppColorScheme on ColorScheme {
  Color get success => brightness == Brightness.dark
      ? const Color(0xFF35B595)
      : const Color(0xFF1F6F5B);
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF111111),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFEEC3F5),
    secondary: Color(0xFFEEC3F5),
    surface: Color(0xFF1A1A1A),
    tertiary: Color(0xFF262626),
    error: Color(0xFFFB7185),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF2D1A1A),
    onErrorContainer: Color(0xFFFF8A8A),
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF9AA0A6),
  ),

  textTheme: TextTheme(
    displayLarge: GoogleFonts.jetBrainsMono(
      fontSize: 52,
      fontWeight: FontWeight.w900,
      letterSpacing: getLetterSpacing(52, 18),
      color: Colors.white,
    ),
    displayMedium: GoogleFonts.jetBrainsMono(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(40, 14),
      color: Colors.white,
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: getLetterSpacing(20, 4),
      color: const Color(0xFF9AA0A6),
    ),

    headlineMedium: GoogleFonts.manrope(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(30, 8),
      color: Colors.white,
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(22, 4),
      color: Colors.white,
    ),

    bodyMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: getLetterSpacing(16, 2),
      color: const Color(0xFFE8EAED),
    ),

    titleMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(16, 1),
      color: Colors.white,
    ),
    titleSmall: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: getLetterSpacing(14, 1),
      color: Colors.white,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: getLetterSpacing(18, 1),
      color: const Color(0xFFE8EAED),
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: getLetterSpacing(13, 1),
      color: const Color(0xFF9AA0A6),
    ),
    labelLarge: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(15, 10),
      color: const Color(0xFF48A68B),
    ),
    labelMedium: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(12, 2),
      color: const Color(0xFF9AA0A6),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1A1A1A),
    labelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF9AA0A6),
    ),
    floatingLabelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF48A68B),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF48A68B), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),

  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF262626),
    contentTextStyle: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFF1A1A1A),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    titleTextStyle: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    contentTextStyle: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: const Color(0xFFE8EAED),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF48A68B),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
      elevation: 0,
    ),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: const Color(0xFF262626),
    labelStyle: GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
);
