import 'package:shared_preferences/shared_preferences.dart';

class StarredTeacherService {
  static const String _storageKey = "starred_teachers";

  static Future<Set<String>> getStarredTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_storageKey) ?? [];
    return list.toSet();
  }

  static Future<void> toggleTeacher(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? [];

    if (current.contains(fullName)) {
      current.remove(fullName);
    } else {
      current.add(fullName);
    }

    await prefs.setStringList(_storageKey, current);
  }

  static Future<void> starTeacher(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? [];

    if (!current.contains(fullName)) {
      current.add(fullName);
      await prefs.setStringList(_storageKey, current);
    }
  }

  static Future<void> unstarTeacher(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_storageKey) ?? [];

    current.remove(fullName);
    await prefs.setStringList(_storageKey, current);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static Future<bool> isStarred(String fullName) async {
    final starred = await getStarredTeachers();
    return starred.contains(fullName);
  }
}
