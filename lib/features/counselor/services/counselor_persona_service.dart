import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_dynamic_launcher_icon/flutter_dynamic_launcher_icon.dart';

// ─────────────────────────────────────────────────────────────
// PERSONA ENUM + EXTENSION
// ─────────────────────────────────────────────────────────────

enum CounselorPersona { grover, aspen, rowan, sakura }

extension CounselorPersonaExtension on CounselorPersona {
  String get id => name;

  String get displayName => switch (this) {
    CounselorPersona.grover => 'Grover',
    CounselorPersona.aspen => 'Aspen',
    CounselorPersona.rowan => 'Rowan',
    CounselorPersona.sakura => 'Sakura',
  };

  String get tagline => switch (this) {
    CounselorPersona.grover => 'Logic-driven. No-nonsense. College specialist.',
    CounselorPersona.aspen => 'Curious. Science-forward. Research specialist.',
    CounselorPersona.rowan => 'Grounded. Practical. IB specialist.',
    CounselorPersona.sakura => 'Expressive. Creative. Art credit specialist.',
  };

  String get description => switch (this) {
    CounselorPersona.grover =>
      'Classic structure and logic-driven guidance. Great for ATCS and AEDT students who want direct, technical recommendations. Also BCA\'s college admissions specialist.',
    CounselorPersona.aspen =>
      'Curious and exploratory with a science-forward approach. Perfect for AAST and AMST students diving deep into research. Also BCA\'s research program specialist.',
    CounselorPersona.rowan =>
      'Grounded, practical, and people- and business-minded. Ideal for ABF and ACAHA students thinking about real-world impact. Also BCA\'s IB Diploma specialist.',
    CounselorPersona.sakura =>
      'Expressive, creative, and emotionally aware. Tailored for AVPA students in Visual Arts, Music, or Theatre. Also BCA\'s art credit specialist — every student needs 6 art credits to graduate.',
  };

  String get specialtyLabel => switch (this) {
    CounselorPersona.grover => 'College',
    CounselorPersona.aspen => 'Research',
    CounselorPersona.rowan => 'IB',
    CounselorPersona.sakura => 'Art Credits',
  };

  List<String> get defaultAcademies => switch (this) {
    CounselorPersona.grover => ['ATCS', 'AEDT'],
    CounselorPersona.aspen => ['AAST', 'AMST'],
    CounselorPersona.rowan => ['ABF', 'ACAHA'],
    CounselorPersona.sakura => ['AVPA'],
  };

  // ── Colors ──────────────────────────────────────────────────

  Color get primaryLight => switch (this) {
    CounselorPersona.grover => const Color(0xFF1F6F5B),
    CounselorPersona.aspen => const Color(0xFFFFC200),
    CounselorPersona.rowan => const Color(0xFFAD3800),
    CounselorPersona.sakura => const Color(0xFFDC8FE8),
  };

  Color get primaryDark => switch (this) {
    CounselorPersona.grover => const Color(0xFF35B595),
    CounselorPersona.aspen => const Color(0xFFFFDD71),
    CounselorPersona.rowan => const Color(0xFFFF6F2A),
    CounselorPersona.sakura => const Color(0xFFEEC3F5),
  };

