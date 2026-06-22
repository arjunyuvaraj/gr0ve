import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HiddenFishDefinition {
  const HiddenFishDefinition({
    required this.id,
    required this.name,
    required this.album,
    required this.asset,
    required this.description,
  });

  final String id;
  final String name;
  final String album;
  final String asset;
  final String description;
}

class HiddenFishService {
  HiddenFishService._();

  static const _prefsFoundKey = 'hidden_fish_found_ids';
  static const foundField = 'hidden_fish_found_ids';
  static const chapterTwoField = 'grove_story_chapter_two_unlocked';

  static final ValueNotifier<Set<String>> foundIds = ValueNotifier<Set<String>>(
    <String>{},
  );
  static final ValueNotifier<bool> isChapterTwoUnlocked = ValueNotifier<bool>(
    false,
  );
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _remoteSubscription;

  static const List<HiddenFishDefinition> fish = [
    HiddenFishDefinition(
      id: 'polaro_1989',
      name: 'Polaro',
      album: '1989',
      asset: 'assets/fish/polaro.svg',
      description:
          'Polaro is a bright little archivist with mirror-blue scales and a habit of darting toward clean air, city lights, and fresh starts. It looks simple at first glance, then catches the light like an old photo coming into focus.',
    ),
    HiddenFishDefinition(
      id: 'neonfin_after_hours',
      name: 'Neonfin',
      album: 'After Hours',
      asset: 'assets/fish/neofin.svg',
      description:
          'Neonfin only swims after the hallway lights feel too bright. Its fins pulse like late-night signs through rain, glamorous from far away and a little haunted up close.',
    ),
    HiddenFishDefinition(
      id: 'stinger_scorpion',
      name: 'Stinger',
      album: 'Scorpion',
      asset: 'assets/fish/stinger.svg',
      description:
          'Stinger keeps its circle small and its armor polished. It glides like it has heard every rumor already, sharp enough to defend its waters but loyal once it chooses a current.',
    ),
    HiddenFishDefinition(
      id: 'solito_un_verano_sin_ti',
      name: 'Solito',
      album: 'Un Verano Sin Ti',
      asset: 'assets/fish/solito.svg',
      description:
          'Solito is sun-warmed, restless, and secretly tender. It drifts between golden shallows and party-bright tides, carrying the ache of a summer that was loud until it was lonely.',
    ),
    HiddenFishDefinition(
      id: 'halves_divide',
      name: 'Halves',
      album: 'Divide',
      asset: 'assets/fish/halves.svg',
      description:
          'Halves follows every fork in the stream and somehow remembers both paths. It is built from contrast: soft current and quick turn, quiet confession and bright chorus.',
    ),
    HiddenFishDefinition(
      id: 'somnus_when_we_all_fall_asleep',
      name: 'Somnus',
      album: 'When We All Fall Asleep, Where Do We Go?',
      asset: 'assets/fish/somnus.svg',
      description:
          'Somnus is a dream-floor fish, almost too quiet to be real. It slips through shadowy water with a lullaby grin, playful and eerie like something you noticed right before waking.',
    ),
    HiddenFishDefinition(
      id: 'petalback_thank_u_next',
      name: 'Petalback',
      album: 'thank u, next',
      asset: 'assets/fish/petalback.svg',
      description:
          'Petalback wears its softness like armor. It has learned from every tide that pushed it around, and now it swims forward glossy, wounded, grateful, and impossible to stop.',
    ),
  ];

  static int get foundCount => foundIds.value.length;
  static bool get hasFoundAll => foundIds.value.length >= fish.length;

  static HiddenFishDefinition byId(String id) =>
      fish.firstWhere((definition) => definition.id == id);

