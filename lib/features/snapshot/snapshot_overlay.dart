import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/core/theme/dark_theme.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SnapshotOverlay {
  static void show(BuildContext context) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _SnapshotOverlayView(onDismiss: () => entry.remove()),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────
// SCHOOL STATUS
// Firestore: app_config/school_status  { status: 'normal' | 'half_day' | 'snow_day' }
// ─────────────────────────────────────────────────────────────

enum SchoolStatus { normal, halfDay, snowDay }

SchoolStatus _parseStatus(String? s) => switch (s) {
  'half_day' => SchoolStatus.halfDay,
  'snow_day' => SchoolStatus.snowDay,
  _ => SchoolStatus.normal,
};

// ─────────────────────────────────────────────────────────────
// PERSONA TONE
// ─────────────────────────────────────────────────────────────

extension _PersonaTone on CounselorPersona {
  String get morningSubtitle => switch (this) {
    CounselorPersona.grover => 'Doors open in',
    CounselorPersona.aspen => 'Doors open in',
    CounselorPersona.rowan => 'Doors open in',
    CounselorPersona.sakura => 'Doors open in',
  };

  String get absenceEyebrow => switch (this) {
    CounselorPersona.grover => 'Hope you have a free!',
    CounselorPersona.aspen => 'Check your classes.',
    CounselorPersona.rowan => 'Here\'s who\'s out.',
    CounselorPersona.sakura => 'Today\'s absences.',
  };

  String get absenceTitleLine => switch (this) {
    CounselorPersona.grover => 'Teachers',
    CounselorPersona.aspen => 'Who\'s Out',
    CounselorPersona.rowan => 'Absent',
    CounselorPersona.sakura => 'Absences',
  };

  String get busEyebrow => switch (this) {
    CounselorPersona.grover => 'Finally leaving',
    CounselorPersona.aspen => 'Heading out',
    CounselorPersona.rowan => 'Safe travels',
    CounselorPersona.sakura => 'Until tomorrow',
  };

  String get busTitleLine => switch (this) {
    CounselorPersona.grover => 'Buses',
    CounselorPersona.aspen => 'Your Buses',
    CounselorPersona.rowan => 'Buses',
    CounselorPersona.sakura => 'Buses',
  };

  String pomodoroGreeting(String name, int sessions) => switch (this) {
    CounselorPersona.grover =>
      sessions == 0 ? 'Focus mode,\n$name.' : 'Keep going,\n$name.',
    CounselorPersona.aspen =>
      sessions == 0 ? 'Deep work,\n$name.' : 'Good momentum,\n$name.',
    CounselorPersona.rowan =>
      sessions == 0 ? 'Buckle down,\n$name.' : 'Y\'all, keep it up,\n$name.',
    CounselorPersona.sakura =>
      sessions == 0 ? 'Into the work,\n$name.' : 'Beautiful focus,\n$name.',
  };

  String get snowDaySubtitle => switch (this) {
    CounselorPersona.grover => 'No school today',
    CounselorPersona.aspen => 'A surprise variable',
    CounselorPersona.rowan => 'Enjoy it',
    CounselorPersona.sakura => 'Rest. Create. Be.',
  };

  String get halfDaySubtitle => switch (this) {
    CounselorPersona.grover => 'Half day in effect. Dismissal at 12:30 PM.',
    CounselorPersona.aspen => 'Short schedule today. Wrap up by 12:30.',
    CounselorPersona.rowan => 'Half day today. Out by 12:30.',
    CounselorPersona.sakura => 'A half day. More time for what matters.',
  };

  String get noStarredTeachersMessage => switch (this) {
    CounselorPersona.grover => 'Star teachers to track them here.',
    CounselorPersona.aspen => 'No starred teachers yet.',
    CounselorPersona.rowan => 'Head to Teachers and star yours.',
    CounselorPersona.sakura => 'Star your teachers to see them here.',
  };

  String get noBusesMessage => switch (this) {
    CounselorPersona.grover =>
      'Star buses in the Buses tab to track them here.',
    CounselorPersona.aspen =>
      'No starred buses yet. Add them in the Buses tab.',
    CounselorPersona.rowan => 'Head to the Buses tab and star yours.',
    CounselorPersona.sakura => 'Star your route in Buses to see it here.',
  };
}

// ─────────────────────────────────────────────────────────────
// THEME  — matches the app's near-black aesthetic exactly
// ─────────────────────────────────────────────────────────────

class _Theme {
  final Color accent;
  final Color cardBg;
  final Color cardBorder;
  final Color pageBg;

  const _Theme({
    required this.accent,
    required this.cardBg,
    required this.cardBorder,
    required this.pageBg,
  });

  static _Theme of(CounselorPersona p) {
    final accent = switch (p) {
      CounselorPersona.grover => const Color(0xFF35B595),
      CounselorPersona.aspen => const Color(0xFFFFDD71),
      CounselorPersona.rowan => const Color(0xFFFF6F2A),
      CounselorPersona.sakura => const Color(0xFFEEC3F5),
    };
    return _Theme(
      accent: accent,
      cardBg: const Color(0xFF181818),
      cardBorder: Colors.white.withOpacity(0.07),
      pageBg: Color.lerp(const Color(0xFF0D0D0D), accent, 0.04)!,
    );
  }

  static Color onAccentFor(CounselorPersona p) => switch (p) {
    CounselorPersona.grover => Colors.black,
    CounselorPersona.aspen => Colors.black,
    CounselorPersona.rowan => Colors.white,
    CounselorPersona.sakura => Colors.black,
  };
}

// ─────────────────────────────────────────────────────────────
// TIME SEGMENT
// ─────────────────────────────────────────────────────────────

enum _Seg { morning, absence, lunch, buses, pomodoro }

class _LunchWin {
  final int start, end;
  const _LunchWin(this.start, this.end);
}

const _lunches = {
  9: _LunchWin(10 * 60 + 50, 11 * 60 + 40),
  10: _LunchWin(11 * 60 + 44, 12 * 60 + 34),
  11: _LunchWin(12 * 60 + 38, 13 * 60 + 28),
  12: _LunchWin(12 * 60 + 38, 13 * 60 + 28),
};

const _lunchLabels = {
  9: '10:50 - 11:40 AM',
  10: '11:44 AM - 12:34 PM',
  11: '12:38 - 1:28 PM',
  12: '12:38 - 1:28 PM',
};

_Seg _toSeg(DateTime now, int grade, SchoolStatus status) {
  if (status == SchoolStatus.snowDay) return _Seg.morning;
  final t = now.hour * 60 + now.minute;
  if (status == SchoolStatus.halfDay) {
    if (t < 7 * 60 + 30) return _Seg.morning;
    if (t < 11 * 60 + 45) return _Seg.absence;
    if (t < 17 * 60) return _Seg.buses;
    return _Seg.pomodoro;
  }
  final l = _lunches[grade] ?? _lunches[11]!;
  if (t < 7 * 60 + 30) return _Seg.morning;
  if (t < l.start) return _Seg.absence;
  if (t < l.end) return _Seg.lunch;
  if (t < 15 * 60 + 45) return _Seg.absence;
  if (t < 17 * 60) return _Seg.buses;
  return _Seg.pomodoro;
}

bool _isMorningCountdown(DateTime now) =>
    (now.hour * 60 + now.minute) < (7 * 60 + 30);

// ─────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────

class _Data {
  final String firstName;
  final int grade;
  final Map<String, String> absenceMap;
  final Map<String, Map<String, dynamic>> allTeachers;
  final List<BusRoute> allBuses;
  final Set<String> starredTeachers;
  final Set<String> starredBuses;
  final SchoolStatus schoolStatus;

  const _Data({
    required this.firstName,
    required this.grade,
    required this.absenceMap,
    required this.allTeachers,
    required this.allBuses,
    required this.starredTeachers,
    required this.starredBuses,
    required this.schoolStatus,
  });

  List<({String name, String dept, String status})> get starredTeacherRows {
    return starredTeachers.map((n) {
      final teacher = allTeachers.values.firstWhere(
        (t) => (t['name'] as String? ?? '') == n,
        orElse: () => {'name': n, 'department': ''},
      );
      final dept = teacher['department'] as String? ?? '';
      final status = formatStatusString(
        resolveTeacherStatus(teacherName: n, absenceMap: absenceMap),
      );
      return (name: n, dept: dept, status: status);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<BusRoute> get starredRoutes =>
      allBuses.where((b) => starredBuses.contains(b.town)).toList();
}

// ─────────────────────────────────────────────────────────────
// OVERLAY WRAPPER  (enter/exit animation)
// ─────────────────────────────────────────────────────────────

class _SnapshotOverlayView extends StatefulWidget {
  final VoidCallback onDismiss;
  const _SnapshotOverlayView({required this.onDismiss});

  @override
  State<_SnapshotOverlayView> createState() => _SnapshotOverlayViewState();
}

class _SnapshotOverlayViewState extends State<_SnapshotOverlayView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.animateTo(
      0,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeInCubic,
    );
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: _SnapshotRoot(onDismiss: _dismiss),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────

class _SnapshotRoot extends StatefulWidget {
  final Future<void> Function() onDismiss;
  const _SnapshotRoot({required this.onDismiss});

  @override
  State<_SnapshotRoot> createState() => _SnapshotRootState();
}

class _SnapshotRootState extends State<_SnapshotRoot> {
  bool _loading = true;
  late DateTime _now;
  Timer? _timer;
  _Data? _data;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final interval = _isMorningCountdown(_now)
        ? const Duration(seconds: 1)
        : const Duration(minutes: 1);
    _timer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      final newNow = DateTime.now();
      final wasCountdown = _isMorningCountdown(_now);
      final isCountdown = _isMorningCountdown(newNow);
      setState(() => _now = newNow);
      if (wasCountdown != isCountdown) _startTimer();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    String firstName = user?.displayName?.split(' ').first ?? 'there';
    int grade = 11;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final d = doc.data();
        if (d?['grade'] != null)
          grade = int.tryParse(d!['grade'].toString()) ?? 11;
      } catch (_) {}
    }

    SchoolStatus schoolStatus = SchoolStatus.normal;
    try {
      final statusDoc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('school_status')
          .get();
      schoolStatus = _parseStatus(statusDoc.data()?['status'] as String?);
    } catch (_) {}

    final results = await Future.wait([
      fetchTeacherListFromFirebase(),
      fetchGoogleSheetAbsences(spreadsheetId: '', worksheetTitle: ''),
      fetchBusRoutes(),
      StarredTeacherService.load(),
      StarredBusService.load(),
    ]);

    if (!mounted) return;
    setState(() {
      _data = _Data(
        firstName: firstName,
        grade: grade,
        allTeachers: results[0] as Map<String, Map<String, dynamic>>,
        absenceMap: results[1] as Map<String, String>,
        allBuses: results[2] as List<BusRoute>,
        starredTeachers: StarredTeacherService.starredTeachers.value,
        starredBuses: StarredBusService.starredTowns.value,
        schoolStatus: schoolStatus,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CounselorPersona>(
      valueListenable: CounselorPersonaService.activePersona,
      builder: (_, persona, __) {
        final theme = _Theme.of(persona);
        if (_loading || _data == null) {
          return _LoadingShell(theme: theme, onDismiss: widget.onDismiss);
        }
        final status = _data!.schoolStatus;
        if (status == SchoolStatus.snowDay) {
          return _SnowDayScreen(
            theme: theme,
            persona: persona,
            now: _now,
            data: _data!,
            onDismiss: widget.onDismiss,
            onRefresh: _load,
          );
        }
        final seg = _toSeg(_now, _data!.grade, status);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey('${seg.name}_${persona.name}_${status.name}'),
            child: _route(seg, theme, persona),
          ),
        );
      },
    );
  }

  Widget _route(_Seg seg, _Theme theme, CounselorPersona persona) =>
      switch (seg) {
        _Seg.morning => _MorningScreen(
          theme: theme,
          persona: persona,
          now: _now,
          data: _data!,
          onDismiss: widget.onDismiss,
          onRefresh: _load,
        ),
        _Seg.absence => _AbsenceScreen(
          theme: theme,
          persona: persona,
          now: _now,
          data: _data!,
          onDismiss: widget.onDismiss,
          onRefresh: _load,
        ),
        _Seg.lunch => _LunchScreen(
          theme: theme,
          persona: persona,
          now: _now,
          data: _data!,
          onDismiss: widget.onDismiss,
          onRefresh: _load,
        ),
        _Seg.buses => _BusScreen(
          theme: theme,
          persona: persona,
          now: _now,
          data: _data!,
          onDismiss: widget.onDismiss,
          onRefresh: _load,
        ),
        _Seg.pomodoro => _PomodoroScreen(
          theme: theme,
          persona: persona,
          now: _now,
          data: _data!,
          onDismiss: widget.onDismiss,
        ),
      };
}

// ─────────────────────────────────────────────────────────────
// SHARED SHELL
// ─────────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  final _Theme theme;
  final Widget child;
  final Future<void> Function() onDismiss;
  final Future<void> Function()? onRefresh;

  const _Shell({
    required this.theme,
    required this.child,
    required this.onDismiss,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: theme.pageBg)),
        // Subtle top accent glow
        Positioned(
          top: -60,
          left: -60,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [theme.accent.withOpacity(0.09), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: onRefresh != null
                    ? RefreshIndicator(
                        onRefresh: onRefresh!,
                        color: theme.accent,
                        backgroundColor: theme.cardBg,
                        child: child,
                      )
                    : child,
              ),
              _DismissBar(theme: theme, onDismiss: onDismiss),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DISMISS BAR
// ─────────────────────────────────────────────────────────────

class _DismissBar extends StatelessWidget {
  final _Theme theme;
  final Future<void> Function() onDismiss;
  const _DismissBar({required this.theme, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: GestureDetector(
          onTap: onDismiss,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to gr0ve',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.55),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withOpacity(0.35),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MICRO-WIDGETS  — match app typography exactly
// ─────────────────────────────────────────────────────────────

/// Spaced uppercase eyebrow (e.g. "NICE TO SEE YOU", "FINALLY LEAVING")
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 3.0,
      color: Colors.white.withOpacity(0.35),
    ),
  );
}

/// Giant bold uppercase page title (e.g. "BUSES", "TEACHERS")
class _BigTitle extends StatelessWidget {
  final String text;
  const _BigTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 46,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      letterSpacing: -1.0,
      height: 1.05,
    ),
  );
}

/// Section header with star icon + optional count (e.g. "★ FAVORITE BUSES  3")
class _SectionHeader extends StatelessWidget {
  final String text;
  final Color accent;
  final int? count;
  const _SectionHeader(this.text, this.accent, {this.count});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.star_rounded, color: accent, size: 14),
      const SizedBox(width: 6),
      Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
      if (count != null) ...[
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.28),
          ),
        ),
      ],
    ],
  );
}

