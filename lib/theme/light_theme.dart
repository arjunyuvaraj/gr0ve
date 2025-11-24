import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

final lightTheme = ThemeData(
  // LIGHT THEME
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  // COLOR SCHEME
  colorScheme: ColorScheme.light(
    primary: Color(0xFF496E4C),
    secondary: Color(0xFF202124),
    tertiary: Color(0xFFF6F5F4),
    onPrimary: Color(0xFFFDFDFD),
    onSurface: Color(0xFF202124),
  ),
  textTheme: TextTheme(
    // TEXT: Displays
    displayLarge: GoogleFonts.robotoMono(
      fontWeight: FontWeight.w900,
      fontSize: 64,
      color: Color(0xFF253726).withAlpha(225),
      letterSpacing: getLetterSpacing(54, 25),
    ),
    displayMedium: GoogleFonts.robotoMono(
      fontWeight: FontWeight.w900,
      fontSize: 52,
      color: Color(0xFF253726).withAlpha(225),
      letterSpacing: getLetterSpacing(54, 15),
    ),
    displaySmall: GoogleFonts.robotoMono(
      fontWeight: FontWeight.w500,
      fontSize: 24,
      fontStyle: FontStyle.italic,
      color: Color(0xFF253726).withAlpha(100),
      letterSpacing: getLetterSpacing(24, 5),
    ),
    // TEXT: Headlines
    headlineMedium: GoogleFonts.roboto(
      fontWeight: FontWeight.w900,
      fontSize: 32,
      letterSpacing: getLetterSpacing(32, 15),
    ),
    headlineSmall: GoogleFonts.roboto(
      fontWeight: FontWeight.w600,
      fontSize: 24,
      color: Colors.black,
      letterSpacing: getLetterSpacing(24, 5),
    ),

    // TEXT: Bodies
    bodyMedium: GoogleFonts.roboto(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: Color(0xFF202124),
      letterSpacing: getLetterSpacing(18, 2.5),
    ),

    // TEXT: Labels
    labelLarge: GoogleFonts.workSans(
      color: Color(0xFFDADADA),
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: getLetterSpacing(16, 10),
    ),
  ),

  // INPUT
  inputDecorationTheme: InputDecorationTheme(
    labelStyle: GoogleFonts.workSans(
      color: Color(0xFF202124), // visible label color when not focused
      fontWeight: FontWeight.w600,
    ),
    floatingLabelStyle: GoogleFonts.workSans(
      color: Color(0xFF202124),
      fontWeight: FontWeight.w700,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black45, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black45, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
);