  static Future<void> init({Map<String, dynamic>? cachedUserData}) async {
    await _remoteSubscription?.cancel();
    _remoteSubscription = null;

    final prefs = await SharedPreferences.getInstance();
    final localFound = prefs.getStringList(_prefsFoundKey) ?? <String>[];
    final remoteFound = _readStringList(cachedUserData?[foundField]);
    final remoteDoc = await _fetchRemoteUserDoc();
    final remoteServer = _readStringList(remoteDoc?[foundField]);
    final mergedFound = _mergeFishIds([localFound, remoteFound, remoteServer]);
    final chapterUnlocked =
        (cachedUserData?[chapterTwoField] as bool?) ??
        (remoteDoc?[chapterTwoField] as bool?) ??
        mergedFound.length >= fish.length;

    await _applyState(
      prefs: prefs,
      found: mergedFound,
      chapterTwoUnlocked: chapterUnlocked,
      reason: 'init',
      persistRemote: true,
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _remoteSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) async {
            final remote = _mergeFishIds([
              _readStringList(snapshot.data()?[foundField]),
            ]);
            final remoteChapter = snapshot.data()?[chapterTwoField] == true;
            final merged = _mergeFishIds([foundIds.value.toList(), remote]);
            final shouldUnlock = remoteChapter || merged.length >= fish.length;

            debugPrint(
              '[HiddenFish] Remote sync snapshot: ${merged.length}/${fish.length} found; '
              'chapterTwo=$shouldUnlock',
            );

            await _applyState(
              found: merged,
              chapterTwoUnlocked: shouldUnlock,
              reason: 'snapshot',
            );
          });
    }

    debugPrint(
      '[HiddenFish] Init complete: ${foundIds.value.length}/${fish.length} found; '
      'chapterTwo=${isChapterTwoUnlocked.value}',
    );
  }

  static Future<bool> discover(String id) async {
    if (!fish.any((definition) => definition.id == id)) {
      debugPrint('[HiddenFish] Unknown fish id ignored: $id');
      return false;
    }
    if (foundIds.value.contains(id)) {
      debugPrint('[HiddenFish] Already discovered: $id');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    final remoteDoc = await _fetchRemoteUserDoc();
    final remote = _readStringList(remoteDoc?[foundField]);
    final next = _mergeFishIds([
      foundIds.value.toList(),
      remote,
      [id],
    ]);
    final unlockedChapterTwo = next.length >= fish.length;

    await _applyState(
      prefs: prefs,
      found: next,
      chapterTwoUnlocked: unlockedChapterTwo,
      reason: 'discover',
    );
    debugPrint('[HiddenFish] Discovered $id (${next.length}/${fish.length})');

    if (user != null) {
      try {
        final updates = <String, dynamic>{
          foundField: next,
          chapterTwoField: unlockedChapterTwo,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));

        final cached = UserDocCache.getCached();
        if (cached != null) {
          UserDocCache.update({
            ...cached,
            foundField: next,
            chapterTwoField: unlockedChapterTwo,
          });
        }

        debugPrint(
          '[HiddenFish] Remote write complete for ${user.uid}; '
          'found=${next.length}; chapterTwo=$unlockedChapterTwo',
        );
      } catch (_) {}
    }

    return true;
  }

  static Future<void> showInfoDialog(
    BuildContext context,
    HiddenFishDefinition definition, {
    bool discovered = true,
  }) async {
    final colors = Theme.of(context).colorScheme;
    debugPrint(
      '[HiddenFish] Showing dialog for ${definition.id}; discovered=$discovered',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            discovered ? "You've found ${definition.name}" : definition.name,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                definition.asset,
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                definition.description,
                style: TextStyle(
                  height: 1.45,
                  color: colors.onSurface.withOpacity(0.78),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Keep exploring'),
            ),
          ],
        );
      },
    );
  }

  static void reset() {
    _remoteSubscription?.cancel();
    _remoteSubscription = null;
    foundIds.value = <String>{};
    isChapterTwoUnlocked.value = false;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_prefsFoundKey);
      prefs.remove(chapterTwoField);
    });
    debugPrint('[HiddenFish] Reset');
  }

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return <String>[];
  }

  static List<String> _mergeFishIds(Iterable<Iterable<String>> groups) {
    final merged = <String>{};
    for (final group in groups) {
      for (final id in group) {
        if (fish.any((definition) => definition.id == id)) {
          merged.add(id);
        }
      }
    }
    final list = merged.toList()..sort();
    return list;
  }

  static Future<Map<String, dynamic>?> _fetchRemoteUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      final data = doc.data();
      if (kDebugMode) {
        debugPrint(
          '[HiddenFish] Remote fetch: '
          '${_readStringList(data?[foundField]).length}/${fish.length} found; '
          'chapterTwo=${data?[chapterTwoField] == true}',
        );
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HiddenFish] Remote fetch failed: $e');
      }
      return null;
    }
  }

  static Future<void> _applyState({
    SharedPreferences? prefs,
    required List<String> found,
    required bool chapterTwoUnlocked,
    required String reason,
    bool persistRemote = false,
  }) async {
    final normalized = _mergeFishIds([found]);
    foundIds.value = normalized.toSet();
    isChapterTwoUnlocked.value =
        chapterTwoUnlocked || normalized.length >= fish.length;

    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    await sharedPrefs.setStringList(_prefsFoundKey, normalized);
    await sharedPrefs.setBool(chapterTwoField, isChapterTwoUnlocked.value);

    debugPrint(
      '[HiddenFish] State applied from $reason: '
      '${normalized.length}/${fish.length} found; '
      'chapterTwo=${isChapterTwoUnlocked.value}',
    );

    if (persistRemote) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                foundField: normalized,
                chapterTwoField: isChapterTwoUnlocked.value,
              }, SetOptions(merge: true));
          if (kDebugMode) {
            debugPrint(
              '[HiddenFish] Primed remote state for ${user.uid} from $reason',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[HiddenFish] Priming remote state failed: $e');
          }
        }
      }
    }
  }
}
