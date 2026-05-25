import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';

enum CardId {
  countdown,
  absence,
  buses,
  weather,
  upcoming,
  pomodoro;

  String get label => switch (this) {
    CardId.countdown => 'Schedule',
    CardId.absence => 'Absences',
    CardId.buses => 'Buses',
    CardId.weather => 'Weather',
    CardId.upcoming => 'Upcoming',
    CardId.pomodoro => 'Focus Timer',
  };

  dynamic get icon => switch (this) {
    CardId.countdown => HugeIcons.strokeRoundedTimer02,
    CardId.absence => HugeIcons.strokeRoundedUser,
    CardId.buses => HugeIcons.strokeRoundedBus02,
    CardId.weather => HugeIcons.strokeRoundedCloud,
    CardId.upcoming => HugeIcons.strokeRoundedCalendar03,
    CardId.pomodoro => HugeIcons.strokeRoundedTarget01,
  };

  static CardId? tryParse(String n) =>
      CardId.values.where((c) => c.name == n).firstOrNull;
}

enum TimePeriod {
  school,
  afternoon,
  evening;

  String get id => switch (this) {
    TimePeriod.school => 'school',
    TimePeriod.afternoon => 'afternoon',
    TimePeriod.evening => 'evening',
  };

  String get label => switch (this) {
    TimePeriod.school => 'School Hours',
    TimePeriod.afternoon => 'After School',
    TimePeriod.evening => 'Evening',
  };
}

class LayoutService {
  static final schoolLayout = ValueNotifier<List<CardId>>(_defSchool());
  static final afternoonLayout = ValueNotifier<List<CardId>>(_defAfternoon());
  static final eveningLayout = ValueNotifier<List<CardId>>(_defEvening());

  static final currentLayout = ValueNotifier<List<CardId>>(_defSchool());
  static Timer? _timeChecker;

  static List<CardId> _defSchool() => [
    CardId.countdown,
    CardId.absence,
    CardId.upcoming,
    CardId.buses,
    CardId.weather,
    CardId.pomodoro,
  ];

  static List<CardId> _defAfternoon() => [
    CardId.buses,
    CardId.weather,
    CardId.upcoming,
    CardId.pomodoro,
    CardId.countdown,
    CardId.absence,
  ];

  static List<CardId> _defEvening() => [
    CardId.pomodoro,
    CardId.upcoming,
    CardId.weather,
    CardId.countdown,
    CardId.absence,
    CardId.buses,
  ];

  static void initializeTimeChecker() {
    _updateCurrentLayout();
    _timeChecker?.cancel();
    _timeChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateCurrentLayout();
    });
  }

  static void _updateCurrentLayout() {
    final now = DateTime.now();
    final totalMinutes = now.hour * 60 + now.minute;

    if (totalMinutes < 970) {
      if (currentLayout.value != schoolLayout.value) {
        currentLayout.value = schoolLayout.value;
      }
    } else if (totalMinutes < 1050) {
      if (currentLayout.value != afternoonLayout.value) {
        currentLayout.value = afternoonLayout.value;
      }
    } else {
      if (currentLayout.value != eveningLayout.value) {
        currentLayout.value = eveningLayout.value;
      }
    }
  }

  static void stopTimeChecker() {
    _timeChecker?.cancel();
  }

  static Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('time_layouts')
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        if (data.containsKey('school_order')) {
          final List<dynamic> o = data['school_order'];
          schoolLayout.value = _parseOrder(o);
        }

        if (data.containsKey('afternoon_order')) {
          final List<dynamic> o = data['afternoon_order'];
          afternoonLayout.value = _parseOrder(o);
        }

        if (data.containsKey('evening_order')) {
          final List<dynamic> o = data['evening_order'];
          eveningLayout.value = _parseOrder(o);
        }
      }

      _updateCurrentLayout();
    } catch (_) {}
  }

  static List<CardId> _parseOrder(List<dynamic> raw) {
    return raw
        .map((j) => CardId.tryParse(j.toString()))
        .where((id) => id != null)
        .cast<CardId>()
        .toList();
  }

  static Future<void> save(TimePeriod period, List<CardId> ids) async {
    switch (period) {
      case TimePeriod.school:
        schoolLayout.value = ids;
        break;
      case TimePeriod.afternoon:
        afternoonLayout.value = ids;
        break;
      case TimePeriod.evening:
        eveningLayout.value = ids;
        break;
    }
    _updateCurrentLayout();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('time_layouts')
          .set({
            '${period.id}_order': ids.map((id) => id.name).toList(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }
}
