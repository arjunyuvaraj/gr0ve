import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';

// ─────────────────────────────────────────────────────────────
// ABIES UNLOCK SERVICE
// ─────────────────────────────────────────────────────────────

class AbiesUnlockService {
  static const _field = 'abies_unlocked';
  static const String passphrase = 'the last tree remembers';

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
// ABIES VOICE LINES
// Pre-unlock: amnesiac, confused, fragmented
// Post-unlock: bitter, dry, precise
// ─────────────────────────────────────────────────────────────

// Centralized in persona_voice.dart

String abiesVoiceLine({required bool unlocked}) {
  return CounselorPersona.abies.lockedVoiceLine(unlocked: unlocked);
}

// ─────────────────────────────────────────────────────────────
// BUBBLE PASSCODE DIALOG
// Returns true if the correct code was entered
// ─────────────────────────────────────────────────────────────

Future<bool?> showBubblePasscodeDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _BubblePasscodeSheet(),
  );
}

class _BubblePasscodeSheet extends StatefulWidget {
  const _BubblePasscodeSheet();

  @override
  State<_BubblePasscodeSheet> createState() => _BubblePasscodeSheetState();
}

class _BubblePasscodeSheetState extends State<_BubblePasscodeSheet>
    with SingleTickerProviderStateMixin {
  static const _correct = '22437';
  String _entered = '';
  bool _success = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _press(String digit) {
    if (_entered.length >= 5 || _success) return;
    setState(() => _entered += digit);
    HapticFeedback.selectionClick();
    if (_entered.length == 5) _check();
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
      await AbiesUnlockService.markUnlocked();
      CounselorPersonaService.markAbiesUnlocked();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } else {
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _entered = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.abies.primary(brightness);

    const keys = [
      ['1', ''],
      ['2', 'ABC'],
      ['3', 'DEF'],
      ['4', 'GHI'],
      ['5', 'JKL'],
      ['6', 'MNO'],
      ['7', 'PQRS'],
      ['8', 'TUV'],
      ['9', 'WXYZ'],
      ['', ''],
      ['0', '+'],
      ['⌫', ''],
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'enter the passcode',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.35),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '_ _ _ _ _',
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.15),
              fontSize: 10,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _shakeAnim,
            builder: (context, child) {
              final dx = sin(_shakeAnim.value * pi * 6) * 8;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
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
                        ? pc.withOpacity(0.8)
                        : colors.onSurface.withOpacity(0.1),
                    border: Border.all(
                      color: filled
                          ? pc.withOpacity(0.5)
                          : colors.outline.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 28),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: keys.length,
            itemBuilder: (_, i) {
              final digit = keys[i][0];
              final letters = keys[i][1];

              if (digit.isEmpty && letters.isEmpty) {
                return const SizedBox.shrink();
              }

              if (digit == '⌫') {
                return GestureDetector(
                  onTap: _delete,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 18,
                      color: colors.onSurface.withOpacity(0.5),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: digit.isNotEmpty ? () => _press(digit) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.outline.withOpacity(0.07)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        digit,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                      if (letters.isNotEmpty)
                        Text(
                          letters,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            letterSpacing: 1.5,
                            color: colors.onSurface.withOpacity(0.3),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FROZEN LAKE SCREEN — entry point
// ─────────────────────────────────────────────────────────────

class FrozenLakeScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const FrozenLakeScreen({super.key, this.onUnlocked});

  @override
  State<FrozenLakeScreen> createState() => _FrozenLakeScreenState();
}

class _FrozenLakeScreenState extends State<FrozenLakeScreen> {
  bool _checking = true;
  bool _alreadyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final unlocked = await AbiesUnlockService.checkUnlocked();
    if (!mounted) return;
    setState(() {
      _alreadyUnlocked = unlocked;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pc = CounselorPersona.abies.primary(Theme.of(context).brightness);

    if (_checking) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: pc, strokeWidth: 2),
        ),
      );
    }

    if (_alreadyUnlocked) {
      return AbiesRevealScreen(onContinue: widget.onUnlocked);
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
// PASSPHRASE SCREEN  — numpad only, no text field
// Letters that spell ABIES on a phone keypad glow faintly:
//   A,B → key 2 | E → key 3 | I → key 4 | S → key 7
// ─────────────────────────────────────────────────────────────

// Map of digit → which of its letters are part of the hint
const _abiesHintLetters = {
  '2': {'A', 'B'},
  '3': {'E'},
  '4': {'I'},
  '7': {'S'},
};

class _PassphraseScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _PassphraseScreen({required this.onUnlocked});

  @override
  State<_PassphraseScreen> createState() => _PassphraseScreenState();
}

class _PassphraseScreenState extends State<_PassphraseScreen>
    with TickerProviderStateMixin {
  static const _correct = '22437';

  String _entered = '';
  bool _success = false;
  String? _errorMsg;
  int _failCount = 0;

  String _abiesLine = '...';
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

    _abiesLine = abiesVoiceLine(unlocked: false);
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

  void _press(String digit) {
    if (_entered.length >= 5 || _success) return;
    setState(() {
      _entered += digit;
      _errorMsg = null;
    });
    HapticFeedback.selectionClick();
    if (_entered.length == 5) _check();
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
      await AbiesUnlockService.markUnlocked();
      CounselorPersonaService.markAbiesUnlocked();
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
    if (n == 1) return 'Wrong. The lake remembers everything. Including that.';
    if (n == 2) return 'Still wrong.';
    if (n == 3)
      return 'It has been waiting a very long time. It can wait longer.';
    if (n == 4) return 'That is not it either.';
    return 'Stop guessing.';
  }

  /// Numpad as plain Rows — avoids the nested-viewport crash
  /// that GridView causes inside SingleChildScrollView.
  Widget _buildNumpad(
    BuildContext context,
    List<List<String>> keys,
    ColorScheme colors,
    TextTheme textTheme,
    Color pc,
  ) {
    const cellH = 62.0;
    const gap = 10.0;

    Widget keyCell(String digit, String letters) {
      if (digit.isEmpty && letters.isEmpty) return const SizedBox.shrink();

      if (digit == '⌫') {
        return GestureDetector(
          onTap: _delete,
          child: Container(
            height: cellH,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.backspace_outlined,
              size: 18,
              color: colors.onSurface.withOpacity(0.45),
            ),
          ),
        );
      }

      final hintSet = _abiesHintLetters[digit];
      Widget lettersWidget = const SizedBox.shrink();
      if (letters.isNotEmpty) {
        if (hintSet != null) {
          lettersWidget = RichText(
            text: TextSpan(
              children: letters.split('').map((ch) {
                final isHint = hintSet.contains(ch);
                return TextSpan(
                  text: ch,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: isHint ? FontWeight.w700 : FontWeight.w400,
                    letterSpacing: 1.2,
                    color: isHint
                        ? pc.withOpacity(0.6)
                        : colors.onSurface.withOpacity(0.22),
                    shadows: isHint
                        ? [Shadow(color: pc.withOpacity(0.45), blurRadius: 7)]
                        : null,
                  ),
                );
              }).toList(),
            ),
          );
        } else {
          lettersWidget = Text(
            letters,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 8,
              letterSpacing: 1.2,
              color: colors.onSurface.withOpacity(0.22),
            ),
          );
        }
      }

      return GestureDetector(
        onTap: digit.isNotEmpty ? () => _press(digit) : null,
        child: Container(
          height: cellH,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.outline.withOpacity(0.07)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              if (letters.isNotEmpty) ...[
                const SizedBox(height: 1),
                lettersWidget,
              ],
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (int row = 0; row < 4; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < 3; col++) {
        final i = row * 3 + col;
        cells.add(Expanded(child: keyCell(keys[i][0], keys[i][1])));
        if (col < 2) cells.add(const SizedBox(width: gap));
      }
      rows.add(Row(children: cells));
      if (row < 3) rows.add(const SizedBox(height: gap));
    }

    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.abies.primary(brightness);

    const keys = [
      ['1', ''],
      ['2', 'ABC'],
      ['3', 'DEF'],
      ['4', 'GHI'],
      ['5', 'JKL'],
      ['6', 'MNO'],
      ['7', 'PQRS'],
      ['8', 'TUV'],
      ['9', 'WXYZ'],
      ['', ''],
      ['0', '+'],
      ['⌫', ''],
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _FullScreenSnow()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SnowClumps(color: pc),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 120),
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

                      const SizedBox(height: 40),

                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pc.withOpacity(0.08),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            CounselorPersona.abies.avatarAsset(brightness),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Abies voice line — amnesiac
                      SizedBox(
                        height: 20,
                        child: _voiceVisible
                            ? FadeTransition(
                                opacity: _voiceFade,
                                child: Text(
                                  _abiesLine,
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
                        'The Frozen Lake',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Something is buried here.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.38),
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Dot indicators with glow when filled ──
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
                          children: List.generate(5, (i) {
                            final filled = i < _entered.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
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

                      // Error / fail message
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

                      // ── Numpad (Table instead of GridView to avoid nested viewport) ──
                      _buildNumpad(context, keys, colors, textTheme, pc),

                      const SizedBox(height: 48),

                      Text(
                        'not all who are forgotten chose to be',
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
}

// ─────────────────────────────────────────────────────────────
// ABIES REVEAL SCREEN
// ─────────────────────────────────────────────────────────────

class AbiesRevealScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  const AbiesRevealScreen({super.key, this.onContinue});

  @override
  State<AbiesRevealScreen> createState() => AbiesRevealScreenState();
}

class AbiesRevealScreenState extends State<AbiesRevealScreen>
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
    final pc = CounselorPersona.abies.primary(brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _FullScreenSnow()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SnowClumps(color: pc),
          ),
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
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                CounselorPersona.abies.avatarAsset(brightness),
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
                              'Abies',
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
                                'Memory',
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
                              'He was there before the rest of them.\n'
                              'His grove was buried under the first snow — he alone survived.\n'
                              'While the others grew, he watched.\n\n'
                              'Precise. Bitter. Usually right.\n\n'
                              'He does not specialize.\nHe remembers everything.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.55),
                                height: 1.75,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _RevealTrait(
                              label: 'Precise. Blunt.',
                              sub: 'If your plan has a flaw, he will name it.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _RevealTrait(
                              label: 'No sugarcoating.',
                              sub:
                                  'Honesty is the only form of kindness he respects.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _RevealTrait(
                              label: 'Scheduling & policy.',
                              sub:
                                  "Prerequisites. Credit counts. What's missing.",
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
                              foregroundColor: CounselorPersona.abies.onPrimary(
                                brightness,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Speak with Abies',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),
                      const SizedBox(height: 100), // room for snow clumps
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

// ─────────────────────────────────────────────────────────────
// FULL-SCREEN SNOW
// Covers the entire screen with drifting flakes
// ─────────────────────────────────────────────────────────────

class _FullScreenSnow extends StatefulWidget {
  const _FullScreenSnow();

  @override
  State<_FullScreenSnow> createState() => _FullScreenSnowState();
}

class _FullScreenSnowState extends State<_FullScreenSnow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Flake> _flakes;

  @override
  void initState() {
    super.initState();
    _flakes = List.generate(60, (_) => _Flake());
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
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
    final pc = CounselorPersona.abies.primary(brightness);

    return CustomPaint(
      painter: _FullScreenSnowPainter(
        flakes: _flakes,
        elapsed: _ctrl.value * 12.0,
        color: pc,
      ),
    );
  }
}

class _Flake {
  final double x = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 4.0 + Random().nextDouble() * 8.0;
  final double radius = 0.8 + Random().nextDouble() * 2.5;
  final double opacity = 0.04 + Random().nextDouble() * 0.18;
  final double drift = (Random().nextDouble() - 0.5) * 0.12;
  final double wobble = Random().nextDouble() * pi * 2;
  final double wobbleSpeed = 0.5 + Random().nextDouble() * 1.5;
}

class _FullScreenSnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double elapsed;
  final Color color;

  _FullScreenSnowPainter({
    required this.flakes,
    required this.elapsed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      final progress = ((elapsed / f.period) + f.phase) % 1.0;
      final y = progress * (size.height + f.radius * 2) - f.radius;
      final wobbleOffset =
          sin(elapsed * f.wobbleSpeed + f.wobble) * 8 * f.radius;
      final x = (f.x + f.drift * progress) * size.width + wobbleOffset;
      final edgeFade = progress < 0.05
          ? progress / 0.05
          : progress > 0.95
          ? (1.0 - progress) / 0.05
          : 1.0;
      canvas.drawCircle(
        Offset(x, y),
        f.radius,
        Paint()
          ..color = color.withOpacity(f.opacity * edgeFade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(_FullScreenSnowPainter old) => old.elapsed != elapsed;
}

// ─────────────────────────────────────────────────────────────
// SNOW CLUMPS — bottom of screen accumulation
// ─────────────────────────────────────────────────────────────

class _SnowClumps extends StatelessWidget {
  final Color color;
  const _SnowClumps({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _SnowClumpPainter(color: color),
    );
  }
}

class _SnowClumpPainter extends CustomPainter {
  final Color color;
  _SnowClumpPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back layer — subtle, large mounds
    _drawMoundLayer(
      canvas,
      size,
      mounds: [
        _Mound(cx: w * 0.05, baseY: h, height: h * 0.55, width: w * 0.30),
        _Mound(cx: w * 0.28, baseY: h, height: h * 0.45, width: w * 0.28),
        _Mound(cx: w * 0.52, baseY: h, height: h * 0.60, width: w * 0.32),
        _Mound(cx: w * 0.75, baseY: h, height: h * 0.50, width: w * 0.28),
        _Mound(cx: w * 0.95, baseY: h, height: h * 0.55, width: w * 0.25),
      ],
      opacity: 0.06,
    );

    // Mid layer
    _drawMoundLayer(
      canvas,
      size,
      mounds: [
        _Mound(cx: w * 0.0, baseY: h, height: h * 0.40, width: w * 0.22),
        _Mound(cx: w * 0.18, baseY: h, height: h * 0.50, width: w * 0.25),
        _Mound(cx: w * 0.40, baseY: h, height: h * 0.38, width: w * 0.22),
        _Mound(cx: w * 0.60, baseY: h, height: h * 0.48, width: w * 0.26),
        _Mound(cx: w * 0.82, baseY: h, height: h * 0.42, width: w * 0.24),
        _Mound(cx: w * 1.0, baseY: h, height: h * 0.45, width: w * 0.20),
      ],
      opacity: 0.09,
    );

    // Front layer — brightest, smallest mounds
    _drawMoundLayer(
      canvas,
      size,
      mounds: [
        _Mound(cx: w * 0.08, baseY: h, height: h * 0.28, width: w * 0.18),
        _Mound(cx: w * 0.25, baseY: h, height: h * 0.32, width: w * 0.20),
        _Mound(cx: w * 0.45, baseY: h, height: h * 0.26, width: w * 0.18),
        _Mound(cx: w * 0.64, baseY: h, height: h * 0.34, width: w * 0.22),
        _Mound(cx: w * 0.82, baseY: h, height: h * 0.28, width: w * 0.18),
        _Mound(cx: w * 0.96, baseY: h, height: h * 0.30, width: w * 0.16),
      ],
      opacity: 0.13,
    );

    // Tiny sparkle dots scattered across the clumps
    final r = Random(42); // fixed seed = consistent sparkles
    final sparklePaint = Paint()
      ..color = color.withOpacity(0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);
    for (int i = 0; i < 40; i++) {
      final sx = r.nextDouble() * w;
      final sy = h * 0.3 + r.nextDouble() * h * 0.7;
      final sr = 0.4 + r.nextDouble() * 1.2;
      canvas.drawCircle(Offset(sx, sy), sr, sparklePaint);
    }
  }

  void _drawMoundLayer(
    Canvas canvas,
    Size size, {
    required List<_Mound> mounds,
    required double opacity,
  }) {
    for (final m in mounds) {
      final path = Path();
      final rx = m.width / 2;
      // Elliptical bump sitting on the baseline
      path.addOval(
        Rect.fromCenter(
          center: Offset(m.cx, m.baseY - m.height * 0.45),
          width: rx * 2,
          height: m.height * 0.9,
        ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, m.width * 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(_SnowClumpPainter old) => old.color != color;
}

class _Mound {
  final double cx;
  final double baseY;
  final double height;
  final double width;
  const _Mound({
    required this.cx,
    required this.baseY,
    required this.height,
    required this.width,
  });
}
