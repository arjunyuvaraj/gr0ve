import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8F9F9),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1F6F5B),
    secondary: Color(0xFF1F6F5B),
    surface: Color(0xFFFFFFFF),
    tertiary: Color(0xFFF2F4F4),
    errorContainer: Color(0xFFFFEBEE),
    onErrorContainer: Color(0xFFC62828),
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A1D1F),
    onSurfaceVariant: Color(0xFF6F767E),
  ),

  textTheme: TextTheme(
    displayLarge: GoogleFonts.jetBrainsMono(
      fontSize: 52,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(52, 18),
      color: const Color(0xFF1F6F5B),
    ),
    displayMedium: GoogleFonts.jetBrainsMono(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(40, 14),
      color: const Color(0xFF1F6F5B),
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: getLetterSpacing(20, 4),
      color: const Color(0xFF6F767E),
    ),

    headlineMedium: GoogleFonts.manrope(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(30, 8),
      color: const Color(0xFF1A1D1F),
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(22, 4),
      color: const Color(0xFF1A1D1F),
    ),

    bodyMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: getLetterSpacing(16, 2),
      color: const Color(0xFF1A1D1F),
    ),

    titleMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(16, 1),
      color: const Color(0xFF1A1D1F),
    ),
    titleSmall: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: getLetterSpacing(14, 1),
      color: const Color(0xFF1A1D1F),
    ),
    bodyLarge: GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      letterSpacing: getLetterSpacing(18, 1),
      color: const Color(0xFF1A1D1F),
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      letterSpacing: getLetterSpacing(13, 1),
      color: const Color(0xFF6F767E),
    ),
    labelLarge: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(15, 10),
      color: const Color(0xFF1F6F5B),
    ),
    labelMedium: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(12, 2),
      color: const Color(0xFF6F767E),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF2F4F4),
    labelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6F767E),
    ),
    floatingLabelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1F6F5B),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF1F6F5B), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),

  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xFF1A1D1F),
    contentTextStyle: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    titleTextStyle: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1A1D1F),
    ),
    contentTextStyle: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1A1D1F),
    ),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1F6F5B),
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
    backgroundColor: const Color(0xFFF2F4F4),
    labelStyle: GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1D1F),
    ),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  ),
);
