import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'dart:io' as io;

enum CounselorPersona { grover, aspen, rowan, sakura, abies, cedite, ash }

extension CounselorPersonaExtension on CounselorPersona {
  String get id => name;

  bool get isHidden => switch (this) {
    CounselorPersona.abies ||
    CounselorPersona.cedite ||
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

  String get specialtyLabel => switch (this) {
    CounselorPersona.grover => 'ATCS & AEDT',
    CounselorPersona.aspen => 'AAST & AMST',
    CounselorPersona.rowan => 'ABF & ACAHA',
    CounselorPersona.sakura => 'AVPA',
    CounselorPersona.abies => 'Memory',
    CounselorPersona.cedite => 'Truth',
    CounselorPersona.ash => 'Future',
  };

  List<String> get defaultAcademies => switch (this) {
    CounselorPersona.grover => ['ATCS', 'AEDT'],
    CounselorPersona.aspen => ['AAST', 'AMST'],
    CounselorPersona.rowan => ['ABF', 'ACAHA'],
    CounselorPersona.sakura => ['AVPA'],
    CounselorPersona.abies => [],
    CounselorPersona.cedite => [],
    CounselorPersona.ash => [],
  };

  Color get primaryLight => switch (this) {
    CounselorPersona.grover => const Color(0xFF1F6F5B),
    CounselorPersona.aspen => const Color(0xFFFFC200),
    CounselorPersona.rowan => const Color(0xFFAD3800),
    CounselorPersona.sakura => const Color(0xFFDC8FE8),
    CounselorPersona.abies => const Color(0xFF00C8FF),
    CounselorPersona.cedite => const Color(0xFF9F72D8),
    CounselorPersona.ash => const Color(0xFFC43D3D),
  };

  Color get primaryDark => switch (this) {
    CounselorPersona.grover => const Color(0xFF35B595),
    CounselorPersona.aspen => const Color(0xFFFFDD71),
    CounselorPersona.rowan => const Color(0xFFFF6F2A),
    CounselorPersona.sakura => const Color(0xFFEEC3F5),
    CounselorPersona.abies => const Color(0xFF00C8FF),
    CounselorPersona.cedite => const Color(0xFFB388EB),
    CounselorPersona.ash => const Color(0xFFE55B5B),
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
    CounselorPersona.abies => const Color(0xFF1A1D1F),
    _ => Colors.white,
  };

  Color onPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? onPrimaryDark : onPrimaryLight;

  String get avatarLightAsset => 'assets/app_icons/png/${id}_light.png';
  String get avatarDarkAsset => 'assets/app_icons/png/${id}_dark.png';
  String avatarAsset(Brightness brightness) => brightness == Brightness.dark
      ? 'assets/app_icons/png/${id}_dark.png'
      : 'assets/app_icons/png/${id}_light.png';

  String get iosIconName => switch (this) {
    CounselorPersona.grover => 'grover',
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
}

class AppFeatureFlags {
  AppFeatureFlags._();

  static final ValueNotifier<bool> lockdownMode = ValueNotifier(false);
  static final ValueNotifier<bool> isBeta = ValueNotifier(false);
  static final ValueNotifier<bool> enableClubs = ValueNotifier(false);
  static final ValueNotifier<bool> enableCounselor = ValueNotifier(false);
  static final ValueNotifier<bool> isReady = ValueNotifier(false);
  static final List<String> _betaTesters = [];

  static bool isBetaTester(String? email) {
    if (email == null) return false;
    return _betaTesters.contains(email.toLowerCase().trim());
  }

  static bool get ashUnlocked => false;

  static Future<void> load() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _startListener();
    });

    final completer = Completer<void>();
    _startListener(
      onFirstData: () {
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => print('[FLAGS] Sync timed out, proceeding...'),
    );
    isReady.value = true;
  }

