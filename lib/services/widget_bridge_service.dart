// widget_bridge_service.dart
//
// Pushes live Firestore data to iOS WidgetKit / Android AppWidget
// via the home_widget package (shared UserDefaults / SharedPreferences).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

// ── iOS app group ─────────────────────────────────────────────────────────────
const _kAppGroup = 'group.com.arjunyuvaraj.gr0ve';

// ── Widget names — iOS must match Swift Widget.kind, Android must match class name
const _kIosBuses = 'Gr0veBusWidget';
const _kIosTeachers = 'Gr0veTeacherWidget';
const _kIosSchedule = 'Gr0veScheduleWidget';

const _kAndroidBuses = 'BusWidget';
const _kAndroidTeachers = 'TeacherWidget';
const _kAndroidSchedule = 'ScheduleWidget';

// ── Schedule periods ──────────────────────────────────────────────────────────
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

Map<String, dynamic> _computeSchedulePayload(String status) {
  final now = DateTime.now();
  final nm = now.hour * 60.0 + now.minute + now.second / 60.0;
  final s = _sched(status);
  final st = s.first.startMins.toDouble();
  final en = s.last.endMins.toDouble();

  if (nm < st - 60)
    return {'phase': 'pre', 'label': 'School', 'time': '8:00 AM'};
  if (nm < st) {
    final diff = ((st - nm) * 60).round();
    return {
      'phase': 'countdown',
      'label': 'Until school',
      'secs': diff,
      'total': 3600,
    };
  }
  if (nm >= en)
    return {'phase': 'done', 'label': "School's out!", 'secs': 0, 'prog': 1.0};

  for (int i = 0; i < s.length; i++) {
    final p = s[i];
    if (nm >= p.startMins && nm < p.endMins) {
      final left = ((p.endMins - nm) * 60).round();
      final prog = (1 - left / (p.durMins * 60)).clamp(0.0, 1.0);
      return {'phase': 'period', 'label': p.label, 'secs': left, 'prog': prog};
    }
    if (i < s.length - 1) {
      final nx = s[i + 1];
      if (nm >= p.endMins && nm < nx.startMins) {
        final diff = ((nx.startMins - nm) * 60).round();
        return {
          'phase': 'passing',
          'label': 'Passing',
          'next': nx.label,
          'secs': diff,
        };
      }
    }
  }
  return {'phase': 'pre', 'label': 'School', 'time': '8:00 AM'};
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICE
// ═════════════════════════════════════════════════════════════════════════════

class WidgetBridgeService {
  WidgetBridgeService._();

  static StreamSubscription? _busSub;
  static StreamSubscription? _teacherSub;
  static StreamSubscription? _absenceSub;
  static StreamSubscription? _statusSub;
  static StreamSubscription? _starredBusSub;
  static StreamSubscription? _starredTeacherSub;
  static Timer? _scheduleTimer;

  static Set<String> _starredBuses = {};
  static Set<String> _starredTeachers = {};
  static List<Map<String, dynamic>> _allBuses = [];
  static Map<String, Map<String, dynamic>> _allTeachers = {};
  static Map<String, String> _absences = {};
  static String _schoolStatus = 'normal';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_kAppGroup);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      debugPrint('[WidgetBridge] No user — skipping init');
      return;
    }

    // ── Starred buses: users/{uid}/preferences/starredTowns → towns[] ───────
    _starredBusSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('starredTowns')
        .snapshots()
        .listen((snap) {
          _starredBuses = Set<String>.from(
            (snap.data()?['towns'] as List<dynamic>?) ?? [],
          );
          debugPrint('[WidgetBridge] Starred buses: $_starredBuses');
          unawaited(_pushBuses());
        });

    // ── Bus routes: public_data/bus_routes → routes{} ─────────────────────
    // Same path as bus_service.dart getBusRoutesStream()
    _busSub = FirebaseFirestore.instance
        .collection('public_data')
        .doc('bus_routes')
        .snapshots()
        .listen((snap) {
          if (!snap.exists || snap.data() == null) {
            _allBuses = [];
          } else {
            final routesMap =
                (snap.data()!['routes'] as Map<String, dynamic>?) ?? {};
            _allBuses = routesMap.values
                .map((v) => Map<String, dynamic>.from(v as Map))
                .toList();
          }
          debugPrint('[WidgetBridge] Bus routes loaded: ${_allBuses.length}');
          unawaited(_pushBuses());
        });

    // ── Starred teachers: users/{uid}/preferences/starredTeachers → teachers[]
    _starredTeacherSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('starredTeachers')
        .snapshots()
        .listen((snap) {
          _starredTeachers = Set<String>.from(
            (snap.data()?['teachers'] as List<dynamic>?) ??
                [], // field is 'teachers', not 'names'
          );
          debugPrint('[WidgetBridge] Starred teachers: $_starredTeachers');
          unawaited(_pushTeachers());
        });

    // ── Teacher list: teachers collection ─────────────────────────────────
    // Same path as fetchTeacherListFromFirebase() in teacher_service.dart
    _teacherSub = FirebaseFirestore.instance
        .collection('teachers')
        .snapshots()
        .listen((snap) {
          _allTeachers = {
            for (final d in snap.docs)
              (d.data()['name'] ?? d.id).toString(): {
                'name': (d.data()['name'] ?? d.id).toString(),
                'department': (d.data()['department'] ?? '').toString(),
              },
          };
          debugPrint('[WidgetBridge] Teachers loaded: ${_allTeachers.length}');
          unawaited(_pushTeachers());
        });

    // ── Absences: public_data/teacher_absences → teachers{} ───────────────
    // Same path as fetchGoogleSheetAbsences() in teacher_service.dart
    _absenceSub = FirebaseFirestore.instance
        .collection('public_data')
        .doc('teacher_absences')
        .snapshots()
        .listen((snap) {
          if (!snap.exists || snap.data() == null) {
            _absences = {};
          } else {
            final teachers =
                (snap.data()!['teachers'] as Map<String, dynamic>?) ?? {};
            _absences = teachers.map((k, v) => MapEntry(k, v.toString()));
          }
          debugPrint(
            '[WidgetBridge] Absences loaded: ${_absences.keys.toList()}',
          );
          unawaited(_pushTeachers());
        });

    // ── School status: app_config/school_status → status ──────────────────
    _statusSub = FirebaseFirestore.instance
        .collection('app_config')
        .doc('school_status')
        .snapshots()
        .listen((snap) {
          _schoolStatus = (snap.data()?['status'] as String?) ?? 'normal';
          unawaited(_pushSchedule());
        });

    // ── Schedule timer every 30s ───────────────────────────────────────────
    _scheduleTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_pushSchedule()),
    );
    _pushSchedule();
  }

  static void stop() {
    _busSub?.cancel();
    _teacherSub?.cancel();
    _absenceSub?.cancel();
    _statusSub?.cancel();
    _starredBusSub?.cancel();
    _starredTeacherSub?.cancel();
    _scheduleTimer?.cancel();
    _starredBuses = {};
    _starredTeachers = {};
    _allBuses = [];
    _allTeachers = {};
    _absences = {};
    _schoolStatus = 'normal';
  }

  // ── Push: buses ────────────────────────────────────────────────────────────

  static Future<void> _pushBuses() async {
    final starred = _allBuses
        .where((b) => _starredBuses.contains(b['town']))
        .map(
          (b) => {
            'town': (b['town'] ?? '').toString(),
            'code': (b['code'] ?? '?').toString(),
            'status': (b['status'] ?? '').toString(),
          },
        )
        .toList();

    debugPrint('[WidgetBridge] Pushing ${starred.length} starred buses');
    await _save('bus_data', jsonEncode(starred));
    // Verify it was actually written
    final prefs = await HomeWidget.getWidgetData<String>('bus_data');
    debugPrint(
      '[WidgetBridge] Verified bus_data in prefs: ${prefs?.substring(0, (prefs.length > 80 ? 80 : prefs.length))}',
    );
    await _update(ios: _kIosBuses, android: _kAndroidBuses);
  }

  // ── Push: teachers ─────────────────────────────────────────────────────────
  // Absence keys are last names only (e.g. "Hessami").
  // Starred names are full display names (e.g. "Hessami, John" or "Ms. Hessami").
  // We match by checking if the absence key is contained in the display name.

  static Future<void> _pushTeachers() async {
    final list = _starredTeachers.map((displayName) {
      // Look up teacher record for department info
      final t =
          _allTeachers[displayName] ??
          _allTeachers.values.firstWhere(
            (t) => t['name'].toString() == displayName,
            orElse: () => {'name': displayName, 'department': ''},
          );

      // Match absence by last-name substring (same logic as teacher_service.dart)
      String status = 'Present';
      for (final entry in _absences.entries) {
        final absenceKey = entry.key.trim().toLowerCase();
        final nameLower = displayName.toLowerCase();
        // e.g. "hessami" inside "hessami, john" or "ms. hessami"
        if (nameLower.contains(absenceKey)) {
          status = 'Absent';
          break;
        }
      }

      return {
        'name': displayName,
        'department': (t['department'] ?? '').toString(),
        'status': status,
      };
    }).toList();

    debugPrint('[WidgetBridge] Pushing ${list.length} teachers');
    await _save('teacher_data', jsonEncode(list));
    await _update(ios: _kIosTeachers, android: _kAndroidTeachers);
  }

  // ── Push: schedule ─────────────────────────────────────────────────────────

  static Future<void> _pushSchedule() async {
    final payload = _computeSchedulePayload(_schoolStatus);
    await _save('schedule_data', jsonEncode(payload));
    await _update(ios: _kIosSchedule, android: _kAndroidSchedule);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Future<void> _save(String key, String value) async {
    try {
      await HomeWidget.saveWidgetData<String>(key, value);
    } catch (e) {
      debugPrint('[WidgetBridge] saveWidgetData($key) failed: $e');
    }
  }

  static Future<void> _update({
    required String ios,
    required String android,
  }) async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.updateWidget(iOSName: ios);
      } else if (Platform.isAndroid) {
        await HomeWidget.updateWidget(androidName: android);
      }
    } catch (e) {
      debugPrint(
        '[WidgetBridge] updateWidget(ios=$ios, android=$android) failed: $e',
      );
    }
  }
}
