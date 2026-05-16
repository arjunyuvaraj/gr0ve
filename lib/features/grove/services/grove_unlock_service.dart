import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroveUnlockService {
  GroveUnlockService._();

  static final ValueNotifier<bool> isUnlocked = ValueNotifier<bool>(false);
  static const _key = 'grove_unlocked_easter_egg';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isUnlocked.value = prefs.getBool(_key) ?? false;
  }

  static Future<void> unlock() async {
    isUnlocked.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