  static StreamSubscription? _sub;
  static void _startListener({VoidCallback? onFirstData}) {
    _sub?.cancel();
    try {
      _sub = FirebaseFirestore.instance
          .collection('app_config')
          .doc('feature_flags')
          .snapshots()
          .listen(
            (doc) {
              if (doc.exists) {
                final data = doc.data();
                lockdownMode.value = data?['lockdown_mode'] ?? false;

                final testers = List<String>.from(data?['beta_testers'] ?? []);
                _betaTesters.clear();
                _betaTesters.addAll(testers.map((e) => e.toLowerCase().trim()));

                final currentEmail = FirebaseAuth.instance.currentUser?.email;
                final isBetaTesterFlag = isBetaTester(currentEmail);
                isBeta.value = isBetaTesterFlag;

                enableClubs.value =
                    (data?['enable_clubs'] ?? false) || isBetaTesterFlag;
                enableCounselor.value =
                    (data?['enable_counselor'] ?? false) || isBetaTesterFlag;

                print('[FLAGS] --- SYSTEM STATUS ---');
                print('[FLAGS] Lockdown Active: ${lockdownMode.value}');
                print('[FLAGS] User Is Beta: $isBetaTesterFlag');
                print('[FLAGS] Clubs Enabled: ${enableClubs.value}');
                print('[FLAGS] Counselor Enabled: ${enableCounselor.value}');
                print('[FLAGS] -----------------------');

                onFirstData?.call();
              }
            },
            onError: (e) {
              print('[FLAGS] Firestore restricted access: $e');

              onFirstData?.call();
            },
          );
    } catch (e) {
      print('[FLAGS] Fatal listener error: $e');
      onFirstData?.call();
    }
  }

  static Future<void> loadUserUnlocks(String uid) async {}
}

class CounselorPersonaService {
  CounselorPersonaService._();

  static final ValueNotifier<CounselorPersona> activePersona =
      ValueNotifier<CounselorPersona>(CounselorPersona.grover);

  static const _personaField = 'counselor_persona';
  static const _abiesUnlockedField = 'abies_unlocked';
  static const _cediteUnlockedField = 'cedite_unlocked';
  static const _ashUnlockedField = 'ash_unlocked';
  static const _ashLockedForeverField = 'ash_locked_forever';

  static const _iconChannel = MethodChannel('com.gr0ve.app/icon');

  static bool _abiesUnlocked = false;
  static bool _cediteUnlocked = false;
  static bool _ashUnlocked = false;
  static bool _ashLockedForever = false;

  static bool get abiesUnlocked => _abiesUnlocked;
  static bool get cediteUnlocked => _cediteUnlocked;
  static bool get ashUnlocked => _ashUnlocked;
  static bool get ashLockedForever => _ashLockedForever;

  static DateTime? _lastIconChangeAttempt;

  static CounselorPersona _fromString(String? s) => CounselorPersona.values
      .firstWhere((p) => p.id == s, orElse: () => CounselorPersona.grover);

  static bool _isUnlocked(CounselorPersona p) {
    final data = UserDocCache.getCached();
    final bool abies = (data?[_abiesUnlockedField] == true) || _abiesUnlocked;
    final bool cedite =
        (data?[_cediteUnlockedField] == true) || _cediteUnlocked;
    final bool ash = (data?[_ashUnlockedField] == true) || _ashUnlocked;

    return switch (p) {
      CounselorPersona.abies => abies,
      CounselorPersona.cedite => cedite,
      CounselorPersona.ash => ash,
      _ => true,
    };
  }

  static bool isPersonaUnlocked(CounselorPersona p) => _isUnlocked(p);

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

  static List<CounselorPersona> get availablePersonas =>
      CounselorPersona.values.where((p) {
        if (p.isHidden) return _isUnlocked(p);
        return true;
      }).toList();

  static Future<void> init({Map<String, dynamic>? cachedUserData}) async {
    final persona = await load(cachedUserData: cachedUserData);
    activePersona.value = persona;
  }

