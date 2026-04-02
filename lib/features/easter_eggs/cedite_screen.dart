import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

class CediteShadowScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const CediteShadowScreen({super.key, this.onUnlocked});

  @override
  State<CediteShadowScreen> createState() => _CediteShadowScreenState();
}

class _CediteShadowScreenState extends State<CediteShadowScreen> with TickerProviderStateMixin {
  final String _correct = 'DECITE';
  String _entered = '';
  bool _success = false;
  String? _errorMsg;
  int _failCount = 0;

  String _cediteLine = 'Truth is rarely what it seems...';
  bool _voiceVisible = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late AnimationController _voiceCtrl;
  late Animation<double> _voiceFade;

  final Set<String> _hintLetters = {'D', 'E', 'C', 'I', 'T'};

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    _voiceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
      CounselorPersonaService.markCediteUnlocked();
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        widget.onUnlocked?.call();
        Navigator.pop(context);
      }
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.cedite.primary(brightness);

    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
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
                          color: colors.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: colors.onSurface.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: pc.withOpacity(0.15), width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(CounselorPersona.cedite.avatarAsset(brightness)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'C E D I T E',
                    style: textTheme.headlineSmall?.copyWith(
                      color: pc,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'I am the truth you fear, and the lie you live...',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withOpacity(0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  // Voice line
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 16,
                    child: _voiceVisible
                        ? FadeTransition(
                            opacity: _voiceFade,
                            child: Text(
                              _cediteLine,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                color: pc.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 48),

                  // Passcode display
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (context, child) {
                      final dx = sin(_shakeAnim.value * pi * 6) * 8;
                      return Transform.translate(offset: Offset(dx, 0), child: child);
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
                            color: (_success && filled) ? pc : filled ? pc.withOpacity(0.8) : colors.onSurface.withOpacity(0.1),
                            border: Border.all(
                              color: filled ? pc.withOpacity(0.5) : colors.outline.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Error message
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _errorMsg != null
                        ? Text(
                            _errorMsg!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: pc.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          )
                        : const SizedBox(height: 0),
                  ),

                  const SizedBox(height: 48),

                  // Keyboard
                  ..._buildKeyboardRows(rows, colors, textTheme, pc),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildKeyboardRows(List<List<String>> rows, ColorScheme colors, TextTheme textTheme, Color pc) {
    const cellH = 52.0;
    const gap = 10.0;

    Widget keyCell(String char) {
      if (char == '⌫') {
        return GestureDetector(
          onTap: _delete,
          child: Container(
            height: cellH,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.backspace_outlined, size: 18, color: colors.onSurface.withOpacity(0.45)),
          ),
        );
      }

      final isHint = _hintLetters.contains(char);
      return GestureDetector(
        onTap: () => _press(char),
        child: Container(
          height: cellH,
          decoration: BoxDecoration(
            color: isHint ? pc.withOpacity(0.12) : colors.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHint ? pc.withOpacity(0.3) : colors.outline.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Text(
            char,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: isHint ? FontWeight.w700 : FontWeight.w600,
              color: isHint ? pc : colors.onSurface,
            ),
          ),
        ),
      );
    }

    final keyboardRows = <Widget>[];
    for (int row = 0; row < rows.length; row++) {
      final cells = <Widget>[];
      for (int col = 0; col < rows[row].length; col++) {
        cells.add(Expanded(child: keyCell(rows[row][col])));
        if (col < rows[row].length - 1) cells.add(const SizedBox(width: gap));
      }
      keyboardRows.add(Row(children: cells));
      if (row < rows.length - 1) keyboardRows.add(const SizedBox(height: gap));
    }

    return keyboardRows;
  }
}
