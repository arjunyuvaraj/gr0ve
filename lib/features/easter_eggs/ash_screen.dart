import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:gr0ve/features/counselor/services/persona_voice.dart';

class AshRuinScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const AshRuinScreen({super.key, this.onUnlocked});

  @override
  State<AshRuinScreen> createState() => _AshRuinScreenState();
}

class _AshRuinScreenState extends State<AshRuinScreen> with TickerProviderStateMixin {
  static const _target = 'grove';
  final List<String> _guesses = [];
  String _currentInput = '';
  bool _success = false;
  final int _tries = 6;

  String _ashLine = CounselorPersona.ash.lockedVoiceLine(unlocked: false);
  bool _voiceVisible = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late AnimationController _voiceCtrl;
  late Animation<double> _voiceFade;

  final Map<String, Color?> _keyStates = {};

  static const List<String> _dictionary = [
    'grove', 'adieu', 'stare', 'crane', 'slate', 'trace', 'react', 'about', 'above', 'abuse', 'admit', 'adopt', 'adult', 'after', 'again', 'agent', 'agree', 'ahead', 'alarm', 'album', 'alert', 'alive', 'allow', 'alone', 'along', 'alter', 'among', 'anger', 'angle', 'apart', 'apple', 'apply', 'arena', 'argue', 'arise', 'array', 'aside', 'asset', 'audio', 'audit', 'avoid', 'award', 'aware', 'basic', 'basis', 'beach', 'began', 'begin', 'being', 'below', 'bench', 'birth', 'black', 'blade', 'blame', 'blind', 'block', 'blood', 'board', 'boost', 'booth', 'bound', 'brain', 'brand', 'bread', 'break', 'breed', 'brief', 'bring', 'broad', 'broke', 'brown', 'build', 'built', 'buyer', 'cable', 'calif', 'carry', 'catch', 'cause', 'chain', 'chair', 'chart', 'chase', 'cheap', 'check', 'chest', 'chief', 'child', 'china', 'chose', 'civil', 'claim', 'class', 'clean', 'clear', 'click', 'clock', 'close', 'coach', 'coast', 'could', 'count', 'court', 'cover', 'craft', 'crash', 'cream', 'crime', 'cross', 'crowd', 'crown', 'curve', 'cycle', 'daily', 'dance', 'dated', 'dealt', 'death', 'debut', 'delay', 'depth', 'doing', 'doubt', 'dozen', 'draft', 'drama', 'drawn', 'dream', 'dress', 'drill', 'drink', 'drive', 'drove', 'dying', 'eager', 'early', 'earth', 'eight', 'elite', 'empty', 'enemy', 'enjoy', 'enter', 'entry', 'equal', 'error', 'event', 'every', 'exact', 'exist', 'extra', 'faith', 'false', 'fault', 'fiber', 'field', 'fifth', 'fifty', 'fight', 'final', 'first', 'fixed', 'flash', 'fleet', 'floor', 'fluid', 'focus', 'force', 'forth', 'forty', 'forum', 'found', 'frame', 'frank', 'fraud', 'fresh', 'front', 'fruit', 'fully', 'funny', 'giant', 'given', 'glass', 'globe', 'going', 'grace', 'grade', 'grand', 'grant', 'graph', 'grass', 'great', 'green', 'gross', 'group', 'grown', 'guard', 'guess', 'guest', 'guide', 'habit', 'happy', 'heart', 'heavy', 'hence', 'house', 'human', 'ideal', 'image', 'index', 'inner', 'input', 'issue', 'joint', 'judge', 'label', 'large', 'laser', 'later', 'laugh', 'layer', 'learn', 'lease', 'least', 'leave', 'legal', 'level', 'light', 'limit', 'links', 'lives', 'local', 'logic', 'loose', 'lower', 'lucky', 'lunch', 'lying', 'magic', 'major', 'maker', 'march', 'match', 'maybe', 'mayor', 'meant', 'media', 'metal', 'might', 'minor', 'minus', 'mixed', 'model', 'money', 'month', 'moral', 'motor', 'mount', 'mouse', 'mouth', 'movie', 'music', 'needs', 'never', 'newly', 'night', 'noise', 'north', 'noted', 'novel', 'nurse', 'occur', 'ocean', 'offer', 'often', 'order', 'other', 'ought', 'paint', 'panel', 'paper', 'party', 'peace', 'phase', 'phone', 'photo', 'piece', 'pilot', 'pitch', 'place', 'plain', 'plane', 'plant', 'plate', 'point', 'pound', 'power', 'press', 'price', 'pride', 'prime', 'print', 'prior', 'prize', 'proof', 'proud', 'prove', 'queen', 'quick', 'quiet', 'quite', 'radio', 'raise', 'range', 'rapid', 'ratio', 'reach', 'ready', 'refer', 'right', 'rival', 'river', 'robin', 'rough', 'round', 'route', 'royal', 'rural', 'scale', 'scene', 'scope', 'score', 'sense', 'serve', 'seven', 'shall', 'shape', 'share', 'sharp', 'sheet', 'shelf', 'shell', 'shift', 'shirt', 'shock', 'shoot', 'short', 'shown', 'sight', 'since', 'sixth', 'sixty', 'sized', 'skill', 'sleep', 'slide', 'small', 'smart', 'smile', 'smith', 'smoke', 'solid', 'solve', 'sorry', 'sound', 'south', 'space', 'spare', 'speak', 'speed', 'spend', 'spent', 'split', 'spoke', 'sport', 'staff', 'stage', 'stake', 'stand', 'start', 'state', 'steam', 'steel', 'stick', 'still', 'stock', 'stone', 'stood', 'store', 'storm', 'story', 'strip', 'stuck', 'study', 'stuff', 'style', 'sugar', 'suite', 'super', 'sweet', 'table', 'taken', 'taste', 'texas', 'thank', 'theft', 'their', 'theme', 'there', 'these', 'thick', 'thing', 'think', 'third', 'those', 'three', 'threw', 'throw', 'tight', 'times', 'tired', 'title', 'today', 'topic', 'total', 'touch', 'tough', 'tower', 'track', 'trade', 'train', 'treat', 'trend', 'trial', 'tried', 'tries', 'truck', 'trust', 'truth', 'twice', 'under', 'union', 'unity', 'until', 'upper', 'upset', 'urban', 'usage', 'usual', 'valid', 'value', 'video', 'virus', 'visit', 'vital', 'voice', 'waste', 'watch', 'water', 'wheel', 'where', 'which', 'while', 'white', 'whole', 'whose', 'woman', 'women', 'world', 'worry', 'worse', 'worst', 'worth', 'would', 'wound', 'write', 'wrong', 'wrote', 'yield', 'young', 'youth', 'zebra', 'trees', 'bloom', 'roots', 'seeds', 'plant', 'petal', 'trunk', 'flora', 'berry', 'leafy', 'shrub', 'woods', 'hello'
  ];

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

