import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';

class AshUnlockService {
  static const _field = 'ash_unlocked';

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

String ashVoiceLine({required bool unlocked}) {
  return CounselorPersona.ash.lockedVoiceLine(unlocked: unlocked);
}

class AshRuinScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const AshRuinScreen({super.key, this.onUnlocked});

  @override
  State<AshRuinScreen> createState() => _AshRuinScreenState();
}

class _AshRuinScreenState extends State<AshRuinScreen> {
  bool _checking = true;
  bool _alreadyUnlocked = false;
  bool _isLockedForever = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final unlocked = await AshUnlockService.checkUnlocked();
    final lockedForever = CounselorPersonaService.ashLockedForever;
    if (!mounted) return;
    setState(() {
      _alreadyUnlocked = unlocked;
      _isLockedForever = lockedForever;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pc = CounselorPersona.ash.primary(Theme.of(context).brightness);

    if (_checking) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: pc, strokeWidth: 2),
        ),
      );
    }

    if (_isLockedForever) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "THE FUTURE IS SEALED",
            style: TextStyle(
              color: Colors.red.withOpacity(0.5),
              letterSpacing: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    if (_alreadyUnlocked) {
      return AshRevealScreen(onContinue: widget.onUnlocked);
    }

    return _PassphraseScreen(
      onUnlocked: () {
        setState(() => _alreadyUnlocked = true);
        widget.onUnlocked?.call();
      },
    );
  }
}

class _PassphraseScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _PassphraseScreen({required this.onUnlocked});

  @override
  State<_PassphraseScreen> createState() => _PassphraseScreenState();
}

