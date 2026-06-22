import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/features/grove/episodes/episode_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

class GroveGameState {
  String currentScene;
  int stability;
  int connectivity;
  int vitality;
  int transience;
  int seedWarmth;
  List<String> inventory;
  String? chosenPath;
  int currentEpisode;
  bool episodeComplete;
  bool newtonUnlocked;
  bool darwinUnlocked;
  bool salixUnlocked;
  bool londonUnlocked;
  String? intentionVessel;
  int? busyUntil;
  String? pendingScene;
  int skips1h;
  int skips3h;
  int skips5h;

  int newtonRiddleAttempts;
  bool newtonRiddleSolved;
  int newtonExitAttempts;
  bool newtonExitSolved;

  bool darwinConversationHad;
  bool darwinDefaultModeUnlocked;

  Map<String, List<Map<String, dynamic>>> episodeHistories;
  Map<String, Map<String, dynamic>> episodeStartStates;
  bool isBetaTester;

  GroveGameState({
    this.currentScene = 'ep0_intro',
    this.stability = 0,
    this.connectivity = 0,
    this.vitality = 0,
    this.transience = 0,
    this.seedWarmth = 100,
    List<String>? inventory,
    this.chosenPath,
    this.currentEpisode = 0,
    this.episodeComplete = false,
    this.newtonUnlocked = false,
    this.darwinUnlocked = false,
    this.salixUnlocked = false,
    this.londonUnlocked = false,
    this.intentionVessel,
    this.newtonRiddleAttempts = 0,
    this.newtonRiddleSolved = false,
    this.newtonExitAttempts = 0,
    this.newtonExitSolved = false,
    this.darwinConversationHad = false,
    this.darwinDefaultModeUnlocked = false,
    this.busyUntil,
    this.pendingScene,
    this.skips1h = 0,
    this.skips3h = 0,
    this.skips5h = 0,
    this.isBetaTester = false,
    Map<String, List<Map<String, dynamic>>>? episodeHistories,
    Map<String, Map<String, dynamic>>? episodeStartStates,
  }) : inventory = inventory ?? [],
       episodeHistories = episodeHistories ?? {},
       episodeStartStates = episodeStartStates ?? {};

  void clampStats() {
    stability = stability.clamp(-5, 5);
    connectivity = connectivity.clamp(-5, 5);
    vitality = vitality.clamp(-5, 5);
    transience = transience.clamp(-5, 5);
    seedWarmth = seedWarmth.clamp(0, 100);
  }

  Map<String, dynamic> toJson() {
    clampStats();
    return {
      'currentScene': currentScene,
      'stability': stability,
      'connectivity': connectivity,
      'vitality': vitality,
      'transience': transience,
      'seedWarmth': seedWarmth,
      'inventory': inventory,
      'chosenPath': chosenPath,
      'currentEpisode': currentEpisode,
      'episodeComplete': episodeComplete,
      'newtonUnlocked': newtonUnlocked,
      'darwinUnlocked': darwinUnlocked,
      'salixUnlocked': salixUnlocked,
      'londonUnlocked': londonUnlocked,
      'intentionVessel': intentionVessel,
      'newtonRiddleAttempts': newtonRiddleAttempts,
      'newtonRiddleSolved': newtonRiddleSolved,
      'newtonExitAttempts': newtonExitAttempts,
      'newtonExitSolved': newtonExitSolved,
      'darwinConversationHad': darwinConversationHad,
      'darwinDefaultModeUnlocked': darwinDefaultModeUnlocked,
      'busyUntil': busyUntil,
      'pendingScene': pendingScene,
      'skips1h': skips1h,
      'skips3h': skips3h,
      'skips5h': skips5h,
      'isBetaTester': isBetaTester,

      'episodeHistories': episodeHistories,
      'episodeStartStates': episodeStartStates,
    };
  }

  Map<String, dynamic> toNestedJson() {
    final map = toJson();
    map.remove('episodeHistories');
    map.remove('episodeStartStates');
    return map;
  }

