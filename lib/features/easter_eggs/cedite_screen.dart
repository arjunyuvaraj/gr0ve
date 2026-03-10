import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

// ─────────────────────────────────────────────────────────────
// CEDITE UNLOCK SERVICE
// ─────────────────────────────────────────────────────────────

class CediteUnlockService {
  static const _field = 'cedite_unlocked';
  // The word is "decite" — a deliberate misspelling that mirrors
  // Cedite's nature: the answer is right there, but slightly off
  static const String passphrase = 'decite';

  static Future<bool> checkUnlocked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return (doc.data()?[_field] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> tryUnlock(String input) async {
    if (input.trim().toLowerCase() != passphrase) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {_field: true},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markUnlocked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {_field: true},
      );
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────
// CEDITE VOICE LINES
// Pre-unlock: conspiratorial fragments, hints that feel like
//             insider knowledge but don't quite add up
// Post-unlock: charming, unreliable, almost-right
// ─────────────────────────────────────────────────────────────

const _cediteAmbiguousLines = [
  'I heard something about this.',
  'Between us — this is the right place.',
  'Someone mentioned your name. Recently.',
  'You found it. Most people look right past it.',
  'I know a few people who have been here before.',
  "There's a version of this that makes more sense.",
  'The answer is closer than you think.',
  'I almost told someone else. Almost.',
  '...',
  "Officially, this doesn't exist.",
];

const _cediteRevealLines = [
  'You verified the right thing for once.',
  'Now you know where to find me.',
  'I would say I was surprised, but I knew you were coming.',
  'Most people never get this far. Unofficially.',
  'The information was always here. You just had to look slightly wrong.',
];

String cediteVoiceLine({required bool unlocked}) {
  final r = Random();
  final lines = unlocked ? _cediteRevealLines : _cediteAmbiguousLines;
  if (!unlocked && r.nextDouble() < 0.08) return '...';
  return lines[r.nextInt(lines.length)];
}

// ─────────────────────────────────────────────────────────────
// CEDITE SCREEN — entry point
// ─────────────────────────────────────────────────────────────

class CediteScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const CediteScreen({super.key, this.onUnlocked});

  @override
  State<CediteScreen> createState() => _CediteScreenState();
}

class _CediteScreenState extends State<CediteScreen> {
  bool _checking = true;
  bool _alreadyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final unlocked = await CediteUnlockService.checkUnlocked();
    if (!mounted) return;
    setState(() {
      _alreadyUnlocked = unlocked;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pc = CounselorPersona.cedite.primary(Theme.of(context).brightness);

    if (_checking) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: pc, strokeWidth: 2),
        ),
      );
    }

    if (_alreadyUnlocked) {
      return CediteRevealScreen(onContinue: widget.onUnlocked);
    }

    return _CediteTypingScreen(
      onUnlocked: () {
        setState(() => _alreadyUnlocked = true);
        widget.onUnlocked?.call();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TYPING SCREEN — enter "decite" on a custom keyboard
// Letters are rendered in slightly wrong positions / weights
// to mirror Cedite's distorted nature
// ─────────────────────────────────────────────────────────────

class _CediteTypingScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _CediteTypingScreen({required this.onUnlocked});

  @override
  State<_CediteTypingScreen> createState() => _CediteTypingScreenState();
}

class _CediteTypingScreenState extends State<_CediteTypingScreen>
    with TickerProviderStateMixin {
  static const _correct = 'decite';
  static const _maxLen = 6;

  String _entered = '';
  bool _success = false;
  String? _errorMsg;
  int _failCount = 0;

  String _cediteLine = '...';
  bool _voiceVisible = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late AnimationController _voiceCtrl;
  late Animation<double> _voiceFade;
  late AnimationController _staticCtrl;

  // Static / distortion animation — occasional flicker
  double _staticOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _voiceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _voiceFade = CurvedAnimation(parent: _voiceCtrl, curve: Curves.easeOut);

    // Static flicker controller — loops irregularly
    _staticCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _cediteLine = cediteVoiceLine(unlocked: false);
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _voiceVisible = true);
      _voiceCtrl.forward();
    });

    // Occasional static flicker
    _scheduleStaticFlicker();
  }

  void _scheduleStaticFlicker() {
    final delay = 2000 + Random().nextInt(4000);
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _staticOpacity = 0.06 + Random().nextDouble() * 0.08);
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        setState(() => _staticOpacity = 0.0);
        _scheduleStaticFlicker();
      });
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    _voiceCtrl.dispose();
    _staticCtrl.dispose();
    super.dispose();
  }

  void _pressLetter(String letter) {
    if (_entered.length >= _maxLen || _success) return;
    setState(() {
      _entered += letter;
      _errorMsg = null;
    });
    HapticFeedback.selectionClick();
    if (_entered.length == _maxLen) _check();
  }

  void _delete() {
    if (_entered.isEmpty || _success) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
    HapticFeedback.lightImpact();
  }

  Future<void> _check() async {
    if (_entered.toLowerCase() == _correct) {
      HapticFeedback.heavyImpact();
      setState(() => _success = true);
      await CediteUnlockService.markUnlocked();
      // CounselorPersonaService.markCediteUnlocked();
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) widget.onUnlocked();
    } else {
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      _failCount++;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _entered = '';
          _errorMsg = _failMessage(_failCount);
        });
      }
    }
  }

  String _failMessage(int n) {
    if (n == 1) return 'That information is incorrect.';
    if (n == 2) return "Close. Not quite. From what I understand.";
    if (n == 3) return 'You should verify this with someone official.';
    if (n == 4) return 'The answer is almost what you think it is.';
    return "I might be slightly off on the specifics. So might you.";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.cedite.primary(brightness);

    // Keyboard layout: 3 rows
    const row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
    const row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
    const row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

    // Letters that appear in "decite" — glow faintly as hints
    const hintLetters = {'D', 'E', 'C', 'I', 'T'};

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Distortion field background
          const Positioned.fill(child: _CediteDistortionBg()),

          // Static flicker overlay
          if (_staticOpacity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _StaticNoisePainter(opacity: _staticOpacity),
                ),
              ),
            ),

          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withOpacity(
                                0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Avatar — slightly offset to feel wrong
                      Transform.translate(
                        offset: const Offset(2, 0),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pc.withOpacity(0.08),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              CounselorPersona.cedite.avatarAsset(brightness),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Voice line
                      SizedBox(
                        height: 20,
                        child: _voiceVisible
                            ? FadeTransition(
                                opacity: _voiceFade,
                                child: Text(
                                  _cediteLine,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: pc.withOpacity(0.55),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 18),

                      Text(
                        'The Wrong Door',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Most people walk right past it.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.38),
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Entered text display — letters shown, slightly
                      // inconsistent spacing to feel unstable
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) {
                          final dx = sin(_shakeAnim.value * pi * 6) * 8;
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_maxLen, (i) {
                              final filled = i < _entered.length;
                              final letter = filled
                                  ? _entered[i].toUpperCase()
                                  : '';
                              // Slight vertical jitter per-slot
                              final jitter = (i % 3 == 1) ? -1.5 : 0.0;
                              return Transform.translate(
                                offset: Offset(0, jitter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  width: 32,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: filled
                                            ? pc.withOpacity(0.7)
                                            : colors.outline.withOpacity(0.2),
                                        width: filled ? 2 : 1,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      letter,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: _success ? pc : colors.onSurface,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Error message
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _errorMsg != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _errorMsg!,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: pc.withOpacity(0.65),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 8),
                      ),

                      const SizedBox(height: 24),

                      // ── Keyboard ──────────────────────────────
                      _buildKeyRow(row1, hintLetters, colors, textTheme, pc),
                      const SizedBox(height: 8),
                      _buildKeyRow(row2, hintLetters, colors, textTheme, pc),
                      const SizedBox(height: 8),
                      _buildKeyRow(
                        row3,
                        hintLetters,
                        colors,
                        textTheme,
                        pc,
                        withDelete: true,
                      ),

                      const SizedBox(height: 48),

                      Text(
                        'the answer is almost what you think it is',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.18),
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(
    List<String> letters,
    Set<String> hintLetters,
    ColorScheme colors,
    TextTheme textTheme,
    Color pc, {
    bool withDelete = false,
  }) {
    final keys = <Widget>[];
    for (final letter in letters) {
      final isHint = hintLetters.contains(letter);
      keys.add(
        Expanded(
          child: GestureDetector(
            onTap: () => _pressLetter(letter.toLowerCase()),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isHint
                    ? pc.withOpacity(0.10)
                    : colors.surfaceContainerHighest.withOpacity(0.45),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isHint
                      ? pc.withOpacity(0.28)
                      : colors.outline.withOpacity(0.06),
                ),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: textTheme.labelLarge?.copyWith(
                    color: isHint ? pc : colors.onSurface.withOpacity(0.75),
                    fontWeight: isHint ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    shadows: isHint
                        ? [Shadow(color: pc.withOpacity(0.4), blurRadius: 8)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (withDelete) {
      keys.add(
        GestureDetector(
          onTap: _delete,
          child: Container(
            height: 44,
            width: 52,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.backspace_outlined,
              size: 16,
              color: colors.onSurface.withOpacity(0.45),
            ),
          ),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: keys);
  }
}

// ─────────────────────────────────────────────────────────────
// CEDITE REVEAL SCREEN
// ─────────────────────────────────────────────────────────────

class CediteRevealScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  const CediteRevealScreen({super.key, this.onContinue});

  @override
  State<CediteRevealScreen> createState() => _CediteRevealScreenState();
}

class _CediteRevealScreenState extends State<CediteRevealScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _textFade;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();

    _iconFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _btnFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.cedite.primary(brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _CediteDistortionBg()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withOpacity(
                                0.5,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: colors.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      FadeTransition(
                        opacity: _iconFade,
                        child: ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pc.withOpacity(0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: pc.withOpacity(0.22),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                CounselorPersona.cedite.avatarAsset(brightness),
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Text(
                              'Cedite',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: pc.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: pc.withOpacity(0.25)),
                              ),
                              child: Text(
                                'Deceite',
                                style: textTheme.labelSmall?.copyWith(
                                  color: pc,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The Forgotten Trees',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(0.3),
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Nobody planted Cedite.\nOne day he was simply there.\n\n'
                              'He knows everyone, and everyone knows him —\n'
                              'or thinks they do.\n\n'
                              '*Almost* right. *Almost* always.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.55),
                                height: 1.75,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _CediteRevealTrait(
                              label: 'Charming. Unreliable.',
                              sub: 'What he tells you is almost always useful.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _CediteRevealTrait(
                              label: 'One thing per response will be wrong.',
                              sub:
                                  'Plausible. Blended in. Verify with someone official.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                              isWarning: true,
                            ),
                            const SizedBox(height: 10),
                            _CediteRevealTrait(
                              label: 'Insider knowledge.',
                              sub:
                                  'He has a way of knowing what the handbook leaves out.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      FadeTransition(
                        opacity: _btnFade,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: pc,
                              foregroundColor: CounselorPersona.cedite
                                  .onPrimary(brightness),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Speak with Cedite',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REVEAL TRAIT CARD
// ─────────────────────────────────────────────────────────────

class _CediteRevealTrait extends StatelessWidget {
  const _CediteRevealTrait({
    required this.label,
    required this.sub,
    required this.pc,
    required this.colors,
    required this.textTheme,
    this.isWarning = false,
  });

  final String label;
  final String sub;
  final Color pc;
  final ColorScheme colors;
  final TextTheme textTheme;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final accentColor = isWarning ? Colors.orange.shade600 : pc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning
              ? Colors.orange.withOpacity(0.15)
              : colors.outline.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.45),
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DISTORTION BACKGROUND
// Shifting purple wisps + faint tangled lines
// ─────────────────────────────────────────────────────────────

class _CediteDistortionBg extends StatefulWidget {
  const _CediteDistortionBg();

  @override
  State<_CediteDistortionBg> createState() => _CediteDistortionBgState();
}

class _CediteDistortionBgState extends State<_CediteDistortionBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..addListener(() => setState(() {}))
          ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.cedite.primary(brightness);
    return CustomPaint(
      painter: _CediteDistortionPainter(t: _ctrl.value * 14, color: pc),
    );
  }
}

class _CediteDistortionPainter extends CustomPainter {
  final double t;
  final Color color;
  const _CediteDistortionPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Drifting fog blobs
    for (int i = 0; i < 4; i++) {
      final cx =
          size.width * (0.15 + i * 0.23) +
          sin(t * 0.07 + i * 1.4) * size.width * 0.10;
      final cy =
          size.height * 0.35 + cos(t * 0.05 + i * 1.1) * size.height * 0.18;
      canvas.drawCircle(
        Offset(cx, cy),
        size.width * 0.28,
        Paint()
          ..color = color.withOpacity(0.025 + sin(t * 0.09 + i) * 0.01)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.16),
      );
    }

    // Drifting connection lines
    final rng = Random(77);
    final nodes = List.generate(
      14,
      (i) =>
          Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
    );
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist > size.width * 0.4) continue;
        final drift = sin(t * 0.055 + i * 0.8 + j * 0.4) * 5;
        final opacity = (1 - dist / (size.width * 0.4)) * 0.05;
        canvas.drawLine(
          nodes[i].translate(drift, -drift * 0.4),
          nodes[j].translate(-drift * 0.3, drift * 0.6),
          Paint()
            ..color = color.withOpacity(opacity)
            ..strokeWidth = 0.35,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CediteDistortionPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────
// STATIC NOISE PAINTER — brief interference flicker
// ─────────────────────────────────────────────────────────────

class _StaticNoisePainter extends CustomPainter {
  final double opacity;
  _StaticNoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random();
    final paint = Paint()..color = Colors.white.withOpacity(opacity);
    for (int i = 0; i < 120; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 1.5 + rng.nextDouble() * 3, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StaticNoisePainter old) => old.opacity != opacity;
}
