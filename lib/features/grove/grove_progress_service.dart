import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

// ─────────────────────────────────────────────────────────────
// GROVE GAME STATE
// ─────────────────────────────────────────────────────────────

class GroveGameState {
  String currentScene;
  int stability;
  int connectivity;
  int vitality;
  int transience;
  int seedWarmth;
  List<String> inventory;
  String? chosenPath; // 'apple' or 'orange'
  int currentEpisode;
  bool episodeComplete;
  bool newtonUnlocked;
  bool darwinUnlocked;
  int? busyUntil; // epoch milliseconds
  String? pendingScene; // Scene to load once busyUntil expires
  int skips1h; // 1-hour skips
  int skips3h; // 3-hour skips
  int skips5h; // 5-hour skips
  // Steve path tracking
  int newtonRiddleAttempts;
  bool newtonRiddleSolved;
  int newtonExitAttempts;
  bool newtonExitSolved;

  // Andy path tracking
  bool darwinConversationHad;
  bool darwinDefaultModeUnlocked;

  // History tracking log
  Map<String, List<Map<String, dynamic>>> episodeHistories;

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
    Map<String, List<Map<String, dynamic>>>? episodeHistories,
  })  : inventory = inventory ?? [],
        episodeHistories = episodeHistories ?? {};

  Map<String, dynamic> toJson() => {
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
    'episodeHistories': episodeHistories,
  };

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
      newtonRiddleAttempts: json['newtonRiddleAttempts'] as int? ?? 0,
      newtonRiddleSolved: json['newtonRiddleSolved'] as bool? ?? false,
      newtonExitAttempts: json['newtonExitAttempts'] as int? ?? 0,
      newtonExitSolved: json['newtonExitSolved'] as bool? ?? false,
      darwinConversationHad: json['darwinConversationHad'] as bool? ?? false,
      darwinDefaultModeUnlocked:
          json['darwinDefaultModeUnlocked'] as bool? ?? false,
      busyUntil: json['busyUntil'] as int?,
      pendingScene: json['pendingScene'] as String?,
      skips1h: json['skips1h'] as int? ?? (json['skipTokens'] as int? ?? 0), // Migrate old tokens
      skips3h: json['skips3h'] as int? ?? 0,
      skips5h: json['skips5h'] as int? ?? 0,
      episodeHistories: _parseHistories(json['episodeHistories']),
    );
  }

  static Map<String, List<Map<String, dynamic>>> _parseHistories(dynamic data) {
    if (data == null) return {};
    final mapText = data as Map<String, dynamic>;
    return mapText.map((k, v) {
      final list = (v as List).map((e) => Map<String, dynamic>.from(e)).toList();
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
    Map<String, List<Map<String, dynamic>>>? episodeHistories,
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
      newtonRiddleAttempts: newtonRiddleAttempts ?? this.newtonRiddleAttempts,
      newtonRiddleSolved: newtonRiddleSolved ?? this.newtonRiddleSolved,
      newtonExitAttempts: newtonExitAttempts ?? this.newtonExitAttempts,
      newtonExitSolved: newtonExitSolved ?? this.newtonExitSolved,
      darwinConversationHad: darwinConversationHad ?? this.darwinConversationHad,
      darwinDefaultModeUnlocked:
          darwinDefaultModeUnlocked ?? this.darwinDefaultModeUnlocked,
      busyUntil: busyUntil ?? this.busyUntil,
      pendingScene: pendingScene ?? this.pendingScene,
      skips1h: skips1h ?? this.skips1h,
      skips3h: skips3h ?? this.skips3h,
      skips5h: skips5h ?? this.skips5h,
      episodeHistories: episodeHistories ?? Map.from(this.episodeHistories),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GROVE PROGRESS SERVICE
// ─────────────────────────────────────────────────────────────

class GroveProgressService {
  static const _prefsKey = 'grove_game_state';
  static const _firestoreCollection = 'users';
  static const _firestoreField = 'grove_progress';

  /// Save game state to both SharedPreferences and Firestore
  static Future<void> save(GroveGameState state) async {
    final json = state.toJson();
    final jsonString = jsonEncode(json);

    // Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      debugPrint('[GroveProgress] Local save error: $e');
    }

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(_firestoreCollection)
            .doc(user.uid)
            .set({_firestoreField: json}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[GroveProgress] Firestore save error: $e');
      }
    }
  }

  /// Load game state — tries Firestore first, falls back to local
  static Future<GroveGameState?> load() async {
    final user = FirebaseAuth.instance.currentUser;

    // Try Firestore first via cache to prevent redundant network calls
    if (user != null) {
      try {
        final data = await UserDocCache.get();
        if (data != null && data[_firestoreField] != null) {
          final progress = data[_firestoreField] as Map<String, dynamic>;
          return GroveGameState.fromJson(progress);
        }
      } catch (e) {
        debugPrint('[GroveProgress] Firestore cache load error: $e');
      }
    }

    // Fall back to local
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return GroveGameState.fromJson(json);
      }
    } catch (e) {
      debugPrint('[GroveProgress] Local load error: $e');
    }

    return null;
  }

  /// Clear saved progress (for reset/debug)
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection(_firestoreCollection)
            .doc(user.uid)
            .update({
              _firestoreField: FieldValue.delete(),
              'story_newton_unlocked': FieldValue.delete(),
              'story_darwin_unlocked': FieldValue.delete(),
            });
      } catch (_) {}
    }
  }

  /// Mark a story profile picture as unlocked in Firestore
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

  /// Check if a story profile picture is unlocked
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