  factory GroveGameState.fromJson(Map<String, dynamic> json) {
    return GroveGameState(
      currentScene: json['currentScene'] as String? ?? 'ep0_intro',
      stability: json['stability'] as int? ?? 0,
      connectivity: json['connectivity'] as int? ?? 0,
      vitality: json['vitality'] as int? ?? 0,
      transience: json['transience'] as int? ?? 0,
      seedWarmth: json['seedWarmth'] as int? ?? 100,
      inventory: List<String>.from(json['inventory'] ?? []),
      chosenPath: json['chosenPath'] as String?,
      currentEpisode: json['currentEpisode'] as int? ?? 0,
      episodeComplete: json['episodeComplete'] as bool? ?? false,
      newtonUnlocked: json['newtonUnlocked'] as bool? ?? false,
      darwinUnlocked: json['darwinUnlocked'] as bool? ?? false,
      salixUnlocked: json['salixUnlocked'] as bool? ?? false,
      londonUnlocked: json['londonUnlocked'] as bool? ?? false,
      intentionVessel: json['intentionVessel'] as String?,
      newtonRiddleAttempts: json['newtonRiddleAttempts'] as int? ?? 0,
      newtonRiddleSolved: json['newtonRiddleSolved'] as bool? ?? false,
      newtonExitAttempts: json['newtonExitAttempts'] as int? ?? 0,
      newtonExitSolved: json['newtonExitSolved'] as bool? ?? false,
      darwinConversationHad: json['darwinConversationHad'] as bool? ?? false,
      darwinDefaultModeUnlocked:
          json['darwinDefaultModeUnlocked'] as bool? ?? false,
      busyUntil: json['busyUntil'] as int?,
      pendingScene: json['pendingScene'] as String?,
      skips1h: json['skips1h'] as int? ?? (json['skipTokens'] as int? ?? 0),
      skips3h: json['skips3h'] as int? ?? 0,
      skips5h: json['skips5h'] as int? ?? 0,
      isBetaTester: json['isBetaTester'] as bool? ?? false,
      episodeHistories: _parseHistories(json['episodeHistories']),
      episodeStartStates: _parseStartStates(json['episodeStartStates']),
    );
  }

  static Map<String, Map<String, dynamic>> _parseStartStates(dynamic data) {
    if (data == null) return {};
    final map = data as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
  }

  static Map<String, List<Map<String, dynamic>>> _parseHistories(dynamic data) {
    if (data == null) return {};
    final mapText = data as Map<String, dynamic>;
    return mapText.map((k, v) {
      final list = (v as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      return MapEntry(k, list);
    });
  }

  GroveGameState copyWith({
    String? currentScene,
    int? stability,
    int? connectivity,
    int? vitality,
    int? transience,
    int? seedWarmth,
    List<String>? inventory,
    String? chosenPath,
    int? currentEpisode,
    bool? episodeComplete,
    bool? newtonUnlocked,
    bool? darwinUnlocked,
    bool? salixUnlocked,
    bool? londonUnlocked,
    String? intentionVessel,
    int? newtonRiddleAttempts,
    bool? newtonRiddleSolved,
    int? newtonExitAttempts,
    bool? newtonExitSolved,
    bool? darwinConversationHad,
    bool? darwinDefaultModeUnlocked,
    int? busyUntil,
    String? pendingScene,
    int? skips1h,
    int? skips3h,
    int? skips5h,
    bool? isBetaTester,
    Map<String, List<Map<String, dynamic>>>? episodeHistories,
    Map<String, Map<String, dynamic>>? episodeStartStates,
  }) {
    return GroveGameState(
      currentScene: currentScene ?? this.currentScene,
      stability: stability ?? this.stability,
      connectivity: connectivity ?? this.connectivity,
      vitality: vitality ?? this.vitality,
      transience: transience ?? this.transience,
      seedWarmth: seedWarmth ?? this.seedWarmth,
      inventory: inventory ?? List.from(this.inventory),
      chosenPath: chosenPath ?? this.chosenPath,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      episodeComplete: episodeComplete ?? this.episodeComplete,
      newtonUnlocked: newtonUnlocked ?? this.newtonUnlocked,
      darwinUnlocked: darwinUnlocked ?? this.darwinUnlocked,
      salixUnlocked: salixUnlocked ?? this.salixUnlocked,
      londonUnlocked: londonUnlocked ?? this.londonUnlocked,
      intentionVessel: intentionVessel ?? this.intentionVessel,
      newtonRiddleAttempts: newtonRiddleAttempts ?? this.newtonRiddleAttempts,
      newtonRiddleSolved: newtonRiddleSolved ?? this.newtonRiddleSolved,
      newtonExitAttempts: newtonExitAttempts ?? this.newtonExitAttempts,
      newtonExitSolved: newtonExitSolved ?? this.newtonExitSolved,
      darwinConversationHad:
          darwinConversationHad ?? this.darwinConversationHad,
      darwinDefaultModeUnlocked:
          darwinDefaultModeUnlocked ?? this.darwinDefaultModeUnlocked,
      busyUntil: busyUntil ?? this.busyUntil,
      pendingScene: pendingScene ?? this.pendingScene,
      skips1h: skips1h ?? this.skips1h,
      skips3h: skips3h ?? this.skips3h,
      skips5h: skips5h ?? this.skips5h,
      isBetaTester: isBetaTester ?? this.isBetaTester,
      episodeHistories: episodeHistories ?? Map.from(this.episodeHistories),
      episodeStartStates:
          episodeStartStates ?? Map.from(this.episodeStartStates),
    );
  }
}

class GroveProgressService {
  static const _prefsKey = 'grove_game_state';
  static const _firestoreCollection = 'users';
  static const _firestoreField = 'grove_progress';

