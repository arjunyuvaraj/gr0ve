import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:gr0ve/features/account/services/dawn_unlock_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/grove/grove_progress_service.dart';

// ─────────────────────────────────────────────────────────────
// PROFILE VARIANT MODEL
// ─────────────────────────────────────────────────────────────

class ProfileVariant {
  final String key;
  final CounselorPersona persona;

  const ProfileVariant({required this.key, required this.persona});

  /// Display name shown in the picker — capitalizes each word
  String get displayName => key
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Brightness-aware asset path.
  String assetPath(Brightness brightness) {
    final mode = brightness == Brightness.dark ? 'dark' : 'light';
    if (key == 'dawn') {
      return 'assets/app_icons/png/dawn_$mode.png';
    }
    // Story reward characters
    if (key == 'newton' || key == 'darwin') {
      return 'assets/app_icons/png/${key}_$mode.png';
    }
    // Use app icons for hidden personas' default PFPs
    if (persona.isHidden && isDefault) {
      return 'assets/app_icons/png/${persona.name}_$mode.png';
    }
    return 'assets/profile/${persona.name}/${persona.name}_${mode}_$key.png';
  }

  bool get isDefault => key == 'default';

  /// Stable unique ID across all counselors — used as the Firestore key.
  String get id => '${persona.name}__$key';
}

// ─────────────────────────────────────────────────────────────
// GLOBAL VARIANTS REGISTRY
// Every variant across every counselor lives here.
// Hidden-counselor variants are gated behind unlock state.
// ─────────────────────────────────────────────────────────────

const List<ProfileVariant> _allVariants = [
  // Grover
  ProfileVariant(key: 'default', persona: CounselorPersona.grover),
  ProfileVariant(key: 'winter', persona: CounselorPersona.grover),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.grover),
  // Aspen
  ProfileVariant(key: 'default', persona: CounselorPersona.aspen),
  ProfileVariant(key: 'summer', persona: CounselorPersona.aspen),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.aspen),
  // Rowan
  ProfileVariant(key: 'default', persona: CounselorPersona.rowan),
  ProfileVariant(key: 'autumn', persona: CounselorPersona.rowan),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.rowan),
  // Sakura
  ProfileVariant(key: 'default', persona: CounselorPersona.sakura),
  ProfileVariant(key: 'spring', persona: CounselorPersona.sakura),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.sakura),
  // Hidden counselors — only default shown until unlocked
  ProfileVariant(key: 'default', persona: CounselorPersona.abies),
  ProfileVariant(key: 'default', persona: CounselorPersona.cedite),
  ProfileVariant(key: 'default', persona: CounselorPersona.ash),
  // Special
  ProfileVariant(key: 'dawn', persona: CounselorPersona.grover),
  // Story rewards
  ProfileVariant(key: 'newton', persona: CounselorPersona.grover),
  ProfileVariant(key: 'darwin', persona: CounselorPersona.grover),
];

/// All variants the user is currently allowed to see.
List<ProfileVariant> get availableVariants => _allVariants.where((v) {
  if (v.key == 'dawn') {
    return DawnUnlockService.isUnlocked.value;
  }
  // Story reward gating — check cached unlock status
  if (v.key == 'newton' || v.key == 'darwin') {
    return _storyUnlocks[v.key] ?? false;
  }
  if (v.persona.isHidden &&
      !CounselorPersonaService.isPersonaUnlocked(v.persona)) {
    return false; // completely hide if locked
  }
  return true;
}).toList();

/// Cached story unlock status (populated during init)
Map<String, bool> _storyUnlocks = {};

/// Update story unlock cache at runtime (call after unlocking a story PFP)
void markStoryPfpUnlocked(String key) {
  _storyUnlocks[key] = true;
}

/// Helper to lock story PFP at runtime (used when resetting progress)
void lockStoryPfp(String key) {
  _storyUnlocks[key] = false;
}

// ─────────────────────────────────────────────────────────────
// PROFILE PICTURE SERVICE
// ─────────────────────────────────────────────────────────────

class ProfilePictureService {
  static const _firestoreField =
      'selected_profile_picture'; // stores variant ID

  /// The variant the user has chosen — counselor-agnostic.
  static final ValueNotifier<ProfileVariant> activeVariant =
      ValueNotifier<ProfileVariant>(defaultVariant);

  static ProfileVariant get defaultVariant => _allVariants.firstWhere(
    (v) => v.persona == CounselorPersona.grover && v.isDefault,
  );

  // ── Init ────────────────────────────────────────────────────

  static Future<void> init({Map<String, dynamic>? cachedUserData}) async {
    debugPrint('[ProfilePictureService] Initializing...');
    await _loadStoryUnlocks(cachedUserData: cachedUserData);
    await _loadFromFirestore(cachedUserData: cachedUserData);
  }

  /// Load story unlock status from cached user doc
  static Future<void> _loadStoryUnlocks({Map<String, dynamic>? cachedUserData}) async {
    final data = cachedUserData ?? await UserDocCache.get();
    for (final key in ['newton', 'darwin']) {
      final field = 'story_${key}_unlocked';
      _storyUnlocks[key] = (data?[field] as bool?) ?? false;
    }
  }

  // ── Public API ───────────────────────────────────────────────

  /// Sets any variant regardless of active counselor, persists to Firestore.
  static Future<void> setVariant(ProfileVariant variant) async {
    activeVariant.value = variant;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Sync with photoURL for compatibility (using light mode asset as default)
      try {
        await user.updatePhotoURL(variant.assetPath(Brightness.light));
      } catch (_) {}
    }
    await _persistToFirestore(variant);
  }

  /// Convenience: resolve asset path for the current theme brightness.
  static String activePath(Brightness brightness) =>
      activeVariant.value.assetPath(brightness);

  // ── Firestore ────────────────────────────────────────────────

  static Future<void> _loadFromFirestore({Map<String, dynamic>? cachedUserData}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final data = cachedUserData ?? await UserDocCache.get();
      final id = data?[_firestoreField] as String?;
      if (id != null) {
        final match = _allVariants.where((v) => v.id == id).firstOrNull;
        if (match != null) {
          debugPrint('[ProfilePictureService] Loaded variant: ${match.id}');
          activeVariant.value = match;

          // Defer photoURL sync — don't block boot for this
          if (user.photoURL != match.assetPath(Brightness.light)) {
            user.updatePhotoURL(match.assetPath(Brightness.light)).catchError((_) {});
          }

          if (match.persona.isHidden &&
              !CounselorPersonaService.isPersonaUnlocked(match.persona)) {
            // Fallback to grover default if unlocked persona was removed
            activeVariant.value = _allVariants.firstWhere(
              (v) => v.persona == CounselorPersona.grover && v.isDefault,
            );
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> _persistToFirestore(ProfileVariant variant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        _firestoreField: variant.id, // Save stable ID, not theme-specific path
        'active_counselor_persona': variant.persona.name,
        'active_profile_variant': variant.key,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