/// Pill badge matching the app's status badges (e.g. "All Day", "Present")
class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// Standard list row card
class _RowCard extends StatelessWidget {
  final _Theme t;
  final Widget child;
  const _RowCard(this.t, {required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: t.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: t.cardBorder),
    ),
    child: child,
  );
}

/// Smaller info / empty-state card
class _InfoCard extends StatelessWidget {
  final _Theme t;
  final Widget child;
  const _InfoCard(this.t, {required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: t.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: t.cardBorder),
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────
// LOADING
// ─────────────────────────────────────────────────────────────

class _LoadingShell extends StatelessWidget {
  final _Theme theme;
  final Future<void> Function() onDismiss;
  const _LoadingShell({required this.theme, required this.onDismiss});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: ColoredBox(color: theme.pageBg)),
      Center(
        child: CircularProgressIndicator(color: theme.accent, strokeWidth: 2),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _DismissBar(theme: theme, onDismiss: onDismiss),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// SNOW DAY
// ─────────────────────────────────────────────────────────────

class _SnowDayScreen extends StatelessWidget {
  final _Theme theme;
  final CounselorPersona persona;
  final DateTime now;
  final _Data data;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onRefresh;

  const _SnowDayScreen({
    required this.theme,
    required this.persona,
    required this.now,
    required this.data,
    required this.onDismiss,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = isDark
        ? 'assets/snow/snow_dark.png'
        : 'assets/snow/snow_light.png';

    return _Shell(
      theme: theme,
      onDismiss: onDismiss,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _Eyebrow(_fmtTime(now)),
            const SizedBox(height: 6),
            const _BigTitle('Snow Day'),
            const SizedBox(height: 4),
            Text(
              persona.snowDaySubtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 48),
            Image.asset(
              assetPath,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                height: 160,
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSnow,
                    color: theme.accent,
                    size: 72,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _InfoCard(
                theme,
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      color: theme.accent.withOpacity(0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'School is cancelled. Check back tomorrow.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.45),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MORNING  (live seconds countdown)
// ─────────────────────────────────────────────────────────────

class _MorningScreen extends StatelessWidget {
  final _Theme theme;
  final CounselorPersona persona;
  final DateTime now;
  final _Data data;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onRefresh;

  const _MorningScreen({
    required this.theme,
    required this.persona,
    required this.now,
    required this.data,
    required this.onDismiss,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final schoolStart = DateTime(now.year, now.month, now.day, 7, 30, 0);
    final diffSec = schoolStart.difference(now).inSeconds.clamp(0, 99999);
    final hLeft = diffSec ~/ 3600;
    final mLeft = (diffSec % 3600) ~/ 60;
    final sLeft = diffSec % 60;
    final halfDay = data.schoolStatus == SchoolStatus.halfDay;

    return _Shell(
      theme: theme,
      onDismiss: onDismiss,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _Eyebrow(_fmtTime(now)),
            const SizedBox(height: 6),
            _BigTitle(persona.morningSubtitle),
            if (halfDay) ...[const SizedBox(height: 10), _HalfDayChip(theme)],
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _CountdownCard(
                theme: theme,
                diffSec: diffSec,
                hLeft: hLeft,
                mLeft: mLeft,
                sLeft: sLeft,
              ),
            ),
            if (halfDay) ...[
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _InfoCard(
                  theme,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        color: theme.accent.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          persona.halfDaySubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final _Theme theme;
  final int diffSec;
  final int hLeft;
  final int mLeft;
  final int sLeft;

  const _CountdownCard({
    required this.theme,
    required this.diffSec,
    required this.hLeft,
    required this.mLeft,
    required this.sLeft,
  });

  @override
  Widget build(BuildContext context) {
    // Total seconds from midnight to 7:30
    const totalSec = 7 * 3600 + 30 * 60;
    final progress = (1.0 - (diffSec / totalSec)).clamp(0.0, 1.0);

    // Build the HH:MM:SS or MM:SS string
    final timeStr = hLeft > 0
        ? '${hLeft.toString().padLeft(2, '0')}:${mLeft.toString().padLeft(2, '0')}:${sLeft.toString().padLeft(2, '0')}'
        : '${mLeft.toString().padLeft(2, '0')}:${sLeft.toString().padLeft(2, '0')}';

    final monoStyle = GoogleFonts.jetBrainsMono(
      fontSize: 52,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -1,
      height: 1.0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: diffSec > 0 ? theme.accent : context.colors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                diffSec > 0 ? 'until school' : 'school has started',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main time display
          diffSec > 0
              ? Text(timeStr, style: monoStyle)
              : Text(
                  'Head to class.',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: context.colors.success,
                    height: 1.0,
                  ),
                ),

          const SizedBox(height: 6),

          // HH / MM / SS column labels
          if (diffSec > 0)
            Row(
              children: [
                if (hLeft > 0) ...[_monoLabel('hr'), _monoSpacer(hLeft > 0)],
                _monoLabel('min'),
                _monoSpacer(true),
                _monoLabel('sec'),
              ],
            ),

          const SizedBox(height: 18),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
            ),
          ),

          const SizedBox(height: 10),

          // "doors open 7:30 AM" footer
          Text(
            'doors open 7:30 AM',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: Colors.white.withOpacity(0.25),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monoLabel(String text) => Text(
    text,
    style: GoogleFonts.jetBrainsMono(
      fontSize: 11,
      color: Colors.white.withOpacity(0.28),
      fontWeight: FontWeight.w400,
    ),
  );

  // Spacer that matches the character width of the digit block above
  Widget _monoSpacer(bool show) => show
      ? const SizedBox(width: 36) // ~3 chars wide at fontSize 52
      : const SizedBox.shrink();
}

class _HalfDayChip extends StatelessWidget {
  final _Theme t;
  const _HalfDayChip(this.t);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      color: t.accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: t.accent.withOpacity(0.3)),
    ),
    child: Text(
      'Half Day',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: t.accent,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// ABSENCE  (starred teachers only)
// ─────────────────────────────────────────────────────────────

class _AbsenceScreen extends StatelessWidget {
  final _Theme theme;
  final CounselorPersona persona;
  final DateTime now;
  final _Data data;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onRefresh;

  const _AbsenceScreen({
    required this.theme,
    required this.persona,
    required this.now,
    required this.data,
    required this.onDismiss,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final rows = data.starredTeacherRows;
    final halfDay = data.schoolStatus == SchoolStatus.halfDay;

    return _Shell(
      theme: theme,
      onDismiss: onDismiss,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 72),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Eyebrow(persona.absenceEyebrow),
                      if (halfDay) ...[const Spacer(), _HalfDayChip(theme)],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _BigTitle(persona.absenceTitleLine),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _SectionHeader(
                'Starred Teachers',
                theme.accent,
                count: rows.length,
              ),
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _InfoCard(
                  theme,
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_border_rounded,
                        color: theme.accent.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          persona.noStarredTeachersMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...rows.map((row) {
                final isAbsent = row.status != 'Present';
                final badgeColor = isAbsent
                    ? const Color(0xFFF87171)
                    : context.colors.success;
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 8,
                  ),
                  child: _RowCard(
                    theme,
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: theme.accent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (row.dept.isNotEmpty)
                                Text(
                                  row.dept,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.38),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _StatusBadge(row.status, badgeColor),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LUNCH
// ─────────────────────────────────────────────────────────────

class _LunchScreen extends StatefulWidget {
  final _Theme theme;
  final CounselorPersona persona;
  final DateTime now;
  final _Data data;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onRefresh;

  const _LunchScreen({
    required this.theme,
    required this.persona,
    required this.now,
    required this.data,
    required this.onDismiss,
    required this.onRefresh,
  });

  @override
  State<_LunchScreen> createState() => _LunchScreenState();
}

class _LunchScreenState extends State<_LunchScreen> {
  bool _loading = true;
  String? _error;
  Map<String, List<String>> _stations = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = widget.now;
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final url =
          'https://bergen.api.nutrislice.com/menu/api/weeks/school/bergen-academy/menu-type/lunch/${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}?format=json';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) throw Exception();
      final raw = jsonDecode(res.body);
      final days = raw['days'] as List;
      final today = days.firstWhere(
        (d) => d['date'] == dateStr && (d['menu_items'] as List).isNotEmpty,
        orElse: () => null,
      );
      if (today == null) throw Exception();
      String station = '';
      final Map<String, List<String>> stations = {};
      for (final item in today['menu_items'] as List) {
        if (item['is_section_title'] == true && item['food'] == null) {
          station = item['text'] as String? ?? '';
          continue;
        }
        if (item['food'] != null) {
          final name = (item['food']['name'] as String? ?? '').trim();
          if (name.isNotEmpty)
            stations.putIfAbsent(station, () => []).add(name);
        }
      }
      if (mounted)
        setState(() {
          _stations = stations;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'No lunch data available today';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final grade = widget.data.grade;
    final gradeLabel =
        {9: '9th', 10: '10th', 11: '11th', 12: '12th'}[grade] ?? '11th';
    final lunchTime = _lunchLabels[grade] ?? '12:38 - 1:28 PM';

    return _Shell(
      theme: theme,
      onDismiss: widget.onDismiss,
      onRefresh: () async {
        await _fetch();
        await widget.onRefresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 72),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Eyebrow('$gradeLabel  ·  $lunchTime'),
                  const SizedBox(height: 4),
                  const _BigTitle('Lunch'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.accent,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _InfoCard(
                  theme,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedRestaurant02,
                        color: theme.accent.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._stations.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (e.key.isEmpty ? 'Menu' : e.key).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: e.value
                            .map(
                              (item) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.07),
                                  ),
                                ),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BUSES  (starred only)
// ─────────────────────────────────────────────────────────────

class _BusScreen extends StatelessWidget {
  final _Theme theme;
  final CounselorPersona persona;
  final DateTime now;
  final _Data data;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onRefresh;

  const _BusScreen({
    required this.theme,
    required this.persona,
    required this.now,
    required this.data,
    required this.onDismiss,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final buses = data.starredRoutes;
    final halfDay = data.schoolStatus == SchoolStatus.halfDay;

    return _Shell(
      theme: theme,
      onDismiss: onDismiss,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 72),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Eyebrow(persona.busEyebrow),
                      if (halfDay) ...[const Spacer(), _HalfDayChip(theme)],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _BigTitle(persona.busTitleLine),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _SectionHeader(
                'Favorite Buses',
                theme.accent,
                count: buses.length,
              ),
            ),
            const SizedBox(height: 10),
            if (buses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _InfoCard(
                  theme,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedBus02,
                        color: theme.accent.withOpacity(0.5),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          persona.noBusesMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...buses.map(
                (bus) => Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 8,
                  ),
                  child: _RowCard(
                    theme,
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: theme.accent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.town,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Arrived',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.success.withOpacity(
                                    0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bus code — accent-tinted pill matching app style
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bus.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: theme.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _InfoCard(
                theme,
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 16,
                      color: theme.accent.withOpacity(0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Buses depart from the lower parking lot. Don\'t forget anything!',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.45),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// POMODORO
// ─────────────────────────────────────────────────────────────

enum _PomMode { focus, shortBreak, longBreak }

extension _PomX on _PomMode {
  String get label => switch (this) {
    _PomMode.focus => 'Focus',
    _PomMode.shortBreak => 'Short Break',
    _PomMode.longBreak => 'Long Break',
  };
  int get total => switch (this) {
    _PomMode.focus => 25 * 60,
    _PomMode.shortBreak => 5 * 60,
    _PomMode.longBreak => 15 * 60,
  };
}

class _PomodoroScreen extends StatefulWidget {
  final _Theme theme;
  final CounselorPersona persona;
  final DateTime now;
  final _Data data;
  final Future<void> Function() onDismiss;

  const _PomodoroScreen({
    required this.theme,
    required this.persona,
    required this.now,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_PomodoroScreen> createState() => _PomodoroState();
}

class _PomodoroState extends State<_PomodoroScreen>
    with SingleTickerProviderStateMixin {
  _PomMode _mode = _PomMode.focus;
  late int _left;
  bool _running = false;
  int _sessions = 0;
  Timer? _timer;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _left = _mode.total;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _setMode(_PomMode m) {
    _timer?.cancel();
    setState(() {
      _mode = m;
      _left = m.total;
      _running = false;
    });
  }

  void _toggle() {
    if (_left == 0) {
      _setMode(_mode);
      return;
    }
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_left > 0) {
            _left--;
          } else {
            _timer?.cancel();
            _running = false;
            if (_mode == _PomMode.focus) _sessions++;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final mins = _left ~/ 60;
    final secs = _left % 60;
    final progress = 1.0 - (_left / _mode.total);

    return _Shell(
      theme: theme,
      onDismiss: widget.onDismiss,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            const SizedBox(height: 80),
            _Eyebrow(_fmtTime(widget.now)),
            const SizedBox(height: 6),
            const _BigTitle('Focus'),

            // Mode tabs
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: _PomMode.values.map((m) {
                  final active = _mode == m;
                  final last = m == _PomMode.longBreak;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: last ? 0 : 7),
                      child: GestureDetector(
                        onTap: () => _setMode(m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: active
                                ? theme.accent.withOpacity(0.15)
                                : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? theme.accent.withOpacity(0.4)
                                  : Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Text(
                            m.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: active
                                  ? theme.accent
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 36),
            Center(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _running ? _pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(220, 220),
                            painter: _RingPainter(
                              progress: progress,
                              color: theme.accent,
                              track: Colors.white.withOpacity(0.07),
                              stroke: 8,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _mode.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.4),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Reset
                      GestureDetector(
                        onTap: () => _setMode(_mode),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: Colors.white.withOpacity(0.45),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Play/Pause
                      GestureDetector(
                        onTap: _toggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: theme.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.accent.withOpacity(0.4),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                          child: Icon(
                            _left == 0
                                ? Icons.refresh_rounded
                                : _running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: _Theme.onAccentFor(widget.persona),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Session dots
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Center(
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            alignment: WrapAlignment.center,
                            children: List.generate(4, (i) {
                              final filled = i < (_sessions % 4);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: filled
                                      ? theme.accent
                                      : Colors.white.withOpacity(0.1),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_sessions > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.accent.withOpacity(0.3)),
                ),
                child: Text(
                  '$_sessions session${_sessions != 1 ? 's' : ''} completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.accent,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _InfoCard(
                theme,
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      size: 15,
                      color: theme.accent.withOpacity(0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '25 min focus, 5 min rest. After 4 sessions, take a 15 min break.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.45),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RING PAINTER
// ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double stroke;
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - stroke) / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.progress != progress || o.color != color;
}

// ─────────────────────────────────────────────────────────────
// HELPER
// ─────────────────────────────────────────────────────────────

String _fmtTime(DateTime t) {
  final ap = t.hour >= 12 ? 'PM' : 'AM';
  final hh = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$hh:${t.minute.toString().padLeft(2, '0')} $ap';
}
