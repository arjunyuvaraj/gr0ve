import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0E1413),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF4FD1C5),
    secondary: Color(0xFF1F6F5B),
    surface: Color(0xFF151D1B),
    tertiary: Color(0xFF1A2422),
    errorContainer: Color(0xFF7A2E2E),
    onErrorContainer: Color(0xFFFFB4B4),
    onPrimary: Color(0xFF0E1413),
    onSurface: Color(0xFFE6ECEB),
  ),

  textTheme: TextTheme(
    displayLarge: GoogleFonts.jetBrainsMono(
      fontSize: 52,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(52, 18),
      color: const Color(0xFF4FD1C5),
    ),
    displayMedium: GoogleFonts.jetBrainsMono(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(40, 14),
      color: const Color(0xFF4FD1C5),
    ),
    displaySmall: GoogleFonts.manrope(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: getLetterSpacing(20, 4),
      color: const Color(0xFF9FB7B2),
    ),

    headlineMedium: GoogleFonts.manrope(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(30, 8),
      color: const Color(0xFFE6ECEB),
    ),
    headlineSmall: GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: getLetterSpacing(22, 4),
      color: const Color(0xFFD7E2E0),
    ),

    bodyMedium: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: getLetterSpacing(16, 2),
      color: const Color(0xFFB9C6C3),
    ),

    labelLarge: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(15, 10),
      color: const Color(0xFF4FD1C5),
    ),
  ),

  inputDecorationTheme: InputDecorationTheme(
    labelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w600,
      color: const Color(0xFFB9C6C3),
    ),
    floatingLabelStyle: GoogleFonts.manrope(
      fontWeight: FontWeight.w700,
      color: const Color(0xFF4FD1C5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2A3A37), width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF4FD1C5), width: 1.8),
    ),
  ),
);
