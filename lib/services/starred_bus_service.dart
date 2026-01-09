import 'package:shared_preferences/shared_preferences.dart';

class StarredBusService {
  static const _key = 'starred_towns';

  class StarredBusService {
  static final ValueNotifier<Set<String>> starredTowns =
      ValueNotifier(<String>{});

  static Future<void> load() async {
    starredTowns.value = await getStarredTowns();
  }

  static Future<void> toggleTown(String town) async {
    final current = await getStarredTowns();

    if (current.contains(town)) {
      current.remove(town);
    } else {
      current.add(town);
    }

    await saveStarredTowns(current);
    starredTowns.value = Set.from(current);
  }
}

}
