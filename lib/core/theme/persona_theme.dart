import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/core/helper/helper_functions.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

// ─────────────────────────────────────────────────────────────
// PERSONA THEME BUILDER
//
// Generates a full ThemeData for light or dark mode using
// whichever persona is active. Drop-in replacement for the
// static lightTheme / darkTheme you had before.
//
// Usage in main.dart:
//   ValueListenableBuilder<CounselorPersona>(
//     valueListenable: CounselorPersonaService.activePersona,
//     builder: (context, persona, _) {
//       return MaterialApp(
//         theme:     PersonaTheme.light(persona),
//         darkTheme: PersonaTheme.dark(persona),
//         ...
//       );
//     },
//   )
// ─────────────────────────────────────────────────────────────

class PersonaTheme {
  const PersonaTheme._();

  static ThemeData light(CounselorPersona persona) =>
      _build(persona, Brightness.light);

  static ThemeData dark(CounselorPersona persona) =>
      _build(persona, Brightness.dark);

  static ThemeData _build(CounselorPersona persona, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    print("IS DARK" + isDark.toString());
    final primary = persona.primary(brightness);
    final onPrimary = persona.onPrimary(brightness);

    // ── Scaffold / surface colours (unchanged from your originals) ──
    final scaffoldBg = isDark
        ? const Color(0xFF111111)
        : const Color(0xFFF8F9F9);
    final surface = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
    final tertiary = isDark ? const Color(0xFF262626) : const Color(0xFFF2F4F4);
    final onSurface = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1A1D1F);
    final onSurfaceVariant = isDark
        ? const Color(0xFF9AA0A6)
        : const Color(0xFF454C52);
    final errorContainer = isDark
        ? const Color(0xFF3D1F1F)
        : const Color(0xFFFFEBEE);
    final onErrorContainer = isDark
        ? const Color(0xFFFFB4B4)
        : const Color(0xFFC62828);

    // Input fill uses surface in dark, tertiary in light
    final inputFill = isDark ? surface : tertiary;

    // ── Label colour: use persona primary (slightly muted in dark) ──
    final labelColor = isDark ? primary : primary;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: primary,
        onSecondary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        error: isDark ? const Color(0xFFFFB4B4) : const Color(0xFFC62828),
        onError: Colors.white,
        tertiary: tertiary,
        onTertiary: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        // Keep outline subtle regardless of persona
        outline: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0),
        surfaceContainerHighest: isDark
            ? const Color(0xFF262626)
            : const Color(0xFFF2F4F4),
      ),

      textTheme: TextTheme(
        displayLarge: GoogleFonts.jetBrainsMono(
          fontSize: 52,
          fontWeight: isDark ? FontWeight.w900 : FontWeight.w800,
          letterSpacing: getLetterSpacing(52, 18),
          color: isDark ? Colors.white : primary,
        ),
        displayMedium: GoogleFonts.jetBrainsMono(
          fontSize: 40,
          fontWeight: isDark ? FontWeight.w800 : FontWeight.w700,
          letterSpacing: getLetterSpacing(40, 14),
          color: isDark ? Colors.white : primary,
        ),
        displaySmall: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: getLetterSpacing(20, 4),
          color: onSurfaceVariant,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: getLetterSpacing(30, 8),
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: getLetterSpacing(22, 4),
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: getLetterSpacing(18, 1),
          color: isDark ? const Color(0xFFE8EAED) : onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: getLetterSpacing(16, 2),
          color: isDark ? const Color(0xFFE8EAED) : onSurface,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: getLetterSpacing(13, 1),
          color: onSurfaceVariant,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: getLetterSpacing(16, 1),
          color: onSurface,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: getLetterSpacing(14, 1),
          color: onSurface,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: getLetterSpacing(15, 10),
          color: labelColor,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: getLetterSpacing(12, 2),
          color: onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: getLetterSpacing(11, 1),
          color: onSurfaceVariant,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
        floatingLabelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          color: primary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF262626)
            : const Color(0xFF1A1D1F),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xFFE8EAED) : onSurface,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          elevation: 0,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? const Color(0xFF262626)
            : const Color(0xFFF2F4F4),
        labelStyle: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Switches, checkboxes, radio buttons — all follow persona primary
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withOpacity(0.4)
              : null,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppColorScheme EXTENSION (kept for backward compatibility)
// Any code using context.colorScheme.success still works.
// ─────────────────────────────────────────────────────────────

extension AppColorScheme on ColorScheme {
  Color get success => brightness == Brightness.dark
      ? const Color(0xFF35B595)
      : const Color(0xFF1F6F5B);
}
