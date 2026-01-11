import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrossPlatformStorage {
  static Future<Set<String>> getStringSet(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key)?.toSet() ?? {};
    } catch (e) {
      if (kDebugMode) {
        print('Error loading $key: $e');
      }
      return {};
    }
  }

  static Future<void> setStringSet(String key, Set<String> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, value.toList());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving $key: $e');
      }
    }
  }
}
