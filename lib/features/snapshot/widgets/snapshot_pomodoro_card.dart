import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_shared.dart';

// ════════════════════════════════════════════════════════════════
// POMODORO PREFS  (unchanged logic)
// ════════════════════════════════════════════════════════════════

class PomPrefs {
  final int focus, shortB, longB;
  const PomPrefs({this.focus = 25, this.shortB = 5, this.longB = 15});
  PomPrefs cp({int? f, int? s, int? l}) =>
      PomPrefs(focus: f ?? focus, shortB: s ?? shortB, longB: l ?? longB);
}

class PomPrefsService {
  static final prefs = ValueNotifier(const PomPrefs());

  static Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('pomodoro')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        prefs.value = PomPrefs(
          focus: data['focus'] ?? 25,
          shortB: data['shortB'] ?? 5,
          longB: data['longB'] ?? 15,
        );
      }
    } catch (_) {}
  }

  static Future<void> save(PomPrefs v) async {
    prefs.value = v;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('pomodoro')
          .set({
            'focus': v.focus,
            'shortB': v.shortB,
            'longB': v.longB,
          }, SetOptions(merge: true));
    } catch (_) {}
  }
}

// ════════════════════════════════════════════════════════════════
// INTERNAL ENUMS
// ════════════════════════════════════════════════════════════════

enum _PM {
  focus,
  shortB,
  longB;

  String get label => const ['Focus', 'Short Break', 'Long Break'][index];
  String get shortLabel => const ['Focus', 'Short', 'Long'][index];
  int secs(PomPrefs p) => [p.focus * 60, p.shortB * 60, p.longB * 60][index];

  // Gold accent for focus, muted tones for breaks — consistent with gr0ve theme
  Color activeColor(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return switch (this) {
      _PM.focus => c.primary, // app gold
      _PM.shortB => const Color(0xFF7CB9A8), // muted sage
      _PM.longB => const Color(0xFF8B9DC3), // muted slate-blue
    };
  }
}

// ════════════════════════════════════════════════════════════════
// CARD: POMODORO  (redesigned)
// ════════════════════════════════════════════════════════════════

class SnapshotPomodoroCard extends StatefulWidget {
  final bool compact;
  const SnapshotPomodoroCard({super.key, this.compact = false});

  @override
  State<SnapshotPomodoroCard> createState() => _SnapshotPomodoroCardState();
}

