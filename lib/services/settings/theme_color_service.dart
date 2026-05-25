import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeColor {
  grover,
  aspen,
  rowan,
  sakura,
  abies,
  cedite,
  ash,
  monochrome,
  counselorSync;

  String get displayName => switch (this) {
    AppThemeColor.grover => 'Green',
    AppThemeColor.aspen => 'Yellow',
    AppThemeColor.rowan => 'Orange',
    AppThemeColor.sakura => 'Pink',
    AppThemeColor.abies => 'Blue',
    AppThemeColor.cedite => 'Purple',
    AppThemeColor.ash => 'Red',
    AppThemeColor.monochrome => 'Mono',
    AppThemeColor.counselorSync => 'Sync',
  };

  IconData? get pickerIcon => switch (this) {
    AppThemeColor.counselorSync => Icons.sync_rounded,
    _ => null,
  };

  Color color(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      AppThemeColor.grover =>
        isDark ? const Color(0xFF35B595) : const Color(0xFF1F6F5B),
      AppThemeColor.aspen =>
        isDark ? const Color(0xFFFFDD71) : const Color(0xFFFFC200),
      AppThemeColor.rowan =>
        isDark ? const Color(0xFFFF6F2A) : const Color(0xFFAD3800),
      AppThemeColor.sakura =>
        isDark ? const Color(0xFFEEC3F5) : const Color(0xFFDC8FE8),
      AppThemeColor.abies => const Color(0xFF00C8FF),
      AppThemeColor.cedite =>
        isDark ? const Color(0xFFB388EB) : const Color(0xFF9F72D8),
      AppThemeColor.ash =>
        isDark ? const Color(0xFFE55B5B) : const Color(0xFFC43D3D),
      AppThemeColor.monochrome =>
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111111),

      AppThemeColor.counselorSync =>
        isDark ? const Color(0xFF35B595) : const Color(0xFF1F6F5B),
    };
  }

  Color onColor(Brightness brightness) {
    if (this == AppThemeColor.monochrome) {
      return brightness == Brightness.dark ? Colors.black : Colors.white;
    }

    if (brightness == Brightness.dark) {
      if (this == AppThemeColor.aspen || this == AppThemeColor.sakura) {
        return Colors.black;
      }
    }
    return Colors.white;
  }
}

class ThemeColorService {
  ThemeColorService._();

  static const _key = 'app_theme_color';

  static final ValueNotifier<AppThemeColor> activeColor = ValueNotifier(
    AppThemeColor.grover,
  );

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? AppThemeColor.grover.index;

    if (index < AppThemeColor.values.length) {
      activeColor.value = AppThemeColor.values[index];
    }
  }

  static Future<void> setColor(AppThemeColor color) async {
    activeColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, color.index);
  }
}
