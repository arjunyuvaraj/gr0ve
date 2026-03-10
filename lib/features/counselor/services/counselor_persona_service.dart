// counselor_persona_service.dart
//
// REFACTOR NOTES:
// - Trees are now tone-only; functional behavior is identical across personas.
// - Academy determines the default persona on first load.
// - Persona switching is hidden (not surfaced in main UI); accessible via
//   a discoverable toggle in Settings only.
// - Ash and Cedite are gated behind TWO-LAYER unlock:
//   1. Global flag in app_config/feature_flags (ash_unlocked / cedite_unlocked)
//   2. Per-user flag in user document (ash_unlocked / cedite_unlocked)
//   Both must be true for the persona to appear.
// - Abies retains its existing easter-egg unlock flow (FrozenLake passphrase).
// - Chime-in queue logic has been removed from this file entirely.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_dynamic_launcher_icon/flutter_dynamic_launcher_icon.dart';

enum CounselorPersona { grover, aspen, rowan, sakura, abies, cedite, ash }

extension CounselorPersonaExtension on CounselorPersona {
  String get id => name;

  // Hidden = requires an explicit unlock before it appears anywhere in the UI.
  bool get isHidden => switch (this) {
    CounselorPersona.abies => true,
    CounselorPersona.cedite => true,
    CounselorPersona.ash => true,
    _ => false,
  };

  String get displayName => switch (this) {
    CounselorPersona.grover => 'Grover',
    CounselorPersona.aspen => 'Aspen',
    CounselorPersona.rowan => 'Rowan',
    CounselorPersona.sakura => 'Sakura',
    CounselorPersona.abies => 'Abies',
    CounselorPersona.cedite => 'Cedite',
    CounselorPersona.ash => 'Ash',
  };

  // Specialty label — display only, no functional routing.
  String get specialtyLabel => switch (this) {
    CounselorPersona.grover => 'College',
    CounselorPersona.aspen => 'Research',
    CounselorPersona.rowan => 'IB',
    CounselorPersona.sakura => 'Art Credits',
    CounselorPersona.abies => 'Memory',
    CounselorPersona.cedite => 'Connections',
    CounselorPersona.ash => 'Clarity',
  };

  List<String> get defaultAcademies => switch (this) {
    CounselorPersona.grover => ['ATCS', 'AEDT'],
    CounselorPersona.aspen => ['AAST', 'AMST'],
    CounselorPersona.rowan => ['ABF', 'ACAHA'],
    CounselorPersona.sakura => ['AVPA'],
    _ => [],
  };

  // ── Colors (unchanged) ────────────────────────────────────────────────────

  Color get primaryLight => switch (this) {
    CounselorPersona.grover => const Color(0xFF1F6F5B),
    CounselorPersona.aspen => const Color(0xFFFFC200),
    CounselorPersona.rowan => const Color(0xFFAD3800),
    CounselorPersona.sakura => const Color(0xFFDC8FE8),
    CounselorPersona.abies => const Color(0xFF00C8FF),
    CounselorPersona.cedite => const Color(0xFF7B2FBE),
    CounselorPersona.ash => const Color(0xFFB61C1C),
  };

  Color get primaryDark => switch (this) {
    CounselorPersona.grover => const Color(0xFF35B595),
    CounselorPersona.aspen => const Color(0xFFFFDD71),
    CounselorPersona.rowan => const Color(0xFFFF6F2A),
    CounselorPersona.sakura => const Color(0xFFEEC3F5),
    CounselorPersona.abies => const Color(0xFF00C8FF),
    CounselorPersona.cedite => const Color(0xFFB47EE5),
    CounselorPersona.ash => const Color(0xFFB61C1C),
  };

