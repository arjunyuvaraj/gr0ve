import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StarredBusService {
  static const _key = 'starred_towns';

  static final ValueNotifier<Set<String>> starredTowns = ValueNotifier(
    <String>{},
  );

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    starredTowns.value = prefs.getStringList(_key)?.toSet() ?? {};
    _loaded = true;
  }

  static Future<void> toggleTown(String town) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {...starredTowns.value};

    if (updated.contains(town)) {
      updated.remove(town);
    } else {
      updated.add(town);
    }

    starredTowns.value = updated;
    await prefs.setStringList(_key, updated.toList());
  }

  static bool isStarred(String town) {
    return starredTowns.value.contains(town);
  }
}
