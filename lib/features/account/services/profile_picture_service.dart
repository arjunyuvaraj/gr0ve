import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:gr0ve/features/account/services/dawn_unlock_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

class ProfileVariant {
  final String key;
  final CounselorPersona persona;

  const ProfileVariant({required this.key, required this.persona});

  String get displayName {
    if (persona.isHidden && isDefault) {
      return '${persona.name[0].toUpperCase()}${persona.name.substring(1)}';
    }
    return key
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String assetPath(Brightness brightness) {
    final mode = brightness == Brightness.dark ? 'dark' : 'light';
    if (key == 'dawn') {
      return 'assets/app_icons/png/dawn_$mode.png';
    }

    if (key == 'newton' ||
        key == 'darwin' ||
        key == 'london' ||
        key == 'salix') {
      if (key == 'london') {
        return 'assets/story/characters/ep3/london_$mode.png';
      }
      if (key == 'salix') {
        return 'assets/story/characters/ep2/salix_$mode.png';
      }
      return 'assets/story/characters/ep1/${key}_$mode.png';
    }

    if ((persona.name == 'ash' || persona.name == 'cedite') && isDefault) {
      return 'assets/profile/${persona.name}/${persona.name}_$mode.png';
    }

    if (key.startsWith('academy_')) {
      final academy = key.replaceFirst('academy_', '');
      return 'assets/profile/academy/${academy}_$mode.png';
    }

    return 'assets/profile/${persona.name}/${persona.name}_${mode}_$key.png';
  }

  bool get isDefault => key == 'default';

  String get id => '${persona.name}__$key';
}

const List<ProfileVariant> _allVariants = [
  ProfileVariant(key: 'default', persona: CounselorPersona.grover),
  ProfileVariant(key: 'winter', persona: CounselorPersona.grover),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.grover),

  ProfileVariant(key: 'default', persona: CounselorPersona.aspen),
  ProfileVariant(key: 'summer', persona: CounselorPersona.aspen),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.aspen),

  ProfileVariant(key: 'default', persona: CounselorPersona.rowan),
  ProfileVariant(key: 'autumn', persona: CounselorPersona.rowan),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.rowan),

  ProfileVariant(key: 'default', persona: CounselorPersona.sakura),
  ProfileVariant(key: 'spring', persona: CounselorPersona.sakura),
  ProfileVariant(key: 'pixel', persona: CounselorPersona.sakura),

  ProfileVariant(key: 'default', persona: CounselorPersona.abies),
  ProfileVariant(key: 'default', persona: CounselorPersona.cedite),
  ProfileVariant(key: 'default', persona: CounselorPersona.ash),

  ProfileVariant(key: 'dawn', persona: CounselorPersona.grover),

  ProfileVariant(key: 'newton', persona: CounselorPersona.grover),
  ProfileVariant(key: 'darwin', persona: CounselorPersona.grover),
  ProfileVariant(key: 'salix', persona: CounselorPersona.grover),
  ProfileVariant(key: 'london', persona: CounselorPersona.grover),

  ProfileVariant(key: 'academy_atcs', persona: CounselorPersona.grover),
  ProfileVariant(key: 'academy_aedt', persona: CounselorPersona.grover),
  ProfileVariant(key: 'academy_amst', persona: CounselorPersona.aspen),
  ProfileVariant(key: 'academy_aast', persona: CounselorPersona.aspen),
  ProfileVariant(key: 'academy_abf', persona: CounselorPersona.rowan),
  ProfileVariant(key: 'academy_acaha', persona: CounselorPersona.rowan),
  ProfileVariant(key: 'academy_avpa', persona: CounselorPersona.sakura),
];

List<ProfileVariant> get availableVariants => _allVariants.where((v) {
  if (v.key == 'dawn') {
    return DawnUnlockService.isUnlocked.value;
  }

  if (v.key == 'newton' ||
      v.key == 'darwin' ||
      v.key == 'salix' ||
      v.key == 'london') {
    return _storyUnlocks[v.key] ?? false;
  }
  if (v.persona.isHidden &&
      !CounselorPersonaService.isPersonaUnlocked(v.persona)) {
    return false;
  }
  return true;
}).toList();

Map<String, bool> _storyUnlocks = {};

void markStoryPfpUnlocked(String key) {
  _storyUnlocks[key] = true;
}

void lockStoryPfp(String key) {
  _storyUnlocks[key] = false;
}

class ProfilePictureService {
  static const _firestoreField = 'selected_profile_picture';

  static final ValueNotifier<ProfileVariant> activeVariant =
      ValueNotifier<ProfileVariant>(defaultVariant);

  static ProfileVariant get defaultVariant => _allVariants.firstWhere(
    (v) => v.persona == CounselorPersona.grover && v.isDefault,
  );

  static Future<void> init({Map<String, dynamic>? cachedUserData}) async {
    debugPrint('[ProfilePictureService] Initializing...');
    await _loadStoryUnlocks(cachedUserData: cachedUserData);
    await _loadFromFirestore(cachedUserData: cachedUserData);
  }

  static Future<void> _loadStoryUnlocks({
    Map<String, dynamic>? cachedUserData,
  }) async {
    final data = cachedUserData ?? await UserDocCache.get();
    for (final key in ['newton', 'darwin', 'salix', 'london']) {
      final field = 'story_${key}_unlocked';
      _storyUnlocks[key] = (data?[field] as bool?) ?? false;
    }
  }

  static Future<void> setVariant(ProfileVariant variant) async {
    activeVariant.value = variant;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.updatePhotoURL(variant.assetPath(Brightness.light));
      } catch (_) {}
    }
    await _persistToFirestore(variant);
  }

  static String activePath(Brightness brightness) =>
      activeVariant.value.assetPath(brightness);

  static Future<void> _loadFromFirestore({
    Map<String, dynamic>? cachedUserData,
  }) async {
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

          if (user.photoURL != match.assetPath(Brightness.light)) {
            user
                .updatePhotoURL(match.assetPath(Brightness.light))
                .catchError((_) {});
          }

          if (match.persona.isHidden &&
              !CounselorPersonaService.isPersonaUnlocked(match.persona)) {
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
        _firestoreField: variant.id,
        'active_counselor_persona': variant.persona.name,
        'active_profile_variant': variant.key,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