class _SnapshotPomodoroCardState extends State<SnapshotPomodoroCard>
    with TickerProviderStateMixin {
  _PM _mode = _PM.focus;
  int _left = 25 * 60;
  int _sessions = 0;
  bool _run = false;
  bool _editP = false;
  Timer? _t;
  late PomPrefs _draft;

  // Subtle breathing glow when timer is running
  late final AnimationController _glowAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final Animation<double> _glowAnim = CurvedAnimation(
    parent: _glowAc,
    curve: Curves.easeInOut,
  );

  // Slide-in for settings panel
  late final AnimationController _settingsAc = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    _draft = PomPrefsService.prefs.value;
    // ── FIX: read from prefs correctly on first load ──
    _left = _mode.secs(PomPrefsService.prefs.value);
    PomPrefsService.prefs.addListener(_onPref);
  }

  void _onPref() {
    if (!_run) setState(() => _left = _mode.secs(PomPrefsService.prefs.value));
  }

  @override
  void dispose() {
    _t?.cancel();
    _glowAc.dispose();
    _settingsAc.dispose();
    PomPrefsService.prefs.removeListener(_onPref);
    super.dispose();
  }

  void _setMode(_PM m) {
    _t?.cancel();
    _glowAc.stop();
    setState(() {
      _mode = m;
      _left = m.secs(PomPrefsService.prefs.value);
      _run = false;
    });
  }

  void _toggle() {
    if (_left == 0) {
      _setMode(_mode);
      return;
    }
    if (_run) {
      _t?.cancel();
      _glowAc.stop();
      setState(() => _run = false);
    } else {
      setState(() => _run = true);
      _glowAc.repeat(reverse: true);
      _t = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_left > 0) {
            _left--;
          } else {
            _t?.cancel();
            _glowAc.stop();
            _run = false;
            if (_mode == _PM.focus) _sessions++;
          }
        });
      });
    }
  }

  Future<void> _savePref() async {
    await PomPrefsService.save(_draft);
    setState(() {
      _editP = false;
      _settingsAc.reverse();
      _setMode(_mode);
    });
  }

  void _toggleSettings() {
    setState(() => _editP = !_editP);
    if (_editP) {
      _draft = PomPrefsService.prefs.value;
      _settingsAc.forward();
    } else {
      _settingsAc.reverse();
    }
  }

  String get _timeString =>
      '${(_left ~/ 60).toString().padLeft(2, '0')}:${(_left % 60).toString().padLeft(2, '0')}';

  double get _progress {
    final p = PomPrefsService.prefs.value;
    final total = _mode.secs(p);
    return total == 0 ? 0.0 : (1 - _left / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final mColor = _mode.activeColor(ctx);
    final p = PomPrefsService.prefs.value;

    return ValueListenableBuilder<PomPrefs>(
      valueListenable: PomPrefsService.prefs,
      builder: (_, __, ___) => Column(
        children: [
          // ── Mode selector ─────────────────────────────────────
          _ModeSelector(
            current: _mode,
            onSelect: _setMode,
            activeColor: mColor,
            cs: cs,
          ),

          const SizedBox(height: 10),

          // ── Main card ─────────────────────────────────────────
          SnapshotTile(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Top row: ring + side controls
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Progress rounded-rect ──────────────────
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, child) {
                        final glow = _run ? _glowAnim.value * 0.22 : 0.0;
                        return Container(
                          width: 104,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _run
                                ? [
                                    BoxShadow(
                                      color: mColor.withOpacity(glow),
                                      blurRadius: 28,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: child,
                        );
                      },
                      child: CustomPaint(
                        painter: _RRectPainter(
                          progress: _progress,
                          color: mColor,
                          track: cs.onSurface.withOpacity(0.06),
                          strokeWidth: 5,
                          radius: 22,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _timeString,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  height: 1,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _ModePill(
                                label: _mode.shortLabel.toUpperCase(),
                                color: mColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 18),

                    // ── Right side ─────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Play/pause button — full width, prominent
                          _PlayButton(
                            running: _run,
                            done: _left == 0,
                            color: mColor,
                            onTap: _toggle,
                          ),

                          const SizedBox(height: 10),

                          // Reset + settings row
                          Row(
                            children: [
                              _SmallButton(
                                icon: Icons.refresh_rounded,
                                onTap: () => _setMode(_mode),
                                cs: cs,
                                tooltip: 'Reset',
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _SmallButton(
                                  icon: Icons.tune_rounded,
                                  label:
                                      '${p.focus}m · ${p.shortB}m · ${p.longB}m',
                                  onTap: _toggleSettings,
                                  cs: cs,
                                  active: _editP,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Session dots ───────────────────────────────
                if (_sessions > 0 || true) ...[
                  const SizedBox(height: 16),
                  _SessionDots(sessions: _sessions, color: mColor, cs: cs),
                ],
              ],
            ),
          ),

          // ── Settings panel ─────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _editP
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _SettingsPanel(
                      draft: _draft,
                      cs: cs,
                      onChanged: (d) => setState(() => _draft = d),
                      onCancel: () {
                        setState(() => _editP = false);
                        _settingsAc.reverse();
                      },
                      onSave: _savePref,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ════════════════════════════════════════════════════════════════

/// Three-tab mode selector with animated indicator
class _ModeSelector extends StatelessWidget {
  final _PM current;
  final ValueChanged<_PM> onSelect;
  final Color activeColor;
  final ColorScheme cs;
  const _ModeSelector({
    required this.current,
    required this.onSelect,
    required this.activeColor,
    required this.cs,
  });

  @override
  Widget build(BuildContext ctx) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.07)),
      ),
      child: Row(
        children: _PM.values.map((m) {
          final active = current == m;
          final mC = m.activeColor(ctx);
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(right: m == _PM.longB ? 0 : 4),
                decoration: BoxDecoration(
                  color: active ? mC.withOpacity(0.14) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active ? mC.withOpacity(0.3) : Colors.transparent,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  m.shortLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? mC : cs.onSurface.withOpacity(0.35),
                    letterSpacing: active ? 0.2 : 0,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Pill label inside the ring
class _ModePill extends StatelessWidget {
  final String label;
  final Color color;
  const _ModePill({required this.label, required this.color});

  @override
  Widget build(BuildContext ctx) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.13),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.2), width: 0.8),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: color,
      ),
    ),
  );
}

/// Big start/pause button
class _PlayButton extends StatelessWidget {
  final bool running, done;
  final Color color;
  final VoidCallback onTap;
  const _PlayButton({
    required this.running,
    required this.done,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext ctx) {
    final label = done
        ? 'RESTART'
        : running
        ? 'PAUSE'
        : 'START';
    final icon = done
        ? Icons.refresh_rounded
        : running
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 38,
        decoration: BoxDecoration(
          color: running ? color.withOpacity(0.15) : color,
          borderRadius: BorderRadius.circular(11),
          border: running
              ? Border.all(color: color.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: running
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 20,
                color: running ? color : Colors.black,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: running ? color : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon-only or icon+label small button
class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool active;
  final String? tooltip;
  const _SmallButton({
    required this.icon,
    required this.onTap,
    required this.cs,
    this.label,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext ctx) {
    final Widget btn = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 36,
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 10)
            : EdgeInsets.zero,
        width: label != null ? null : 36,
        decoration: BoxDecoration(
          color: active
              ? cs.primary.withOpacity(0.1)
              : cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? cs.primary.withOpacity(0.25)
                : cs.outline.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? cs.primary : cs.onSurface.withOpacity(0.45),
            ),
            if (label != null) ...[
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: active ? cs.primary : cs.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

/// Four session dots with animated fill
class _SessionDots extends StatelessWidget {
  final int sessions;
  final Color color;
  final ColorScheme cs;
  const _SessionDots({
    required this.sessions,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext ctx) {
    final filled = sessions % 4;
    final total = sessions;

    return Row(
      children: [
        ...List.generate(4, (i) {
          final on = i < filled;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: on ? 22 : 8,
            height: 6,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: on ? color : cs.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 10),
        if (total > 0)
          Text(
            '$total session${total == 1 ? '' : 's'} completed',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.3),
            ),
          )
        else
          Text(
            'Complete a session to track progress',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withOpacity(0.2),
            ),
          ),
      ],
    );
  }
}

/// Settings panel (duration editor)
class _SettingsPanel extends StatelessWidget {
  final PomPrefs draft;
  final ColorScheme cs;
  final ValueChanged<PomPrefs> onChanged;
  final VoidCallback onCancel, onSave;
  const _SettingsPanel({
    required this.draft,
    required this.cs,
    required this.onChanged,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext ctx) {
    final rows = [
      (_PM.focus, 'Focus', draft.focus),
      (_PM.shortB, 'Short break', draft.shortB),
      (_PM.longB, 'Long break', draft.longB),
    ];

    return SnapshotTile(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Timer durations',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: cs.onSurface.withOpacity(0.35),
              ),
            ),
          ),

          // Duration rows
          ...rows.map((r) {
            final mColor = r.$1.activeColor(ctx);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Color dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: mColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ),
                  _StepControl(
                    value: r.$3,
                    color: mColor,
                    cs: cs,
                    onDecrement: () => onChanged(switch (r.$1) {
                      _PM.focus => draft.cp(f: max(1, r.$3 - 1)),
                      _PM.shortB => draft.cp(s: max(1, r.$3 - 1)),
                      _PM.longB => draft.cp(l: max(1, r.$3 - 1)),
                    }),
                    onIncrement: () => onChanged(switch (r.$1) {
                      _PM.focus => draft.cp(f: min(90, r.$3 + 1)),
                      _PM.shortB => draft.cp(s: min(90, r.$3 + 1)),
                      _PM.longB => draft.cp(l: min(90, r.$3 + 1)),
                    }),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Cancel',
                  onTap: onCancel,
                  filled: false,
                  cs: cs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Save',
                  onTap: onSave,
                  filled: true,
                  cs: cs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// +/− stepper control with colored value
class _StepControl extends StatelessWidget {
  final int value;
  final Color color;
  final ColorScheme cs;
  final VoidCallback onDecrement, onIncrement;
  const _StepControl({
    required this.value,
    required this.color,
    required this.cs,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext ctx) => Row(
    children: [
      _StepBtn(icon: Icons.remove_rounded, onTap: onDecrement, cs: cs),
      SizedBox(
        width: 42,
        child: Text(
          '${value}m',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
      _StepBtn(icon: Icons.add_rounded, onTap: onIncrement, cs: cs),
    ],
  );
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _StepBtn({required this.icon, required this.onTap, required this.cs});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.45),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
      ),
      child: Icon(icon, size: 13, color: cs.onSurface.withOpacity(0.55)),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final ColorScheme cs;
  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
    required this.cs,
  });

  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? cs.primary : cs.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: cs.outline.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.black : cs.onSurface.withOpacity(0.55),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// RRECT PROGRESS PAINTER — rounded rectangle border as progress track
// ════════════════════════════════════════════════════════════════

class _RRectPainter extends CustomPainter {
  final double progress;
  final Color color, track;
  final double strokeWidth;
  final double radius;
  const _RRectPainter({
    required this.progress,
    required this.color,
    required this.track,
    this.strokeWidth = 5,
    this.radius = 22,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius - inset),
    );

    // Track (full border, dimmed)
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    // Build the perimeter path starting from top-center, going clockwise
    final path = _buildRRectPath(size);

    // Measure total perimeter length
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold(0.0, (sum, m) => sum + m.length);
    final drawn = totalLength * progress.clamp(0.0, 1.0);

    // Draw only the progress portion
    final progressPath = Path();
    double remaining = drawn;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final take = remaining.clamp(0.0, metric.length);
      progressPath.addPath(metric.extractPath(0, take), Offset.zero);
      remaining -= take;
    }

    canvas.drawPath(
      progressPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Builds a clockwise path around the rounded rect starting from the top-center.
  Path _buildRRectPath(Size size) {
    final inset = strokeWidth / 2;
    final r = radius - inset;
    final l = inset;
    final t = inset;
    final w = size.width - strokeWidth;
    final h = size.height - strokeWidth;

    final path = Path();
    // Start at top-center
    path.moveTo(l + w / 2, t);
    // Top-right corner
    path.lineTo(l + w - r, t);
    path.arcToPoint(Offset(l + w, t + r), radius: Radius.circular(r));
    // Right side down
    path.lineTo(l + w, t + h - r);
    path.arcToPoint(Offset(l + w - r, t + h), radius: Radius.circular(r));
    // Bottom left
    path.lineTo(l + r, t + h);
    path.arcToPoint(Offset(l, t + h - r), radius: Radius.circular(r));
    // Left side up
    path.lineTo(l, t + r);
    path.arcToPoint(Offset(l + r, t), radius: Radius.circular(r));
    // Back to top-center
    path.lineTo(l + w / 2, t);

    return path;
  }

  @override
  bool shouldRepaint(_RRectPainter old) =>
      progress != old.progress ||
      color != old.color ||
      track != old.track ||
      strokeWidth != old.strokeWidth ||
      radius != old.radius;
}
