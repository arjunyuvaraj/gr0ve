import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/utilities/helper/helper_functions.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFDFEFE),

  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1F6F5B),
    secondary: Color(0xFF4FD1C5),
    errorContainer: Color(0xFF6F1F1F),
    onErrorContainer: Color.fromARGB(255, 209, 79, 79),
    surface: Color(0xFFFFFFFF),
    tertiary: Color(0xFFF2F7F6),
    onPrimary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1A1D1F),
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
      fontWeight: FontWeight.w500,
      color: const Color(0xFF5F6C72),
      letterSpacing: getLetterSpacing(20, 4),
    ),

    headlineMedium: GoogleFonts.manrope(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(30, 8),
      color: const Color(0xFF1A1D1F),
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: getLetterSpacing(22, 4),
      color: const Color(0xFF1A1D1F),
    ),

    bodyMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: getLetterSpacing(16, 2),
      color: const Color(0xFF2E3336),
    ),

    labelLarge: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(15, 10),
      color: const Color(0xFF1F6F5B),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    labelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF2E3336),
    ),
    floatingLabelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF1F6F5B),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD1D9D6), width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1F6F5B), width: 1.8),
    ),
  ),
);
