import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService {
  AccessibilityService._();

  static final ValueNotifier<bool> accessibleColors = ValueNotifier<bool>(false);
  static const _accessibleColorsKey = 'accessible_colors_enabled';

  static final ValueNotifier<bool> autoVoiceGreeting = ValueNotifier<bool>(true);
  static const _autoVoiceGreetingKey = 'auto_voice_greeting_enabled';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    accessibleColors.value = prefs.getBool(_accessibleColorsKey) ?? false;
    autoVoiceGreeting.value = prefs.getBool(_autoVoiceGreetingKey) ?? true;
  }

  static Future<void> toggleAccessibleColors(bool enabled) async {
    accessibleColors.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_accessibleColorsKey, enabled);
  }

  static Future<void> toggleAutoVoiceGreeting(bool enabled) async {
    autoVoiceGreeting.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoVoiceGreetingKey, enabled);
  }
}