class _PassphraseScreenState extends State<_PassphraseScreen>
    with TickerProviderStateMixin {
  static const _correct = 'GROVE';
  static const int _maxGuesses = 5;

  final List<String> _guesses = [];
  String _currentEntry = '';
  bool _success = false;
  bool _failedPermanently = false;
  String? _errorMsg;

  String _ashLine = '...';
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

    _ashLine = ashVoiceLine(unlocked: false);
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
    if (_guesses.length >= _maxGuesses || _success || _failedPermanently)
      return;
    if (_currentEntry.length < 5) {
      setState(() {
        _currentEntry += char.toUpperCase();
        _errorMsg = null;
      });
      HapticFeedback.selectionClick();
    }
    if (_currentEntry.length == 5) {
      _submit();
    }
  }

  void _delete() {
    if (_currentEntry.isEmpty || _success || _failedPermanently) return;
    setState(
      () =>
          _currentEntry = _currentEntry.substring(0, _currentEntry.length - 1),
    );
    HapticFeedback.lightImpact();
  }

  Future<void> _submit() async {
    final guess = _currentEntry;
    _guesses.add(guess);
    _currentEntry = '';

    if (guess == _correct) {
      HapticFeedback.heavyImpact();
      setState(() => _success = true);
      await AshUnlockService.markUnlocked();
      CounselorPersonaService.markAshUnlocked();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) widget.onUnlocked();
    } else {
      if (_guesses.length >= _maxGuesses) {
        setState(() {
          _failedPermanently = true;
          _errorMsg = 'The future is lost to you.';
        });
        HapticFeedback.vibrate();
        await CounselorPersonaService.lockAshForever();
        await Future.delayed(const Duration(milliseconds: 2000));
        if (mounted) Navigator.pop(context);
      } else {
        HapticFeedback.vibrate();
        _shakeCtrl.forward(from: 0);
        setState(() {
          _errorMsg = _failMessage(_guesses.length);
        });
      }
    }
  }

  String _failMessage(int n) {
    if (n == 1) return 'The ashes do not recognize you.';
    if (n == 2) return 'A spark of error.';
    if (n == 3) return 'You are grasping at smoke.';
    if (n == 4) return 'The flame is flickering out.';
    return 'The fire has already died.';
  }

  Color _dotColor(
    String letter,
    int index,
    String correct,
    ColorScheme colors,
    Color pc,
  ) {
    if (correct[index] == letter) return Colors.green;
    if (correct.contains(letter)) return Colors.orangeAccent;
    return colors.onSurface.withOpacity(0.15);
  }

  Widget _buildGrid(ColorScheme colors, Color pc) {
    return Column(
      children: List.generate(_maxGuesses, (rowIdx) {
        final hasGuess = rowIdx < _guesses.length;
        final isCurrent = rowIdx == _guesses.length;
        final guessText = hasGuess
            ? _guesses[rowIdx]
            : (isCurrent ? _currentEntry : '');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (colIdx) {
              final hasLetter = colIdx < guessText.length;
              Color color = colors.onSurface.withOpacity(0.05);
              double blur = 0;

              if (hasGuess) {
                color = _dotColor(
                  guessText[colIdx],
                  colIdx,
                  _correct,
                  colors,
                  pc,
                );
                if (color != colors.onSurface.withOpacity(0.15)) blur = 4;
              } else if (isCurrent && hasLetter) {
                color = pc.withOpacity(0.4);
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: blur > 0
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: blur,
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: isCurrent && colIdx == guessText.length
                        ? pc.withOpacity(0.5)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
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
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
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
    final pc = CounselorPersona.ash.primary(brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _FullScreenEmbers(color: pc)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AshMounds(color: pc),
          ),
          SafeArea(
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
                                  color: colors.surfaceContainerHighest
                                      .withOpacity(0.5),
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
                          const SizedBox(height: 30),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: pc.withOpacity(0.08),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                CounselorPersona.ash.avatarAsset(brightness),
                                width: 64,
                                height: 64,
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
                                      _ashLine,
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
                          const SizedBox(height: 12),
                          Text(
                            'The Burning Grove',
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.onSurface,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Access is high stakes. Do not fail.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.38),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: _shakeAnim,
                            builder: (context, child) {
                              final dx = sin(_shakeAnim.value * pi * 6) * 8;
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: _buildGrid(colors, pc),
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
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
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

class AshRevealScreen extends StatefulWidget {
  final VoidCallback? onContinue;
  const AshRevealScreen({super.key, this.onContinue});

  @override
  State<AshRevealScreen> createState() => _AshRevealScreenState();
}

class _AshRevealScreenState extends State<AshRevealScreen>
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
    final pc = CounselorPersona.ash.primary(brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _FullScreenEmbers(color: pc)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _AshMounds(color: pc),
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
                                CounselorPersona.ash.avatarAsset(brightness),
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
                              'Ash',
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
                                'Future',
                                style: textTheme.labelSmall?.copyWith(
                                  color: pc,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The Burning Grove',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withOpacity(0.3),
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              '''Born from the ashes of what is yet to come.
Every probability calculated. Every risk assessed.
If there is a path forward, she sees it.

Cold. Pragmatic. Forward-thinking.

She does not care about the past.
She prepares you for the inevitable.''',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.55),
                                height: 1.75,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _RevealTrait(
                              label: 'Visionary.',
                              sub:
                                  'She anticipates consequences before they unfold.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _RevealTrait(
                              label: 'Uncompromising.',
                              sub: 'She does not coddle delays or excuses.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _RevealTrait(
                              label: 'Strategy & preparation.',
                              sub:
                                  'College planning. Long-term goals. Forecasting.',
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
                              foregroundColor: CounselorPersona.ash.onPrimary(
                                brightness,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Speak with Ash',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      const SizedBox(height: 60),
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

class _FullScreenEmbers extends StatefulWidget {
  final Color color;
  const _FullScreenEmbers({required this.color});
  @override
  State<_FullScreenEmbers> createState() => _FullScreenEmbersState();
}

class _FullScreenEmbersState extends State<_FullScreenEmbers>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    _sparks = List.generate(40, (_) => _Spark());
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
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
    return CustomPaint(
      painter: _EmberPainter(
        sparks: _sparks,
        elapsed: _ctrl.value * 10,
        color: widget.color,
      ),
    );
  }
}

class _Spark {
  final double x = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 6.0 + Random().nextDouble() * 4.0;
  final double radius = 0.5 + Random().nextDouble() * 1.5;
  final double opacity = 0.1 + Random().nextDouble() * 0.4;
  final double drift = (Random().nextDouble() - 0.5) * 0.15;
}

class _EmberPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double elapsed;
  final Color color;

  _EmberPainter({
    required this.sparks,
    required this.elapsed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final progress = ((elapsed / s.period) + s.phase) % 1.0;
      final y = (1.0 - progress) * size.height;
      final x =
          (s.x + s.drift * progress) * size.width +
          sin(elapsed * 2 + s.phase * 10) * 10;
      canvas.drawCircle(
        Offset(x, y),
        s.radius,
        Paint()
          ..color = color.withOpacity(s.opacity * (1.0 - progress))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => true;
}

class _AshMounds extends StatelessWidget {
  final Color color;
  const _AshMounds({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 120),
      painter: _AshMoundPainter(color: color),
    );
  }
}

class _AshMoundPainter extends CustomPainter {
  final Color color;
  _AshMoundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(456);
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    for (int i = 0; i < 8; i++) {
      final x = (i / 7) * size.width;
      final h = 30 + r.nextDouble() * 40;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, size.height),
          width: size.width * 0.35,
          height: h * 2,
        ),
        paint..color = color.withOpacity(0.06),
      );
    }
  }

  @override
  bool shouldRepaint(_AshMoundPainter old) => false;
}
