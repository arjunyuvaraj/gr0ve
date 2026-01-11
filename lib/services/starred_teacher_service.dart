import 'package:flutter/foundation.dart';
import 'package:gr0ve/services/corss_platform_storage_service.dart';

class StarredTeacherService {
  static const _key = 'starred_teachers';

  static final ValueNotifier<Set<String>> starredTeachers = ValueNotifier(
    <String>{},
  );

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;

    starredTeachers.value = await CrossPlatformStorage.getStringSet(_key);
    _loaded = true;
  }

  static Future<void> toggleTeacher(String fullName) async {
    final updated = {...starredTeachers.value};

    if (updated.contains(fullName)) {
      updated.remove(fullName);
    } else {
      updated.add(fullName);
    }

    starredTeachers.value = updated;
    await CrossPlatformStorage.setStringSet(_key, updated);
  }

  static bool isStarred(String name) {
    return starredTeachers.value.contains(name);
  }
}
