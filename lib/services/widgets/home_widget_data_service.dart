import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/features/absence/services/teacher_service.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/features/calendar/services/calendar_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeWidgetDataService {
  static const _appGroupId = 'group.com.arjunyuvaraj.gr0ve';
  static const _busRefreshKey = 'home_widget_bus_refreshed_at';
  static const _teacherRefreshKey = 'home_widget_teacher_refreshed_at';
  static const _eventsRefreshKey = 'home_widget_events_refreshed_at';
  static const _schoolStatusRefreshKey =
      'home_widget_school_status_refreshed_at';
  static const _schoolStatusCacheKey = 'home_widget_school_status';
  static Timer? _scheduleTimer;
  static Timer? _busRefreshDebounce;
  static Timer? _teacherRefreshDebounce;
  static Timer? _eventsRefreshDebounce;
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;

    await HomeWidget.setAppGroupId(_appGroupId);
    StarredBusService.starredTowns.addListener(_scheduleBusRefresh);
    StarredTeacherService.starredTeachers.addListener(_scheduleTeacherRefresh);
    CalendarService.eventsVersion.addListener(_scheduleEventsRefresh);

    _scheduleTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => refreshSchedule(),
    );

    await refreshAll(forceFirebase: false);
  }

  static Future<void> stop() async {
    if (!_started) return;
    _started = false;

    StarredBusService.starredTowns.removeListener(_scheduleBusRefresh);
    StarredTeacherService.starredTeachers.removeListener(
      _scheduleTeacherRefresh,
    );
    CalendarService.eventsVersion.removeListener(_scheduleEventsRefresh);
    _scheduleTimer?.cancel();
    _busRefreshDebounce?.cancel();
    _teacherRefreshDebounce?.cancel();
    _eventsRefreshDebounce?.cancel();
    _scheduleTimer = null;
    _busRefreshDebounce = null;
    _teacherRefreshDebounce = null;
    _eventsRefreshDebounce = null;

    await Future.wait([
      HomeWidget.saveWidgetData<String>('bus_data', '[]'),
      HomeWidget.saveWidgetData<String>('teacher_data', '[]'),
      HomeWidget.saveWidgetData<String>('schedule_data', '{}'),
      HomeWidget.saveWidgetData<String>('events_data', '[]'),
    ]);
    await _updateWidgets();
  }

  static void _scheduleBusRefresh() {
    _busRefreshDebounce?.cancel();
    _busRefreshDebounce = Timer(
      const Duration(milliseconds: 400),
      () => refreshBuses(force: true),
    );
  }

  static void _scheduleTeacherRefresh() {
    _teacherRefreshDebounce?.cancel();
    _teacherRefreshDebounce = Timer(
      const Duration(milliseconds: 400),
      () => refreshTeachers(force: true),
    );
  }

  static void _scheduleEventsRefresh() {
    _eventsRefreshDebounce?.cancel();
    _eventsRefreshDebounce = Timer(
      const Duration(milliseconds: 400),
      () => refreshEvents(force: true),
    );
  }

  static Future<void> refreshAll({bool forceFirebase = false}) async {
    try {
      await Future.wait([
        refreshBuses(force: forceFirebase),
        refreshTeachers(force: forceFirebase),
        refreshSchedule(),
        refreshEvents(force: forceFirebase),
      ]);
    } catch (e) {
      if (kDebugMode) print('[Widgets] refresh failed: $e');
    }
  }

  static Future<void> refreshBuses({bool force = false}) async {
    if (!force && !await _shouldRefresh(_busRefreshKey, _busTtl())) {
      await _updateWidgets(
        names: const ['Gr0veBusWidget', 'Gr0veBusWidgetProvider'],
      );
      return;
    }

    final starred = StarredBusService.starredTowns.value;
    final routes = await fetchBusRoutes();
    final data = routes
        .where((route) => starred.contains(route.town))
        .map((route) => route.toJson())
        .toList();

    await HomeWidget.saveWidgetData<String>('bus_data', jsonEncode(data));
    await _markRefreshed(_busRefreshKey);
    await _updateWidgets(
      names: const ['Gr0veBusWidget', 'Gr0veBusWidgetProvider'],
    );
  }

  static Future<void> refreshTeachers({bool force = false}) async {
    if (!force &&
        !await _shouldRefresh(
          _teacherRefreshKey,
          const Duration(minutes: 30),
        )) {
      await _updateWidgets(
        names: const ['Gr0veTeacherWidget', 'Gr0veTeacherWidgetProvider'],
      );
      return;
    }

    final starred = StarredTeacherService.starredTeachers.value.toList()
      ..sort();
    final absences = await fetchGoogleSheetAbsences(
      spreadsheetId: '',
      worksheetTitle: '',
    );
    final allTeachers = await fetchAllTeachersFromFirebase();
    final byName = {
      for (final teacher in allTeachers)
        teacher['name']?.toString() ?? '': teacher,
    };

    final data = starred.map((name) {
      final teacher = byName[name] ?? const <String, dynamic>{};
      final status = formatStatusString(
        resolveTeacherStatus(teacherName: name, absenceMap: absences),
      );
      return {
        'name': name,
        'department': teacher['department']?.toString() ?? '',
        'status': status,
      };
    }).toList();

    data.sort((a, b) {
      final aPresent = a['status'] == 'Present';
      final bPresent = b['status'] == 'Present';
      if (aPresent != bPresent) return aPresent ? 1 : -1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    await HomeWidget.saveWidgetData<String>('teacher_data', jsonEncode(data));
    await _markRefreshed(_teacherRefreshKey);
    await _updateWidgets(
      names: const ['Gr0veTeacherWidget', 'Gr0veTeacherWidgetProvider'],
    );
  }

  static Future<void> refreshSchedule() async {
    final status = await _schoolStatus();
    final data = _schedulePayload(DateTime.now(), status);
    await HomeWidget.saveWidgetData<String>('schedule_data', jsonEncode(data));
    await _updateWidgets(
      names: const ['Gr0veScheduleWidget', 'Gr0veScheduleWidgetProvider'],
    );
  }

  static Future<void> refreshEvents({bool force = false}) async {
    if (!force &&
        !await _shouldRefresh(_eventsRefreshKey, const Duration(minutes: 15))) {
      await _updateWidgets(
        names: const ['Gr0veEventsWidget', 'Gr0veEventsWidgetProvider'],
      );
      return;
    }

    if (CalendarService.eventsVersion.value == 0) {
      await CalendarService.loadAllEvents();
    }

    final today = DateTime.now();
    final data = CalendarService.getEventsForDate(today).map((event) {
      final start = event.startTime;
      final end = event.endTime;
      return {
        'title': event.title,
        'category': event.category,
        'personalCategory': event.personalCategory ?? '',
        'description': event.description ?? '',
        'isAllDay': event.isAllDay,
        'time': event.isAllDay
            ? 'All day'
            : _timeRange(start ?? event.date, end),
      };
    }).toList();

    await HomeWidget.saveWidgetData<String>('events_data', jsonEncode(data));
    await _markRefreshed(_eventsRefreshKey);
    await _updateWidgets(
      names: const ['Gr0veEventsWidget', 'Gr0veEventsWidgetProvider'],
    );
  }

  static Future<void> _updateWidgets({List<String>? names}) async {
    final widgetNames =
        names ??
        const [
          'Gr0veBusWidget',
          'Gr0veTeacherWidget',
          'Gr0veScheduleWidget',
          'Gr0veEventsWidget',
          'Gr0veBusWidgetProvider',
          'Gr0veTeacherWidgetProvider',
          'Gr0veScheduleWidgetProvider',
          'Gr0veEventsWidgetProvider',
        ];

    for (final name in widgetNames) {
      try {
        await HomeWidget.updateWidget(name: name, iOSName: name);
      } catch (_) {}
    }
  }

  static Future<String> _schoolStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_schoolStatusCacheKey) ?? 'normal';
    if (!await _shouldRefresh(
      _schoolStatusRefreshKey,
      const Duration(minutes: 15),
    )) {
      return cached;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('school_status')
          .get()
          .timeout(const Duration(seconds: 4));
      final status = doc.data()?['status']?.toString() ?? 'normal';
      await prefs.setString(_schoolStatusCacheKey, status);
      await _markRefreshed(_schoolStatusRefreshKey);
      return status;
    } catch (_) {
      return cached;
    }
  }

  static Duration _busTtl() {
    final now = DateTime.now();
    final weekday =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    final minute = now.hour * 60 + now.minute;
    final dismissalWindow = minute >= 14 * 60 && minute <= 17 * 60;
    return weekday && dismissalWindow
        ? const Duration(minutes: 2)
        : const Duration(minutes: 10);
  }

  static Future<bool> _shouldRefresh(String key, Duration ttl) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(key);
    if (last == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= ttl.inMilliseconds;
  }

  static Future<void> _markRefreshed(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  static Map<String, dynamic> _schedulePayload(DateTime now, String status) {
    final schedule = _scheduleFor(status);
    final currentMinute = now.hour * 60.0 + now.minute + now.second / 60.0;
    const countdownWindow = 60;
    final start = schedule.first.startMins.toDouble();
    final end = schedule.last.endMins.toDouble();

    if (currentMinute < start - countdownWindow) {
      return {
        'phase': 'pre',
        'label': 'Before school',
        'secs': 0,
        'prog': 0.0,
        'next': schedule.first.label,
      };
    }

    if (currentMinute < start) {
      final diff = ((start - currentMinute) * 60).round();
      return {
        'phase': 'countdown',
        'label': 'Until school',
        'secs': diff,
        'prog': (1 - diff / (countdownWindow * 60)).clamp(0.0, 1.0),
        'next': schedule.first.label,
      };
    }

    if (currentMinute >= end) {
      return {
        'phase': 'done',
        'label': 'Done',
        'secs': 0,
        'prog': 1.0,
        'next': '',
      };
    }

    for (var i = 0; i < schedule.length; i++) {
      final period = schedule[i];
      if (currentMinute >= period.startMins && currentMinute < period.endMins) {
        final left = ((period.endMins - currentMinute) * 60).round();
        return {
          'phase': 'period',
          'label': period.label,
          'secs': left,
          'prog': (1 - left / (period.durationMins * 60)).clamp(0.0, 1.0),
          'next': i < schedule.length - 1 ? schedule[i + 1].label : '',
        };
      }

      if (i < schedule.length - 1) {
        final next = schedule[i + 1];
        if (currentMinute >= period.endMins && currentMinute < next.startMins) {
          return {
            'phase': 'passing',
            'label': 'Passing',
            'secs': ((next.startMins - currentMinute) * 60).round(),
            'prog': 0.5,
            'next': next.label,
          };
        }
      }
    }

    return {'phase': 'pre', 'label': 'Before school', 'secs': 0, 'prog': 0.0};
  }

  static String _timeRange(DateTime start, DateTime? end) {
    final startLabel = _timeLabel(start);
    if (end == null) return startLabel;
    return '$startLabel-${_timeLabel(end)}';
  }

  static String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _WidgetPeriod {
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const _WidgetPeriod(
    this.label,
    this.startHour,
    this.startMinute,
    this.endHour,
    this.endMinute,
  );

  int get startMins => startHour * 60 + startMinute;
  int get endMins => endHour * 60 + endMinute;
  int get durationMins => endMins - startMins;
}

const _normalSchedule = [
  _WidgetPeriod('Period 1', 8, 0, 8, 50),
  _WidgetPeriod('IGS', 8, 54, 8, 58),
  _WidgetPeriod('Period 2', 9, 2, 9, 52),
  _WidgetPeriod('Period 3', 9, 56, 10, 46),
  _WidgetPeriod('Period 4', 10, 50, 11, 40),
  _WidgetPeriod('Period 5', 11, 44, 12, 34),
  _WidgetPeriod('Period 6', 12, 38, 13, 28),
  _WidgetPeriod('Period 7', 13, 32, 14, 22),
  _WidgetPeriod('Period 8', 14, 26, 15, 16),
  _WidgetPeriod('Period 9', 15, 20, 16, 10),
];

const _halfDaySchedule = [
  _WidgetPeriod('Period 1', 8, 0, 8, 25),
  _WidgetPeriod('IGS', 8, 29, 8, 38),
  _WidgetPeriod('Period 2', 8, 42, 9, 7),
  _WidgetPeriod('Period 3', 9, 11, 9, 36),
  _WidgetPeriod('Period 4', 9, 40, 10, 5),
  _WidgetPeriod('Period 5', 10, 9, 10, 34),
  _WidgetPeriod('Period 6', 10, 38, 11, 3),
  _WidgetPeriod('Period 7', 11, 7, 11, 32),
  _WidgetPeriod('Period 8', 11, 36, 12, 1),
  _WidgetPeriod('Period 9', 12, 5, 12, 30),
];

const _delayedSchedule = [
  _WidgetPeriod('IGS', 9, 30, 10, 10),
  _WidgetPeriod('Period 1', 10, 15, 10, 50),
  _WidgetPeriod('Period 2', 10, 55, 11, 30),
  _WidgetPeriod('Period 3', 11, 35, 12, 10),
  _WidgetPeriod('Period 4', 12, 15, 12, 50),
  _WidgetPeriod('Period 5', 12, 55, 13, 30),
  _WidgetPeriod('Period 6', 13, 35, 14, 10),
  _WidgetPeriod('Period 7', 14, 15, 14, 50),
  _WidgetPeriod('Period 8', 14, 55, 15, 30),
  _WidgetPeriod('Period 9', 15, 35, 16, 10),
];

List<_WidgetPeriod> _scheduleFor(String status) => switch (status) {
  'half_day' => _halfDaySchedule,
  'delayed_opening' => _delayedSchedule,
  _ => _normalSchedule,
};
