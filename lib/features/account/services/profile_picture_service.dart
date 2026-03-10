import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

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
];

/// All variants the user is currently allowed to see.
List<ProfileVariant> get availableVariants => _allVariants.where((v) {
  if (v.persona.isHidden &&
      !CounselorPersonaService.isPersonaUnlocked(v.persona)) {
    return v.isDefault; // only show default until hidden counselor unlocked
  }
  return true;
}).toList();

// ─────────────────────────────────────────────────────────────
// PROFILE PICTURE SERVICE
// ─────────────────────────────────────────────────────────────

class ProfilePictureService {
  static const _firestoreField = 'selected_profile_picture'; // single string id

  /// The variant the user has chosen — counselor-agnostic.
  static final ValueNotifier<ProfileVariant> activeVariant =
      ValueNotifier<ProfileVariant>(
        _allVariants.firstWhere(
          (v) => v.persona == CounselorPersona.grover && v.isDefault,
        ),
      );

  // ── Init ────────────────────────────────────────────────────

  static Future<void> init() async {
    await _loadFromFirestore();
  }

  // ── Public API ───────────────────────────────────────────────

  /// Sets any variant regardless of active counselor, persists to Firestore.
  static Future<void> setVariant(ProfileVariant variant) async {
    activeVariant.value = variant;
    await _persistToFirestore(variant);
  }

  /// Convenience: resolve asset path for the current theme brightness.
  static String activePath(Brightness brightness) =>
      activeVariant.value.assetPath(brightness);

  // ── Firestore ────────────────────────────────────────────────

  static Future<void> _loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final id = doc.data()?[_firestoreField] as String?;
      if (id != null) {
        final match = _allVariants.where((v) => v.id == id).firstOrNull;
        if (match != null) activeVariant.value = match;
      }
    } catch (_) {}
  }

  static Future<void> _persistToFirestore(ProfileVariant variant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        _firestoreField: variant.id,
        // Keep active_profile_picture in sync for social search
        'active_profile_picture': variant.assetPath(Brightness.light),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