  static Future<CounselorPersona> load({
    Map<String, dynamic>? cachedUserData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return CounselorPersona.grover;
    try {
      final data = cachedUserData ?? await UserDocCache.get();

      _abiesUnlocked = (data?[_abiesUnlockedField] as bool?) ?? false;
      _cediteUnlocked = (data?[_cediteUnlockedField] as bool?) ?? false;
      _ashUnlocked = (data?[_ashUnlockedField] as bool?) ?? false;
      _ashLockedForever = (data?[_ashLockedForeverField] as bool?) ?? false;

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

  static void markAbiesUnlocked() {
    _abiesUnlocked = true;
    _persistUnlock(_abiesUnlockedField);
  }

  static void markCediteUnlocked() {
    _cediteUnlocked = true;
    _persistUnlock(_cediteUnlockedField);
  }

  static void markAshUnlocked() {
    _ashUnlocked = true;
    _persistUnlock(_ashUnlockedField);
  }

  static Future<void> lockAshForever() async {
    _ashLockedForever = true;
    await _persistUnlock(_ashLockedForeverField);
  }

  static Future<void> _persistUnlock(String field) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {field: true},
      );
    } catch (_) {}
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

  static Future<void> syncAppIcon(CounselorPersona persona) async {
    await _syncAppIcon(persona);
  }

  static Future<void> _syncAppIcon(CounselorPersona persona) async {
    await Future.wait([_syncIosIcon(persona), _syncAndroidIcon(persona)]);
  }

  static Future<Map<String, dynamic>> diagnoseIosIconSetup() async {
    if (kIsWeb || !io.Platform.isIOS) {
      return {'error': 'Not iOS or Web platform'};
    }

    final results = <String, dynamic>{};

    try {
      final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
      results['supported'] = supported;

      if (!supported) {
        return results;
      }

      final current = await FlutterDynamicIconPlus.alternateIconName;
      results['current_icon'] = current ?? 'default';

      final testIcons = ['grover', 'aspen', 'rowan', 'sakura', 'abies'];
      final availableIcons = <String>[];

      for (final iconName in testIcons) {
        try {
          await FlutterDynamicIconPlus.supportsAlternateIcons;
          availableIcons.add(iconName);
        } catch (e) {
          debugPrint('[DIAGNOSTIC] Icon "$iconName" test: ${e.toString()}');
        }
      }

      results['test_icons'] = testIcons;
      results['available_icons'] = availableIcons;
    } catch (e, stack) {
      results['error'] = e.toString();
      results['stack'] = stack.toString();
    }

    return results;
  }

  static Future<void> _syncIosIcon(CounselorPersona persona) async {
    if (kIsWeb || !io.Platform.isIOS) return;

    try {
      final supported = await FlutterDynamicIconPlus.supportsAlternateIcons;
      if (!supported) {
        debugPrint('[ICON] Dynamic icons not supported on this device');
        return;
      }

      final current = await FlutterDynamicIconPlus.alternateIconName;
      debugPrint('[ICON] Current icon: ${current ?? "default"}');

      if (current == persona.iosIconName) {
        debugPrint('[ICON] Already set to ${persona.iosIconName}, skipping');
        return;
      }

      final now = DateTime.now();
      if (_lastIconChangeAttempt != null) {
        final timeSinceLastChange = now.difference(_lastIconChangeAttempt!);
        const minInterval = Duration(seconds: 3);

        if (timeSinceLastChange < minInterval) {
          final waitTime = minInterval - timeSinceLastChange;
          debugPrint(
            '[ICON] Waiting ${waitTime.inSeconds}s before attempting icon change...',
          );
          await Future.delayed(waitTime);
        }
      }

      try {
        debugPrint('[ICON] Changing iOS icon to: ${persona.iosIconName}');

        await FlutterDynamicIconPlus.setAlternateIconName(
          iconName: persona.iosIconName == 'grover'
              ? null
              : persona.iosIconName,
        );
        _lastIconChangeAttempt = DateTime.now();

        debugPrint('[ICON] ✅ Successfully changed to ${persona.iosIconName}');
      } on PlatformException catch (e) {
        debugPrint('[ICON] ❌ PlatformException: ${e.code}');
        debugPrint('[ICON] Message: ${e.message}');
      }
    } catch (e, stack) {
      debugPrint('[ICON] ❌ Unexpected error: $e');
      debugPrint('[ICON] Stack: $stack');
    }
  }

  static Future<void> _syncAndroidIcon(CounselorPersona persona) async {
    if (kIsWeb || !io.Platform.isAndroid) return;
    try {
      await _iconChannel.invokeMethod<void>('setIcon', {
        'alias': persona.androidAlias,
      });
    } on PlatformException {
    } on MissingPluginException {}
  }
}