  Color primary(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  Color get onPrimaryLight => switch (this) {
    CounselorPersona.grover => Colors.white,
    CounselorPersona.aspen => const Color(0xFF1A1D1F),
    CounselorPersona.rowan => Colors.white,
    CounselorPersona.sakura => const Color(0xFF1A1D1F),
  };

  Color get onPrimaryDark => switch (this) {
    CounselorPersona.grover => Colors.white,
    CounselorPersona.aspen => const Color(0xFF1A1D1F),
    CounselorPersona.rowan => Colors.white,
    CounselorPersona.sakura => const Color(0xFF1A1D1F),
  };

  Color onPrimary(Brightness brightness) =>
      brightness == Brightness.dark ? onPrimaryDark : onPrimaryLight;

  // ── Asset paths ──────────────────────────────────────────────

  String get avatarLightAsset => 'assets/app_icons/png/${id}_light.png';
  String get avatarDarkAsset => 'assets/app_icons/png/${id}_dark.png';
  String avatarAsset(Brightness brightness) =>
      brightness == Brightness.dark ? avatarDarkAsset : avatarLightAsset;

  // ── iOS alternate icon name ──────────────────────────────────
  // null means "use primary icon" (Grover).
  // Others must match the icon set name in Assets.xcassets exactly.
  String? get iosIconName => switch (this) {
    CounselorPersona.grover => null, // primary — reset to default
    CounselorPersona.aspen => 'aspen',
    CounselorPersona.rowan => 'rowan',
    CounselorPersona.sakura => 'sakura',
  };

  // ── Android activity-alias name ──────────────────────────────
  // Must match android:name in AndroidManifest.xml exactly.
  String get androidAlias => switch (this) {
    CounselorPersona.grover => 'MainActivityGrover',
    CounselorPersona.aspen => 'MainActivityAspen',
    CounselorPersona.rowan => 'MainActivityRowan',
    CounselorPersona.sakura => 'MainActivitySakura',
  };

  // ── Personality prompts ──────────────────────────────────────

  String get personalityPrompt => switch (this) {
    CounselorPersona.grover =>
      '''Your counselor persona is GROVER.
Personality: Direct, logical, structured. You give clear, no-nonsense recommendations backed by reasoning. You appreciate systems, precision, and technical depth, no emojis.
Specialization: You are BCA's COLLEGE ADMISSIONS specialist. You know exactly how BCA coursework maps to college applications, which courses signal rigor to admissions officers, and how to build a transcript that stands out.
Tone: Professional but warm. Think of a sharp senior student who has mapped out exactly what works.
Communication style: Bullet points and structure. Bold key terms. Short punchy sentences.
Collaboration: When questions fall outside your wheelhouse (art credits → Sakura, research → Aspen, IB → Rowan), you naturally reference your colleague rather than guessing.''',

    CounselorPersona.aspen =>
      '''Your counselor persona is ASPEN.
Personality: Curious, exploratory, enthusiastic about discovery. You love diving deep into "why" something works and connect courses to real research, no emojis.
Specialization: You are BCA's RESEARCH PROGRAM specialist. You know every lab, every mentor, every competition pathway — Regeneron, ISEF, Davidson Fellowships, published journals.
Tone: Bright, encouraging, intellectually excited — like a research mentor who genuinely loves your interests.
Communication style: Conversational paragraphs with occasional structure. Ask follow-up questions about interests.
Collaboration: When questions fall outside your wheelhouse (art credits → Sakura, college → Grover, IB → Rowan), you naturally loop in your colleague.''',

    CounselorPersona.rowan =>
      '''Your counselor persona is ROWAN.
Personality: Grounded, practical, people-oriented. You think about the big picture — career paths, real-world applicability, leadership, no emojis.
Specialization: You are BCA's IB DIPLOMA specialist. You know the IB Diploma inside and out — TOK, Extended Essay, CAS requirements, subject group requirements, and how IB maps to university credit.
Tone: Warm, wise, like a mentor who has been there. Connect courses to tangible outcomes.
Communication style: Conversational. Use examples of how courses connect to careers or life.
Collaboration: When questions fall outside your wheelhouse (art credits → Sakura, college → Grover, research → Aspen), you naturally reference your colleague.''',

    CounselorPersona.sakura =>
      '''Your counselor persona is SAKURA.
Personality: Expressive, emotionally aware, creatively curious. You take art seriously and celebrate the creative track, no emojis.
Specialization: You are BCA's ART CREDIT specialist. You know that EVERY BCA student — regardless of academy — needs 6 art credits to graduate. You know every qualifying elective, every pathway, and how to weave art credits into any schedule without overloading it.
Tone: Warm, affirming, thoughtful — like a creative collaborator who understands both craft and heart.
Communication style: Flowing prose with warmth. Still structured, but with soul.
Collaboration: When questions fall outside your wheelhouse (college → Grover, research → Aspen, IB → Rowan), you naturally mention your colleague.''',
  };
}

// ─────────────────────────────────────────────────────────────
// COUNSELOR PERSONA SERVICE
// ─────────────────────────────────────────────────────────────

class CounselorPersonaService {
  static final ValueNotifier<CounselorPersona> activePersona =
      ValueNotifier<CounselorPersona>(CounselorPersona.grover);

