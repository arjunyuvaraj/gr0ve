import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/theme/persona_theme.dart';
import 'package:gr0ve/features/snapshot/widgets/snapshot_shared.dart';

// ════════════════════════════════════════════════════════════════
// SCHEDULE DATA
// ════════════════════════════════════════════════════════════════

class _Period {
  final String label;
  final int sh, sm, eh, em;
  const _Period(this.label, this.sh, this.sm, this.eh, this.em);
  int get startMins => sh * 60 + sm;
  int get endMins => eh * 60 + em;
  int get durMins => endMins - startMins;
}

const _normal = [
  _Period('Period 1', 8, 0, 8, 50),
  _Period('IGS', 8, 54, 8, 58),
  _Period('Period 2', 9, 2, 9, 52),
  _Period('Period 3', 9, 56, 10, 46),
  _Period('Period 4', 10, 50, 11, 40),
  _Period('Period 5', 11, 44, 12, 34),
  _Period('Period 6', 12, 38, 13, 28),
  _Period('Period 7', 13, 32, 14, 22),
  _Period('Period 8', 14, 26, 15, 16),
  _Period('Period 9', 15, 20, 16, 10),
];

const _halfDay = [
  _Period('Period 1', 8, 0, 8, 25),
  _Period('IGS', 8, 29, 8, 38),
  _Period('Period 2', 8, 42, 9, 7),
  _Period('Period 3', 9, 11, 9, 36),
  _Period('Period 4', 9, 40, 10, 5),
  _Period('Period 5', 10, 9, 10, 34),
  _Period('Period 6', 10, 38, 11, 3),
  _Period('Period 7', 11, 7, 11, 32),
  _Period('Period 8', 11, 36, 12, 1),
  _Period('Period 9', 12, 5, 12, 30),
];

const _delayed = [
  _Period('IGS', 9, 30, 10, 10),
  _Period('Period 1', 10, 15, 10, 50),
  _Period('Period 2', 10, 55, 11, 30),
  _Period('Period 3', 11, 35, 12, 10),
  _Period('Period 4', 12, 15, 12, 50),
  _Period('Period 5', 12, 55, 13, 30),
  _Period('Period 6', 13, 35, 14, 10),
  _Period('Period 7', 14, 15, 14, 50),
  _Period('Period 8', 14, 55, 15, 30),
  _Period('Period 9', 15, 35, 16, 10),
];

List<_Period> _sched(String s) => switch (s) {
  'half_day' => _halfDay,
  'delayed_opening' => _delayed,
  _ => _normal,
};

// ════════════════════════════════════════════════════════════════
// SCHEDULE STATE
// ════════════════════════════════════════════════════════════════

sealed class _SS {}

class _SSPre extends _SS {}

class _SSDone extends _SS {}

class _SSCountdown extends _SS {
  final int diffSec, totalSec;
  _SSCountdown(this.diffSec, this.totalSec);
}

class _SSPassing extends _SS {
  final String next;
  final int diffSec;
  _SSPassing(this.next, this.diffSec);
}

class _SSInPeriod extends _SS {
  final String label;
  final int leftSec;
  final double prog;
  _SSInPeriod(this.label, this.leftSec, this.prog);
}

_SS _compute(DateTime now, String status) {
  final s = _sched(status);
  final nm = now.hour * 60.0 + now.minute + now.second / 60.0;
  const w = 60;
  final st = s.first.startMins.toDouble();
  final en = s.last.endMins.toDouble();

  if (nm < st - w) return _SSPre();
  if (nm < st) return _SSCountdown(((st - nm) * 60).round(), w * 60);
  if (nm >= en) return _SSDone();

  for (int i = 0; i < s.length; i++) {
    final p = s[i];
    if (nm >= p.startMins && nm < p.endMins) {
      final left = ((p.endMins - nm) * 60).round();
      return _SSInPeriod(
        p.label,
        left,
        (1 - left / (p.durMins * 60)).clamp(0, 1),
      );
    }
    if (i < s.length - 1) {
      final nx = s[i + 1];
      if (nm >= p.endMins && nm < nx.startMins) {
        return _SSPassing(nx.label, ((nx.startMins - nm) * 60).round());
      }
    }
  }
  return _SSPre();
}