  static int? _lastSyncedSkips1h;
  static int? _lastSyncedSkips3h;
  static int? _lastSyncedSkips5h;

  static void _rememberSyncedSkips(GroveGameState state) {
    _lastSyncedSkips1h = state.skips1h;
    _lastSyncedSkips3h = state.skips3h;
    _lastSyncedSkips5h = state.skips5h;
  }

  static Map<String, FieldValue> _skipDeltaUpdates(GroveGameState state) {
    final updates = <String, FieldValue>{};

    if (_lastSyncedSkips1h == null ||
        _lastSyncedSkips3h == null ||
        _lastSyncedSkips5h == null) {
      return updates;
    }

    final delta1h = state.skips1h - _lastSyncedSkips1h!;
    final delta3h = state.skips3h - _lastSyncedSkips3h!;
    final delta5h = state.skips5h - _lastSyncedSkips5h!;

    if (delta1h != 0) {
      updates['$_firestoreField.skips1h'] = FieldValue.increment(delta1h);
    }
    if (delta3h != 0) {
      updates['$_firestoreField.skips3h'] = FieldValue.increment(delta3h);
    }
    if (delta5h != 0) {
      updates['$_firestoreField.skips5h'] = FieldValue.increment(delta5h);
    }

    return updates;
  }

  static Future<void> save(GroveGameState state) async {
    final json = state.toJson();
    final jsonString = jsonEncode(json);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('[GroveProgress] Local save error: $e');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final updates = {
          '$_firestoreField.currentScene': state.currentScene,
          '$_firestoreField.stability': state.stability,
          '$_firestoreField.connectivity': state.connectivity,
          '$_firestoreField.vitality': state.vitality,
          '$_firestoreField.transience': state.transience,
          '$_firestoreField.seedWarmth': state.seedWarmth,
          '$_firestoreField.inventory': state.inventory,
          '$_firestoreField.chosenPath': state.chosenPath,
          '$_firestoreField.currentEpisode': state.currentEpisode,
          '$_firestoreField.episodeComplete': state.episodeComplete,
          '$_firestoreField.newtonUnlocked': state.newtonUnlocked,
          '$_firestoreField.darwinUnlocked': state.darwinUnlocked,
          '$_firestoreField.salixUnlocked': state.salixUnlocked,
          '$_firestoreField.londonUnlocked': state.londonUnlocked,
          '$_firestoreField.busyUntil': state.busyUntil,
          '$_firestoreField.pendingScene': state.pendingScene,
          '$_firestoreField.isBetaTester': state.isBetaTester,

          'story_newton_unlocked': state.newtonUnlocked,
          'story_darwin_unlocked': state.darwinUnlocked,
          'story_salix_unlocked': state.salixUnlocked,
          'story_london_unlocked': state.londonUnlocked,
        };
        final skipUpdates = _skipDeltaUpdates(state);
        if (_lastSyncedSkips1h == null ||
            _lastSyncedSkips3h == null ||
            _lastSyncedSkips5h == null) {
          updates.addAll({
            '$_firestoreField.skips1h': state.skips1h,
            '$_firestoreField.skips3h': state.skips3h,
            '$_firestoreField.skips5h': state.skips5h,
          });
        } else {
          updates.addAll(skipUpdates);
        }

        FirebaseFirestore.instance
            .collection(_firestoreCollection)
            .doc(user.uid)
            .update(updates)
            .catchError((_) {
              final map = state.toNestedJson();
              return FirebaseFirestore.instance
                  .collection(_firestoreCollection)
                  .doc(user.uid)
                  .set({_firestoreField: map}, SetOptions(merge: true));
            });
        _rememberSyncedSkips(state);

        final cached = UserDocCache.getCached();
        if (cached != null) {
          final updated = Map<String, dynamic>.from(cached);
          final progress = Map<String, dynamic>.from(
            (updated[_firestoreField] as Map?) ?? {},
          );
          progress.addAll(state.toNestedJson());
          updated[_firestoreField] = progress;
          updated['story_newton_unlocked'] = state.newtonUnlocked;
          updated['story_darwin_unlocked'] = state.darwinUnlocked;
          updated['story_salix_unlocked'] = state.salixUnlocked;
          updated['story_london_unlocked'] = state.londonUnlocked;
          UserDocCache.update(updated);
        }
      } catch (e) {
        debugPrint('[GroveProgress] Firestore save error: $e');
      }
    }
  }

  static Future<GroveGameState?> load() async {
    final user = FirebaseAuth.instance.currentUser;
    GroveGameState? state;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        state = GroveGameState.fromJson(json);
      }
    } catch (e) {
      debugPrint('[GroveProgress] Local load error: $e');
    }

    if (user != null) {
      try {
        final data = await UserDocCache.get();

        if (data != null && data[_firestoreField] != null) {
          final cloudProgress = data[_firestoreField] as Map<String, dynamic>;
          final cloudState = GroveGameState.fromJson(cloudProgress);

          if (state != null) {
            state = cloudState.copyWith(
              episodeHistories: state.episodeHistories,
              episodeStartStates: state.episodeStartStates,
            );
          } else {
            state = cloudState;
          }
        }
      } catch (e) {
        debugPrint('[GroveProgress] Firestore load error: $e');
      }
    }

    if (state != null) {
      _rememberSyncedSkips(state);
    }

    return state;
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        FirebaseFirestore.instance
            .collection(_firestoreCollection)
            .doc(user.uid)
            .update({
              _firestoreField: FieldValue.delete(),
              'story_newton_unlocked': FieldValue.delete(),
              'story_darwin_unlocked': FieldValue.delete(),
              'story_salix_unlocked': FieldValue.delete(),
              'story_london_unlocked': FieldValue.delete(),
            }).catchError((_) {});

        FirebaseFirestore.instance
            .collection(_firestoreCollection)
            .doc(user.uid)
            .collection('grove_history')
            .get()
            .then((historyDocs) {
          for (final doc in historyDocs.docs) {
            doc.reference.delete();
          }
        }).catchError((_) {});

        _lastSyncedSkips1h = null;
        _lastSyncedSkips3h = null;
        _lastSyncedSkips5h = null;
        final cached = UserDocCache.getCached();
        if (cached != null) {
          final updated = Map<String, dynamic>.from(cached);
          updated.remove(_firestoreField);
          updated.remove('story_newton_unlocked');
          updated.remove('story_darwin_unlocked');
          updated.remove('story_salix_unlocked');
          updated.remove('story_london_unlocked');
          UserDocCache.update(updated);
        }
      } catch (_) {}
    }
  }

  static Future<GroveGameState> resetToEpisode(
    GroveGameState current,
    int episodeNumber,
  ) async {
    final epKey = 'ep$episodeNumber';

    final startStateJson = current.episodeStartStates[epKey];
    GroveGameState newState;

    if (startStateJson != null) {
      newState = GroveGameState.fromJson(startStateJson);

      newState.isBetaTester = current.isBetaTester;

      newState.episodeStartStates = Map.from(current.episodeStartStates);
    } else {
      final episode = groveEpisodes.firstWhere(
        (e) => e.number == episodeNumber,
      );
      final scenes = await episode.buildScenes();
      final initialScene = scenes.isNotEmpty
          ? scenes.first.id
          : 'ep${episodeNumber}_intro';

      newState = current.copyWith(
        currentEpisode: episodeNumber,
        currentScene: initialScene,
        episodeComplete: false,
        busyUntil: 0,
        pendingScene: null,
      );
    }

    if (episodeNumber <= 3) {
      newState.londonUnlocked = false;
      newState.inventory.remove('Mossy Residue');
      newState.inventory.remove('Warming Pouch');
      newState.inventory.remove("Loulo's Pot");
      newState.intentionVessel = null;
    }
    if (episodeNumber <= 2) {
      newState.salixUnlocked = false;
      newState.inventory.remove('Flask of Tears');
    }
    if (episodeNumber <= 1) {
      newState.newtonUnlocked = false;
      newState.darwinUnlocked = false;
      newState.chosenPath = null;
      newState.inventory.remove('iJuice Premium™');
      newState.inventory.remove('iJuice Plus™');
      newState.inventory.remove('Apple Juice');
      newState.inventory.remove('Custom Orange Juice');
      newState.inventory.remove('Orange Juice');
      newState.inventory.remove('Cool Rock');
    }

    for (int i = episodeNumber; i <= 10; i++) {
      newState.episodeHistories.remove('ep$i');
      if (i > episodeNumber) {
        newState.episodeStartStates.remove('ep$i');
      }
    }

    await save(newState);
    return newState;
  }

  static Future<void> unlockProfilePicture(String key) async {
    final field = 'story_${key}_unlocked';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(user.uid)
          .set({field: true}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[GroveProgress] Unlock PFP error: $e');
    }
  }

  static Future<void> lockProfilePicture(String key) async {
    final field = 'story_${key}_unlocked';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(user.uid)
          .set({field: false}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[GroveProgress] Lock PFP error: $e');
    }
  }

  static Future<bool> isProfilePictureUnlocked(String key) async {
    final field = 'story_${key}_unlocked';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_firestoreCollection)
          .doc(user.uid)
          .get();
      return (doc.data()?[field] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }
}