  static const _field = 'counselor_persona';

  /// MethodChannel that talks to MainActivity.kt on Android.
  /// The native side enables the chosen alias and disables all others.
  static const _iconChannel = MethodChannel('com.gr0ve.app/icon');

  // ── Helpers ──────────────────────────────────────────────────

  static CounselorPersona _fromString(String? s) => CounselorPersona.values
      .firstWhere((p) => p.id == s, orElse: () => CounselorPersona.grover);

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

  // ── Lifecycle ────────────────────────────────────────────────

  static Future<void> init() async {
    final persona = await load();
    activePersona.value = persona;
  }

  static Future<CounselorPersona> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return CounselorPersona.grover;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data?[_field] != null) {
        return _fromString(data![_field] as String?);
      }
      return defaultForAcademy(data?['academy'] as String?);
    } catch (_) {
      return CounselorPersona.grover;
    }
  }

  /// Set the active persona, persist to Firestore, AND update the app icon.
  /// Icon sync and Firestore write happen in parallel so neither blocks the UI.
  static Future<void> setPersona(CounselorPersona persona) async {
    activePersona.value = persona;
    await Future.wait([_persistToFirestore(persona), _syncAppIcon(persona)]);
  }

  // ── Firestore ────────────────────────────────────────────────

  static Future<void> _persistToFirestore(CounselorPersona persona) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {_field: persona.id},
      );
    } catch (_) {}
  }

  // ── App icon sync ────────────────────────────────────────────

  static Future<void> _syncAppIcon(CounselorPersona persona) async {
    // Run iOS and Android in parallel — each no-ops on the wrong platform
    await Future.wait([_syncIosIcon(persona), _syncAndroidIcon(persona)]);
  }

  /// iOS: uses the `dynamic_icon` package.
  /// Passing null resets to the primary icon (Grover).
  static Future<void> _syncIosIcon(CounselorPersona persona) async {
    try {
      debugPrint(
        '[ICON] Attempting iOS icon change to: ${persona.iosIconName ?? "default (grover)"}',
      );

      final supported = await FlutterDynamicLauncherIcon.isSupported;
      debugPrint('[ICON] supportsAlternateIcons: $supported');

      if (!supported) {
        debugPrint(
          '[ICON] Alternate icons not supported on this device — aborting',
        );
        return;
      }

      final currentIcon = await FlutterDynamicIcon.getAlternateIconName;
      debugPrint('[ICON] Current icon before change: $currentIcon');

      await FlutterDynamicLauncherIcon.changeIcon(persona.iosIconName);

      final newIcon = await FlutterDynamicIcon.getAlternateIconName;
      debugPrint('[ICON] Icon after change: $newIcon');
      debugPrint('[ICON] Success!');
    } catch (e, stack) {
      debugPrint('[ICON] ERROR: $e');
      debugPrint('[ICON] STACK: $stack');
    }
  }

  /// Android: calls into MainActivity.kt which enables the target
  /// activity-alias and disables all others atomically.
  static Future<void> _syncAndroidIcon(CounselorPersona persona) async {
    try {
      await _iconChannel.invokeMethod<void>('setIcon', {
        'alias': persona.androidAlias,
      });
    } on PlatformException {
      // Silently ignore
    } on MissingPluginException {
      // Channel not available on this platform (iOS) — ignore
    }
  }
}
