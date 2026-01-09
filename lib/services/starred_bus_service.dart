import 'package:shared_preferences/shared_preferences.dart';

class StarredBusService {
  static const _key = 'starred_towns';

  static Future<Set<String>> getStarredTowns() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  static Future<void> toggleTown(String town) async {
    final prefs = await SharedPreferences.getInstance();
    final towns = prefs.getStringList(_key)?.toSet() ?? {};

    if (towns.contains(town)) {
      towns.remove(town);
    } else {
      towns.add(town);
    }

    await prefs.setStringList(_key, towns.toList());
  }

  static bool routeIsStarred(
    List<String> routeTowns,
    Set<String> starredTowns,
  ) {
    return routeTowns.any(starredTowns.contains);
  }
}