  Color primary(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  Color get onPrimaryLight => switch (this) {
    CounselorPersona.aspen => const Color(0xFF1A1D1F),
    CounselorPersona.sakura => const Color(0xFF1A1D1F),
    _ => Colors.white,
  };

  Color get onPrimaryDark => switch (this) {
    CounselorPersona.aspen => const Color(0xFF1A1D1F),
    CounselorPersona.sakura => const Color(0xFF1A1D1F),
    CounselorPersona.abies => const Color(0xFF1A1D1F),
    CounselorPersona.cedite => const Color(0xFF1A1D1F),
    _ => Colors.white,
  };

  Color onPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? onPrimaryDark : onPrimaryLight;

  String get avatarLightAsset => 'assets/app_icons/png/${id}_light.png';
  String get avatarDarkAsset => 'assets/app_icons/png/${id}_dark.png';
  String avatarAsset(Brightness brightness) =>
      brightness == Brightness.dark ? avatarDarkAsset : avatarLightAsset;

  String? get iosIconName => switch (this) {
    CounselorPersona.grover => null,
    CounselorPersona.aspen => 'aspen',
    CounselorPersona.rowan => 'rowan',
    CounselorPersona.sakura => 'sakura',
    CounselorPersona.abies => 'abies',
    CounselorPersona.cedite => 'cedite',
    CounselorPersona.ash => 'ash',
  };

  String get androidAlias => switch (this) {
    CounselorPersona.grover => 'MainActivityGrover',
    CounselorPersona.aspen => 'MainActivityAspen',
    CounselorPersona.rowan => 'MainActivityRowan',
    CounselorPersona.sakura => 'MainActivitySakura',
    CounselorPersona.abies => 'MainActivityAbies',
    CounselorPersona.cedite => 'MainActivityCedite',
    CounselorPersona.ash => 'MainActivityAsh',
  };

  // personalityPrompt is still present in persona_voice.dart (tone layer).
  // Functional system prompt lives in OllamaCounselorService._sharedRules().
}

// ─────────────────────────────────────────────────────────────────────────────
// FEATURE FLAGS  —  TWO-LAYER UNLOCK
//
// Ash and Cedite require BOTH:
// 1. Global flag in app_config/feature_flags (developer controls feature availability)
// 2. Per-user flag in user document (user earns the unlock via specific actions)
//
// Abies still uses per-user unlock only (FrozenLake passphrase).
// ─────────────────────────────────────────────────────────────────────────────

class AppFeatureFlags {
  AppFeatureFlags._();

  // Global flags (from app_config/feature_flags)
  static bool _ashUnlockedGlobal = false;
  static bool _cediteUnlockedGlobal = false;

  // Per-user flags (from user document)
  static bool _ashUnlockedUser = false;
  static bool _cediteUnlockedUser = false;

  // Both must be true for the persona to be visible
  static bool get ashUnlocked => _ashUnlockedGlobal && _ashUnlockedUser;
  static bool get cediteUnlocked =>
      _cediteUnlockedGlobal && _cediteUnlockedUser;