  void _onKeyPress(String key) {
    if (_success || _guesses.length >= _tries) return;
    
    if (key == '⌫') {
      if (_currentInput.isNotEmpty) {
        setState(() => _currentInput = _currentInput.substring(0, _currentInput.length - 1));
        HapticFeedback.lightImpact();
      }
    } else if (key == 'ENTER') {
      if (_currentInput.length == 5) {
        if (_dictionary.contains(_currentInput.toLowerCase())) {
          _submitGuess();
        } else {
          _shakeCtrl.forward(from: 0);
          HapticFeedback.vibrate();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Not in word list'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.black.withOpacity(0.8),
            ),
          );
        }
      } else {
        _shakeCtrl.forward(from: 0);
        HapticFeedback.vibrate();
      }
    } else if (_currentInput.length < 5) {
      setState(() => _currentInput += key.toLowerCase());
      HapticFeedback.selectionClick();
    }
  }

  Color _getFeedbackColor(String char, int index) {
    if (_target[index] == char) return const Color(0xFFC43D3D);
    if (_target.contains(char)) return const Color(0xFFFFB347);
    return Colors.grey[700]!;
  }

  void _submitGuess() async {
    final guess = _currentInput;
    setState(() => _guesses.add(guess));
    _currentInput = '';

    for (String char in guess.split('')) {
      if (_target.contains(char)) {
        setState(() => _keyStates[char] = _getFeedbackColor(char, guess.indexOf(char)));
      } else {
        setState(() => _keyStates[char] ??= Colors.grey[700]);
      }
    }

    if (guess == _target) {
      HapticFeedback.heavyImpact();
      setState(() => _success = true);
      CounselorPersonaService.markAshUnlocked();
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        widget.onUnlocked?.call();
        Navigator.pop(context);
      }
    } else if (_guesses.length >= _tries) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The word was: $_target'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black.withOpacity(0.8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.ash.primary(brightness);

    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          Positioned.fill(child: _FullScreenEmbers(color: pc)),
          Positioned(left: 0, right: 0, bottom: 0, child: _AshMounds(color: pc)),
          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      _buildHeader(context, colors, pc, brightness, textTheme),
                      const Spacer(),
                      _buildGrid(colors, textTheme, pc),
                      const Spacer(),
                      _buildKeyboard(rows, colors, textTheme, pc),
                      const SizedBox(height: 20),
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

  Widget _buildHeader(BuildContext context, ColorScheme colors, Color pc, Brightness brightness, TextTheme textTheme) {
    return Column(
      children: [
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
        const SizedBox(height: 10),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pc.withOpacity(0.08),
            boxShadow: [BoxShadow(color: pc.withOpacity(0.15), blurRadius: 30, spreadRadius: -5)],
          ),
          child: ClipOval(
            child: Image.asset(
              CounselorPersona.ash.avatarAsset(brightness),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 18,
          child: _voiceVisible
              ? FadeTransition(
                  opacity: _voiceFade,
                  child: Text(
                    _ashLine,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: pc.withOpacity(0.6), fontStyle: FontStyle.italic, fontSize: 11),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildGrid(ColorScheme colors, TextTheme textTheme, Color pc) {
    return Column(
      children: [
        Text(
          'THE BURNING GROVE',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: pc, letterSpacing: 4),
        ),
        const SizedBox(height: 8),
        Text(
          'The future is already silent...',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withOpacity(0.3), fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 28),
        Column(
          children: List.generate(6, (guessIndex) {
            final guess = guessIndex < _guesses.length ? _guesses[guessIndex] : '';
            final isCurrentRow = guessIndex == _guesses.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) {
                  final dx = isCurrentRow ? sin(_shakeAnim.value * pi * 6) * 8 : 0.0;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (charIndex) {
                    final char = guessIndex < _guesses.length ? _guesses[guessIndex][charIndex] : '';
                    final currentChar = isCurrentRow && charIndex < _currentInput.length ? _currentInput[charIndex] : '';
                    final displayChar = char.isNotEmpty ? char : currentChar;
                    
                    final statusColor = guess.isNotEmpty && charIndex < guess.length
                        ? _getFeedbackColor(guess[charIndex], charIndex)
                        : null;

                    return _WordleLetterBox(
                      char: displayChar,
                      statusColor: statusColor,
                      colors: colors,
                      pc: pc,
                      size: 58,
                    );
                  }),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildKeyboard(List<List<String>> rows, ColorScheme colors, TextTheme textTheme, Color pc) {
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((char) {
              final isBack = char == '⌫';
              final keyColor = _keyStates[char.toLowerCase()];

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _onKeyPress(char),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: keyColor?.withOpacity(0.7) ?? colors.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: keyColor?.withOpacity(0.3) ?? colors.outline.withOpacity(0.07),
                          width: keyColor != null ? 1 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isBack
                          ? Icon(Icons.backspace_outlined, size: 16, color: colors.onSurface.withOpacity(0.45))
                          : Text(
                              char,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: keyColor != null ? FontWeight.w700 : FontWeight.w600,
                                color: keyColor != null ? Colors.white : colors.onSurface,
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
}

class _WordleLetterBox extends StatelessWidget {
  final String char;
  final Color? statusColor;
  final ColorScheme colors;
  final Color pc;
  final double size;

  const _WordleLetterBox({
    required this.char,
    required this.statusColor,
    required this.colors,
    required this.pc,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: statusColor?.withOpacity(0.9) ?? colors.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor?.withOpacity(0.4) ?? (char.isNotEmpty ? pc.withOpacity(0.3) : colors.outline.withOpacity(0.1)),
          width: 1,
        ),
        boxShadow: statusColor != null ? [BoxShadow(color: statusColor!.withOpacity(0.3), blurRadius: 8)] : null,
      ),
      alignment: Alignment.center,
      child: Text(
        char.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.45,
          fontWeight: FontWeight.w900,
          color: statusColor != null ? Colors.white : colors.onSurface,
        ),
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

class _FullScreenEmbersState extends State<_FullScreenEmbers> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Spark> _sparks;
  
  @override
  void initState() {
    super.initState();
    _sparks = List.generate(40, (_) => _Spark());
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))
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
    return CustomPaint(painter: _EmberPainter(sparks: _sparks, elapsed: _ctrl.value * 10, color: widget.color));
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
  
  _EmberPainter({required this.sparks, required this.elapsed, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final progress = ((elapsed / s.period) + s.phase) % 1.0;
      final y = (1.0 - progress) * size.height;
      final x = (s.x + s.drift * progress) * size.width + sin(elapsed * 2 + s.phase * 10) * 10;
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
    return CustomPaint(size: const Size(double.infinity, 120), painter: _AshMoundPainter(color: color));
  }
}

class _AshMoundPainter extends CustomPainter {
  final Color color;
  _AshMoundPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(456);
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    for (int i = 0; i < 8; i++) {
      final x = (i / 7) * size.width;
      final h = 30 + r.nextDouble() * 40;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, size.height), width: size.width * 0.35, height: h * 2),
        paint..color = color.withOpacity(0.06),
      );
    }
  }
  
  @override
  bool shouldRepaint(_AshMoundPainter old) => false;
}
