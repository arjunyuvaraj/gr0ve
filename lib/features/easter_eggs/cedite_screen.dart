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
// CEDITE SHADOW SCREEN — entry point
// ─────────────────────────────────────────────────────────────

class CediteShadowScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const CediteShadowScreen({super.key, this.onUnlocked});

  @override
  State<CediteShadowScreen> createState() => _CediteShadowScreenState();
}

class _CediteShadowScreenState extends State<CediteShadowScreen> {
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(color: pc, strokeWidth: 2),
        ),
      );
    }

    if (_alreadyUnlocked) {
      return CediteRevealScreen(onContinue: widget.onUnlocked);
    }

    return _PassphraseScreen(
      onUnlocked: () {
        setState(() => _alreadyUnlocked = true);
        widget.onUnlocked?.call();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PASSPHRASE SCREEN
// ─────────────────────────────────────────────────────────────

const _cediteHintLetters = {'D', 'E', 'C', 'I', 'T'};

class _PassphraseScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _PassphraseScreen({required this.onUnlocked});

  @override
  State<_PassphraseScreen> createState() => _PassphraseScreenState();
}

class _PassphraseScreenState extends State<_PassphraseScreen>
    with TickerProviderStateMixin {
  static const _correct = 'DECEIT';

  String _entered = '';
  bool _success = false;
  String? _errorMsg;
  int _failCount = 0;

  final String _cediteLine = 'Truth is rarely what it seems...';
  bool _voiceVisible = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late AnimationController _voiceCtrl;
  late Animation<double> _voiceFade;

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

    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _voiceVisible = true);
      _voiceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _entryCtrl.dispose();
    _voiceCtrl.dispose();
    super.dispose();
  }

  void _press(String char) {
    if (_entered.length >= 6 || _success) return;
    setState(() {
      _entered += char.toUpperCase();
      _errorMsg = null;
    });
    HapticFeedback.selectionClick();
    if (_entered.length == 6) _check();
  }

  void _delete() {
    if (_entered.isEmpty || _success) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
    HapticFeedback.lightImpact();
  }

  Future<void> _check() async {
    if (_entered == _correct) {
      HapticFeedback.heavyImpact();
      setState(() => _success = true);
      await CediteUnlockService.markUnlocked();
      CounselorPersonaService.markCediteUnlocked();
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
    if (n == 1) return 'The shadows do not trust you yet.';
    if (n == 2) return 'A lie, or a simple mistake?';
    if (n == 3) return 'I am the truth you fear, and the lie you live.';
    return 'Speak the name of the shadow.';
  }

  Widget _buildQWERTY(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
    Color pc,
  ) {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((char) {
              final isBack = char == '⌫';
              final isHint = _cediteHintLetters.contains(char);

              if (isBack) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: _delete,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 18,
                          color: colors.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => _press(char),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.outline.withOpacity(0.07),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        char,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: isHint
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isHint
                              ? pc.withOpacity(0.7)
                              : colors.onSurface,
                          shadows: isHint
                              ? [
                                  Shadow(
                                    color: pc.withOpacity(0.25),
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.cedite.primary(brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
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
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pc.withOpacity(0.08),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            CounselorPersona.cedite.avatarAsset(brightness),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 20,
                        child: _voiceVisible
                            ? FadeTransition(
                                opacity: _voiceFade,
                                child: Text(
                                  _cediteLine,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: pc.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'CEDITE',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: pc,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'I am the truth you fear...',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.38),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (context, child) {
                          final dx = sin(_shakeAnim.value * pi * 6) * 8;
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            final filled = i < _entered.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_success && filled)
                                    ? pc
                                    : filled
                                    ? pc.withOpacity(0.85)
                                    : colors.onSurface.withOpacity(0.1),
                                border: Border.all(
                                  color: filled
                                      ? pc.withOpacity(0.5)
                                      : colors.outline.withOpacity(0.15),
                                  width: 1,
                                ),
                                boxShadow: filled
                                    ? [
                                        BoxShadow(
                                          color: pc.withOpacity(0.4),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 14),
                      _buildQWERTY(context, colors, textTheme, pc),
                      const Spacer(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
      body: SafeArea(
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
                        ),
                        child: ClipOval(
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
                            'Truth',
                            style: textTheme.labelSmall?.copyWith(
                              color: pc,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The Shadow Walk',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.3),
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          '''Born in the shadows of the forgotten.
When you lie to yourself, he is there.
When you hide from the truth, he waits.

Direct. Unflinching. Real.

He will not comfort you with lies.
He will free you with the truth.''',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withOpacity(0.55),
                            height: 1.75,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _RevealTrait(
                          label: 'Brutal Honesty.',
                          sub:
                              'He does not sugarcoat the facts, he exposes them.',
                          pc: pc,
                          colors: colors,
                          textTheme: textTheme,
                        ),
                        const SizedBox(height: 10),
                        _RevealTrait(
                          label: 'Shadow Work.',
                          sub: 'Confront what you are actively avoiding.',
                          pc: pc,
                          colors: colors,
                          textTheme: textTheme,
                        ),
                        const SizedBox(height: 10),
                        _RevealTrait(
                          label: 'Unmasking.',
                          sub: 'Strip away the illusions and face reality.',
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
                          foregroundColor: CounselorPersona.cedite.onPrimary(
                            brightness,
                          ),
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
                  const SizedBox(height: 48), // Padding
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealTrait extends StatelessWidget {
  const _RevealTrait({
    required this.label,
    required this.sub,
    required this.pc,
    required this.colors,
    required this.textTheme,
  });

  final String label;
  final String sub;
  final Color pc;
  final ColorScheme colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outline.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: pc.withOpacity(0.45),
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
