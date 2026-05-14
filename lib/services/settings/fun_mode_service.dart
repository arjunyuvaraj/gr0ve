import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FunModeService {
  FunModeService._();

  static final ValueNotifier<bool> isFunMode = ValueNotifier<bool>(false);
  static const _funModeKey = 'fun_mode_enabled';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isFunMode.value = prefs.getBool(_funModeKey) ?? false;
  }

  static Future<void> toggleFunMode(bool enabled) async {
    isFunMode.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_funModeKey, enabled);
  }
}
