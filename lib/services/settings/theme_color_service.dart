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
  custom;

  String get displayName => switch (this) {
    AppThemeColor.grover => 'Green',
    AppThemeColor.aspen => 'Yellow',
    AppThemeColor.rowan => 'Orange',
    AppThemeColor.sakura => 'Pink',
    AppThemeColor.abies => 'Blue',
    AppThemeColor.cedite => 'Purple',
    AppThemeColor.ash => 'Red',
    AppThemeColor.monochrome => 'Monochrome',
    AppThemeColor.custom => 'Custom',
  };

  Color color(Brightness brightness) {
    if (this == AppThemeColor.custom) {
      return ThemeColorService.customColorValue;
    }
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
        isDark ? const Color(0xFFE0E0E0) : const Color(0xFF424242),
      AppThemeColor.custom => ThemeColorService.customColorValue,
    };
  }

  Color onColor(Brightness brightness) => Colors.white;
}

class ThemeColorService {
  ThemeColorService._();

  static const _key = 'app_theme_color';
  static const _customHexKey = 'app_theme_custom_hex';

  static final ValueNotifier<AppThemeColor> activeColor = ValueNotifier(
    AppThemeColor.grover,
  );

  static Color customColorValue = const Color(0xFF1F6F5B);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key) ?? AppThemeColor.grover.index;
    final hexString = prefs.getString(_customHexKey) ?? 'FF1F6F5B';

    customColorValue = Color(int.parse(hexString, radix: 16));

    if (index < AppThemeColor.values.length) {
      activeColor.value = AppThemeColor.values[index];
    }
  }

  static Future<void> setColor(AppThemeColor color) async {
    activeColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, color.index);
  }

  static Future<void> setCustomColor(Color color) async {
    customColorValue = color;
    activeColor.value = AppThemeColor.custom;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, AppThemeColor.custom.index);
    await prefs.setString(
      _customHexKey,
      color.value.toRadixString(16).toUpperCase(),
    );
  }
}
