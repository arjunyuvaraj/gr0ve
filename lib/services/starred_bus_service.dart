import 'package:flutter/material.dart';
import 'package:gr0ve/services/corss_platform_storage_service.dart';

class StarredBusService {
  static const _key = 'starred_towns';

  static final ValueNotifier<Set<String>> starredTowns = ValueNotifier(
    <String>{},
  );

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;

    starredTowns.value = await CrossPlatformStorage.getStringSet(_key);
    _loaded = true;
  }

  static Future<void> toggleTown(String town) async {
    final updated = {...starredTowns.value};

    if (updated.contains(town)) {
      updated.remove(town);
    } else {
      updated.add(town);
    }

    starredTowns.value = updated;
    await CrossPlatformStorage.setStringSet(_key, updated);
  }

  static bool isStarred(String town) {
    return starredTowns.value.contains(town);
  }
}
