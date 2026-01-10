import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarredTeacherService {
  static const _key = 'starred_teachers';

  static final ValueNotifier<Set<String>> starredTeachers = ValueNotifier(
    <String>{},
  );

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    starredTeachers.value = prefs.getStringList(_key)?.toSet() ?? {};
    _loaded = true;
  }

  static Future<void> toggleTeacher(String fullName) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {...starredTeachers.value};

    if (updated.contains(fullName)) {
      updated.remove(fullName);
    } else {
      updated.add(fullName);
    }

    starredTeachers.value = updated;
    await prefs.setStringList(_key, updated.toList());
  }

  static bool isStarred(String name) {
    return starredTeachers.value.contains(name);
  }
}
