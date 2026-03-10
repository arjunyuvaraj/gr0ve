import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

// ─────────────────────────────────────────────────────────────
// ASH UNLOCK SERVICE
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// ASH VOICE LINES
// ─────────────────────────────────────────────────────────────

const _ashSilentLines = [
  'What remains when everything else burns.',
  'Piece by piece.',
  'The answer is already here.',
  'Fragments of what was.',
  'Reconstruct what was lost.',
  '...',
  'The whole from the parts.',
];

const _ashRevealLines = [
  'You rebuilt what burned.',
  'Form restored from ash.',
  'The grove stands again.',
  'What was scattered is whole.',
];

String ashVoiceLine({required bool unlocked}) {
  final r = Random();
  final lines = unlocked ? _ashRevealLines : _ashSilentLines;
  if (!unlocked && r.nextDouble() < 0.15) return '...';
  return lines[r.nextInt(lines.length)];
}

// ─────────────────────────────────────────────────────────────
// ASH SCREEN — entry point
// ─────────────────────────────────────────────────────────────

class AshScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const AshScreen({super.key, this.onUnlocked});

  @override
  State<AshScreen> createState() => _AshScreenState();
}

class _AshScreenState extends State<AshScreen> {
  bool _checking = true;
  bool _alreadyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final unlocked = await AshUnlockService.checkUnlocked();
    if (!mounted) return;
    setState(() {
      _alreadyUnlocked = unlocked;
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

    if (_alreadyUnlocked) {
      return AshRevealScreen(onContinue: widget.onUnlocked);
    }

    return _AshGridPuzzleScreen(
      onUnlocked: () {
        setState(() => _alreadyUnlocked = true);
        widget.onUnlocked?.call();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRID PUZZLE SCREEN — 4x4 sliding tile puzzle
// ─────────────────────────────────────────────────────────────

class _AshGridPuzzleScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const _AshGridPuzzleScreen({required this.onUnlocked});

  @override
  State<_AshGridPuzzleScreen> createState() => _AshGridPuzzleScreenState();
}

class _AshGridPuzzleScreenState extends State<_AshGridPuzzleScreen>
    with TickerProviderStateMixin {
  // 4x4 grid = 16 tiles (0-15, where 15 is empty)
  List<int> _tiles = [];
  int _emptyIndex = 15;
  int _moveCount = 0;
  bool _success = false;

  String _ashLine = '...';
  bool _voiceVisible = false;

  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late AnimationController _voiceCtrl;
  late Animation<double> _voiceFade;
  late AnimationController _emberCtrl;

  @override
  void initState() {
    super.initState();

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

    _emberCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..addListener(() => setState(() {}))
          ..repeat();

    _ashLine = ashVoiceLine(unlocked: false);
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _voiceVisible = true);
      _voiceCtrl.forward();
    });

    _initializePuzzle();
  }

  void _initializePuzzle() {
    // Start with solved state: 0-14 are tiles, 15 is empty
    _tiles = List.generate(16, (i) => i);
    _emptyIndex = 15;
    // Shuffle with guaranteed solvable configuration and ensure not solved
    _shuffle();
  }

  void _shuffle() {
    // Perform random valid moves to ensure solvability
    // Using valid moves guarantees the puzzle is always solvable
    final random = Random();
    // Do at least 200 moves to ensure thorough scrambling
    for (int i = 0; i < 200; i++) {
      final validMoves = _getValidMoves();
      if (validMoves.isNotEmpty) {
        final move = validMoves[random.nextInt(validMoves.length)];
        _moveTile(move, counting: false);
      }
    }

    // Check if accidentally solved (very rare but possible)
    // If so, do more moves
    int attempts = 0;
    while (_isSolved() && attempts < 5) {
      for (int i = 0; i < 20; i++) {
        final validMoves = _getValidMoves();
        if (validMoves.isNotEmpty) {
          final move = validMoves[random.nextInt(validMoves.length)];
          _moveTile(move, counting: false);
        }
      }
      attempts++;
    }

    setState(() {
      _moveCount = 0;
    });
  }

  bool _isSolved() {
    for (int i = 0; i < 16; i++) {
      if (_tiles[i] != i) return false;
    }
    return true;
  }

  // Check if current configuration is solvable
  // A 15-puzzle is solvable if the number of inversions is even
  bool _isSolvable() {
    int inversions = 0;
    final tilesWithoutEmpty = _tiles.where((t) => t != 15).toList();

    for (int i = 0; i < tilesWithoutEmpty.length; i++) {
      for (int j = i + 1; j < tilesWithoutEmpty.length; j++) {
        if (tilesWithoutEmpty[i] > tilesWithoutEmpty[j]) {
          inversions++;
        }
      }
    }

    // For 4x4 grid with empty space, puzzle is solvable if:
    // - inversions is even when empty space is on odd row from bottom
    // - inversions is odd when empty space is on even row from bottom
    final emptyRow = _emptyIndex ~/ 4;
    final rowFromBottom = 3 - emptyRow;

    if (rowFromBottom % 2 == 1) {
      return inversions % 2 == 0;
    } else {
      return inversions % 2 == 1;
    }
  }

  List<int> _getValidMoves() {
    final moves = <int>[];
    final row = _emptyIndex ~/ 4;
    final col = _emptyIndex % 4;

    // Can move tile from above
    if (row > 0) moves.add(_emptyIndex - 4);
    // Can move tile from below
    if (row < 3) moves.add(_emptyIndex + 4);
    // Can move tile from left
    if (col > 0) moves.add(_emptyIndex - 1);
    // Can move tile from right
    if (col < 3) moves.add(_emptyIndex + 1);

    return moves;
  }

  void _moveTile(int tileIndex, {bool counting = true}) {
    if (_success) return;

    final validMoves = _getValidMoves();
    if (!validMoves.contains(tileIndex)) return;

    setState(() {
      _tiles[_emptyIndex] = _tiles[tileIndex];
      _tiles[tileIndex] = 15;
      _emptyIndex = tileIndex;
      if (counting) {
        _moveCount++;
        HapticFeedback.selectionClick();
      }
    });

    _checkWin();
  }

  void _checkWin() {
    if (_isSolved() && !_success) {
      HapticFeedback.heavyImpact();
      setState(() => _success = true);
      _onSolved();
    }
  }

  Future<void> _onSolved() async {
    await AshUnlockService.markUnlocked();
    CounselorPersonaService.markAshUnlocked();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) widget.onUnlocked();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _voiceCtrl.dispose();
    _emberCtrl.dispose();
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
          // Burning embers background
          const Positioned.fill(child: _BurningEmbersBackground()),

          SafeArea(
            child: FadeTransition(
              opacity: _entryFade,
              child: SlideTransition(
                position: _entrySlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
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
                            CounselorPersona.ash.avatarAsset(brightness),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
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

                      const SizedBox(height: 18),

                      Text(
                        'What Remains',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rebuild the grove from ash.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.38),
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Move counter
                      Text(
                        'Moves: $_moveCount',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 4x4 Grid Puzzle
                      _buildPuzzleGrid(colors, pc, brightness),

                      const SizedBox(height: 24),

                      // Shuffle button
                      OutlinedButton.icon(
                        onPressed: _shuffle,
                        icon: Icon(
                          Icons.shuffle_rounded,
                          size: 16,
                          color: colors.onSurface.withOpacity(0.5),
                        ),
                        label: Text(
                          'Shuffle',
                          style: TextStyle(
                            color: colors.onSurface.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: colors.outline.withOpacity(0.2),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        'tap tiles to move them',
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

  Widget _buildPuzzleGrid(ColorScheme colors, Color pc, Brightness brightness) {
    final size = MediaQuery.of(context).size.width - 56;
    final tileSize = size / 4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: 16,
          itemBuilder: (context, index) {
            final tileValue = _tiles[index];

            // Tile 15 is the empty space - make it clearly visible
            if (tileValue == 15) {
              return Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withOpacity(0.5),
                  border: Border.all(color: pc.withOpacity(0.2), width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 24,
                    color: pc.withOpacity(0.3),
                  ),
                ),
              );
            }

            // Show tiles 0-14
            return GestureDetector(
              onTap: () => _moveTile(index),
              child: _buildTile(tileValue, tileSize, colors, pc, brightness),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(
    int tileValue,
    double tileSize,
    ColorScheme colors,
    Color pc,
    Brightness brightness,
  ) {
    final row = tileValue ~/ 4;
    final col = tileValue % 4;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _success ? pc.withOpacity(0.1) : colors.surface,
        border: Border.all(
          color: _success
              ? pc.withOpacity(0.3)
              : colors.outline.withOpacity(0.15),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(-1 + (col * 2 / 3), -1 + (row * 2 / 3)),
          maxWidth: tileSize * 4,
          maxHeight: tileSize * 4,
          child: Image.asset(
            CounselorPersona.ash.avatarAsset(brightness),
            width: tileSize * 4,
            height: tileSize * 4,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ASH REVEAL SCREEN
// ─────────────────────────────────────────────────────────────

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
          const Positioned.fill(child: _BurningEmbersBackground()),
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
                                'Clarity',
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
                              'Ash speaks in stillness.\n'
                              'No warmth. No coldness.\n\n'
                              'What you ask is rarely what you mean.\n'
                              'Ash answers both.\n\n'
                              'Minimal. Precise. Final.',
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withOpacity(0.55),
                                height: 1.75,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _AshRevealTrait(
                              label: 'Reframes your question.',
                              sub:
                                  '"What you\'re actually asking is..." — then answers that.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _AshRevealTrait(
                              label: 'No performance.',
                              sub:
                                  'No reassurance. No encouragement. Just clarity.',
                              pc: pc,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                            _AshRevealTrait(
                              label: 'The quiet voice.',
                              sub:
                                  'When everyone else is loud, Ash speaks once and stops.',
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

class _AshRevealTrait extends StatelessWidget {
  const _AshRevealTrait({
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
// BURNING EMBERS BACKGROUND
// ─────────────────────────────────────────────────────────────

class _BurningEmbersBackground extends StatefulWidget {
  const _BurningEmbersBackground();

  @override
  State<_BurningEmbersBackground> createState() =>
      _BurningEmbersBackgroundState();
}

class _BurningEmbersBackgroundState extends State<_BurningEmbersBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Ember> _embers;

  @override
  void initState() {
    super.initState();
    _embers = List.generate(40, (_) => _Ember());
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
    final brightness = Theme.of(context).brightness;
    final pc = CounselorPersona.ash.primary(brightness);

    return CustomPaint(
      painter: _EmbersPainter(
        embers: _embers,
        elapsed: _ctrl.value * 10.0,
        color: pc,
      ),
    );
  }
}

class _Ember {
  final double x = Random().nextDouble();
  final double phase = Random().nextDouble();
  final double period = 8.0 + Random().nextDouble() * 6.0;
  final double radius = 0.6 + Random().nextDouble() * 2.0;
  final double opacity = 0.08 + Random().nextDouble() * 0.15;
  final double drift = (Random().nextDouble() - 0.5) * 0.08;
  final double riseSpeed = 0.3 + Random().nextDouble() * 0.4;
}

class _EmbersPainter extends CustomPainter {
  final List<_Ember> embers;
  final double elapsed;
  final Color color;

  _EmbersPainter({
    required this.embers,
    required this.elapsed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in embers) {
      final progress = ((elapsed * e.riseSpeed / e.period) + e.phase) % 1.0;
      final y = size.height - (progress * size.height);
      final x = (e.x + e.drift * progress) * size.width;
      final fade = progress < 0.1
          ? progress / 0.1
          : progress > 0.9
          ? (1.0 - progress) / 0.1
          : 1.0;

      canvas.drawCircle(
        Offset(x, y),
        e.radius,
        Paint()
          ..color = color.withOpacity(e.opacity * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }
  }

  @override
  bool shouldRepaint(_EmbersPainter old) => old.elapsed != elapsed;
}