  /// Call once during app initialization (before CounselorPersonaService.init).
  /// Loads GLOBAL flags from app_config/feature_flags.
  static Future<void> load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('feature_flags')
          .get();
      final data = doc.data() ?? {};
      _ashUnlockedGlobal = (data['ash_unlocked'] as bool?) ?? false;
      _cediteUnlockedGlobal = (data['cedite_unlocked'] as bool?) ?? false;
    } catch (_) {
      // Default to locked if Firestore is unreachable.
      _ashUnlockedGlobal = false;
      _cediteUnlockedGlobal = false;
    }
  }

  /// Load per-user unlocks from user document.
  /// Call this from CounselorPersonaService.load() after user is authenticated.
  static Future<void> loadUserUnlocks(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      _ashUnlockedUser = (data['ash_unlocked'] as bool?) ?? false;
      _cediteUnlockedUser = (data['cedite_unlocked'] as bool?) ?? false;
    } catch (_) {
      _ashUnlockedUser = false;
      _cediteUnlockedUser = false;
    }
  }

  /// Mark Ash as unlocked for current user (called when user earns it).
  static Future<void> markAshUnlocked(String uid) async {
    _ashUnlockedUser = true;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'ash_unlocked': true,
      });
    } catch (_) {}
  }

  /// Mark Cedite as unlocked for current user (called when user earns it).
  static Future<void> markCediteUnlocked(String uid) async {
    _cediteUnlockedUser = true;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'cedite_unlocked': true,
      });
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COUNSELOR PERSONA SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class CounselorPersonaService {
  CounselorPersonaService._();

  static final ValueNotifier<CounselorPersona> activePersona =
      ValueNotifier<CounselorPersona>(CounselorPersona.grover);

  static const _personaField = 'counselor_persona';
  static const _abiesUnlockedField = 'abies_unlocked';

  static const _iconChannel = MethodChannel('com.gr0ve.app/icon');

  // Per-user Abies unlock (earned via FrozenLake easter egg).
  static bool _abiesUnlocked = false;
  static bool get abiesUnlocked => _abiesUnlocked;

  // Ash / Cedite are gated via AppFeatureFlags (both global + per-user).
  // These getters delegate to AppFeatureFlags which checks both layers.
  static bool get cediteUnlocked => AppFeatureFlags.cediteUnlocked;
  static bool get ashUnlocked => AppFeatureFlags.ashUnlocked;

  static CounselorPersona _fromString(String? s) => CounselorPersona.values
      .firstWhere((p) => p.id == s, orElse: () => CounselorPersona.grover);

  static bool _isUnlocked(CounselorPersona p) => switch (p) {
    CounselorPersona.abies => _abiesUnlocked,
    CounselorPersona.cedite => AppFeatureFlags.cediteUnlocked,
    CounselorPersona.ash => AppFeatureFlags.ashUnlocked,
    _ => true,
  };

  static bool isPersonaUnlocked(CounselorPersona p) => _isUnlocked(p);

  /// Maps a student's academy string to their default persona.
  /// This is the ONLY automatic persona assignment in the refactored flow.
  static CounselorPersona defaultForAcademy(String? academy) {
    if (academy == null) return CounselorPersona.grover;
    final a = academy.toUpperCase().trim();
    if (a.contains('ATCS') || a.contains('AEDT'))
      return CounselorPersona.grover;
    if (a.contains('AAST') || a.contains('AMST')) return CounselorPersona.aspen;
    if (a.contains('ABF') || a.contains('ACAHA')) return CounselorPersona.rowan;
    if (a.contains('AVPA')) return CounselorPersona.sakura;
    return CounselorPersona.grover;
  }

  /// All personas visible to the current user in the hidden picker.
  /// Normal UI should NOT expose this list — it is only for the
  /// hidden Settings toggle and the easter-egg unlock flow.
  static List<CounselorPersona> get availablePersonas =>
      CounselorPersona.values.where((p) {
        if (p.isHidden) return _isUnlocked(p);
        return true;
      }).toList();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Must be called after AppFeatureFlags.load().
  static Future<void> init() async {
    final persona = await load();
    activePersona.value = persona;
  }

  static Future<CounselorPersona> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return CounselorPersona.grover;
    try {
      // Load per-user unlocks for Ash and Cedite
      await AppFeatureFlags.loadUserUnlocks(user.uid);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();

      // Abies unlock is per-user only (not two-layer).
      _abiesUnlocked = (data?[_abiesUnlockedField] as bool?) ?? false;

      if (data?[_personaField] != null) {
        final saved = _fromString(data![_personaField] as String?);
        if (saved.isHidden && !_isUnlocked(saved)) {
          return defaultForAcademy(data['academy'] as String?);
        }
        return saved;
      }
      return defaultForAcademy(data?['academy'] as String?);
    } catch (_) {
      return CounselorPersona.grover;
    }
  }

  static Future<void> setPersona(CounselorPersona persona) async {
    if (persona.isHidden && !_isUnlocked(persona)) return;
    activePersona.value = persona;
    await Future.wait([_persistToFirestore(persona), _syncAppIcon(persona)]);
  }

  static void markAbiesUnlocked() => _abiesUnlocked = true;

  /// Mark Ash as unlocked for the current user.
  static Future<void> markAshUnlocked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await AppFeatureFlags.markAshUnlocked(uid);
  }

  /// Mark Cedite as unlocked for the current user.
  static Future<void> markCediteUnlocked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await AppFeatureFlags.markCediteUnlocked(uid);
  }

  static Future<void> _persistToFirestore(CounselorPersona persona) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {_personaField: persona.id},
      );
    } catch (_) {}
  }

  static Future<void> _syncAppIcon(CounselorPersona persona) async {
    await Future.wait([_syncIosIcon(persona), _syncAndroidIcon(persona)]);
  }

  static Future<void> _syncIosIcon(CounselorPersona persona) async {
    if (!Platform.isIOS) return;
    try {
      final supported = await FlutterDynamicLauncherIcon.isSupported;
      if (!supported) return;
      final current = await FlutterDynamicIcon.getAlternateIconName();
      if (current == persona.iosIconName) return;
      await FlutterDynamicLauncherIcon.changeIcon(persona.iosIconName);
    } catch (_) {}
  }

  static Future<void> _syncAndroidIcon(CounselorPersona persona) async {
    try {
      await _iconChannel.invokeMethod<void>('setIcon', {
        'alias': persona.androidAlias,
      });
    } on PlatformException {
      /* ignore */
    } on MissingPluginException {
      /* ignore */
    }
  }
}
