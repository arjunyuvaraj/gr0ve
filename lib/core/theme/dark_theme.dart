import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF111111),

  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF48A68B),
    secondary: Color(0xFF48A68B),
    surface: Color(0xFF1A1A1A),
    tertiary: Color(0xFF262626),
    errorContainer: Color(0xFF3D1F1F),
    onErrorContainer: Color(0xFFFFB4B4),
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

    labelLarge: GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      letterSpacing: getLetterSpacing(15, 10),
      color: const Color(0xFF48A68B), // Use updated secondary color
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
);