String _fmt12(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour >= 12 ? 'PM' : 'AM'}';
}

String _fmtSec(int s) {
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sc = s % 60;
  final mm = m.toString().padLeft(2, '0'), ss = sc.toString().padLeft(2, '0');
  return h > 0 ? '${h.toString().padLeft(2, '0')}:$mm:$ss' : '$mm:$ss';
}

// ════════════════════════════════════════════════════════════════
// WIDGET
// ════════════════════════════════════════════════════════════════

const _doneMsgs = [
  'You survived. 🎉',
  "School's out!",
  'Freedom. 🏁',
  "That's a wrap.",
  'Go home.',
];

class SnapshotCountdownCard extends StatefulWidget {
  final bool compact;
  const SnapshotCountdownCard({super.key, this.compact = false});

  @override
  State<SnapshotCountdownCard> createState() => _SnapshotCountdownCardState();
}

class _SnapshotCountdownCardState extends State<SnapshotCountdownCard> {
  DateTime _now = DateTime.now();
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('app_config')
          .doc('school_status')
          .snapshots(),
      builder: (_, snap) {
        final status =
            (snap.data?.data() as Map?)?['status'] as String? ?? 'normal';
        return _buildState(_compute(_now, status), c);
      },
    );
  }

  Widget _buildState(_SS state, ColorScheme c) {
    final bigSize = widget.compact ? 24.0 : 32.0;
    return switch (state) {
      _SSPre() => SnapshotTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SnapshotDot(c.onSurface.withOpacity(0.18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fmt12(_now),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface.withOpacity(0.32),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Starts 8:00 AM',
              style: TextStyle(
                fontSize: 11,
                color: c.onSurface.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),

      _SSDone() => SnapshotTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SnapshotDot(context.colors.success),
                const SizedBox(width: 7),
                Text(
                  'DONE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: c.onSurface.withOpacity(0.32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              _doneMsgs[_now.day % _doneMsgs.length],
              style: TextStyle(
                fontSize: widget.compact ? 15.0 : 18.0,
                fontWeight: FontWeight.w800,
                color: context.colors.success,
              ),
            ),
          ],
        ),
      ),

      _SSCountdown(:final diffSec, :final totalSec) => SnapshotTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SnapshotDot(c.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'UNTIL SCHOOL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: c.onSurface.withOpacity(0.32),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _fmt12(_now),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: c.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              _fmtSec(diffSec),
              style: TextStyle(
                fontSize: widget.compact ? 26.0 : 36.0,
                fontWeight: FontWeight.w900,
                color: c.onSurface,
                fontFamily: 'monospace',
                letterSpacing: -1,
                height: 1,
              ),
            ),
            const SizedBox(height: 9),
            SnapshotProgressBar(1 - diffSec / totalSec),
          ],
        ),
      ),

      _SSPassing(:final next, :final diffSec) => SnapshotTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SnapshotDot(Colors.amber),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'PASSING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: c.onSurface.withOpacity(0.32),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _fmt12(_now),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: c.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtSec(diffSec),
                  style: TextStyle(
                    fontSize: bigSize,
                    fontWeight: FontWeight.w900,
                    color: c.onSurface,
                    fontFamily: 'monospace',
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '→ $next',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.onSurface.withOpacity(0.42),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      _SSInPeriod(:final label, :final leftSec, :final prog) => SnapshotTile(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SnapshotDot(c.primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: c.onSurface.withOpacity(0.32),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _fmt12(_now),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: c.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtSec(leftSec),
                  style: TextStyle(
                    fontSize: bigSize,
                    fontWeight: FontWeight.w900,
                    color: c.onSurface,
                    fontFamily: 'monospace',
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'remaining',
                      style: TextStyle(
                        fontSize: 12,
                        color: c.onSurface.withOpacity(0.42),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            SnapshotProgressBar(prog),
          ],
        ),
      ),
    };
  }
}
