import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class CalendarEvent {
  final String id;
  final String title;
  final DateTime date;
  final String? description;
  final String category;
  final String? personalCategory;
  final bool isAllDay;
  final DateTime? startTime;
  final DateTime? endTime;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    this.description,
    required this.category,
    this.personalCategory,
    this.isAllDay = true,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': Timestamp.fromDate(date),
      'description': description,
      'category': category,
      'personalCategory': personalCategory,
      'isAllDay': isAllDay,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      date: (json['date'] as Timestamp).toDate(),
      description: json['description'] as String?,
      category: json['category'] as String,
      personalCategory: json['personalCategory'] as String?,
      isAllDay: json['isAllDay'] as bool? ?? true,
      startTime: json['startTime'] != null
          ? (json['startTime'] as Timestamp).toDate()
          : null,
      endTime: json['endTime'] != null
          ? (json['endTime'] as Timestamp).toDate()
          : null,
    );
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? description,
    String? category,
    String? personalCategory,
    bool? isAllDay,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
      category: category ?? this.category,
      personalCategory: personalCategory ?? this.personalCategory,
      isAllDay: isAllDay ?? this.isAllDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class CalendarService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static final ValueNotifier<List<CalendarEvent>> bcaEvents = ValueNotifier([]);
  static final ValueNotifier<List<CalendarEvent>> personalEvents =
      ValueNotifier([]);
  static final ValueNotifier<List<CalendarEvent>> clubEvents = ValueNotifier(
    [],
  );
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);

  static final ValueNotifier<int> eventsVersion = ValueNotifier(0);

  static final Map<String, Map<DateTime, List<CalendarEvent>>> _monthCache = {};

  static DateTime get _eventWindowStart {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));
  }

  static DateTime get _eventWindowEnd {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 365));
  }

  static DocumentReference<Map<String, dynamic>> _userEventsRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('calendar')
        .doc('events');
  }

  static void _notifyEventsChanged() {
    eventsVersion.value++;
    _clearMonthCache();
  }

  static void _clearMonthCache() {
    _monthCache.clear();
  }

  static Future<void> fetchBCAEvents() async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      bcaEvents.value = [];
      _notifyEventsChanged();
      return;
    }

    if (!user.email!.toLowerCase().endsWith('@bergen.org')) {
      bcaEvents.value = [];
      _notifyEventsChanged();
      return;
    }

    final List<CalendarEvent> events = [];

    try {
      final snapshot = await _firestore
          .collection('public_data')
          .doc('bca_events')
          .collection('items')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_eventWindowStart),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(_eventWindowEnd),
          )
          .orderBy('date')
          .get();

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final event = CalendarEvent(
            id: data['id'] ?? doc.id,
            title: data['title'] ?? '',
            date: (data['date'] as Timestamp).toDate(),
            description: data['description'] as String?,
            category: 'bca',
            isAllDay: data['isAllDay'] as bool? ?? true,
            startTime: data['startTime'] != null
                ? (data['startTime'] as Timestamp).toDate()
                : null,
            endTime: data['endTime'] != null
                ? (data['endTime'] as Timestamp).toDate()
                : null,
          );
          events.add(event);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing BCA event ${doc.id}: $e');
          }
        }
      }

      bcaEvents.value = events;
      _notifyEventsChanged();
      if (kDebugMode) {
        print('Loaded ${events.length} BCA events from Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching BCA events from Firestore: $e');
      }
      bcaEvents.value = [];
      _notifyEventsChanged();
    }
  }

  static Future<void> loadPersonalEvents() async {
    final user = _auth.currentUser;
    if (user == null) {
      personalEvents.value = [];
      _notifyEventsChanged();
      return;
    }

    try {
      final doc = await _userEventsRef(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        final List<dynamic>? eventsData = data?['events'];

        if (eventsData != null) {
          final events = eventsData
              .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList();
          personalEvents.value = events;
          _notifyEventsChanged();
          if (kDebugMode) {
            print('Loaded ${events.length} personal events');
          }
        } else {
          personalEvents.value = [];
          _notifyEventsChanged();
        }
      } else {
        await _userEventsRef(user.uid).set({'events': []});
        personalEvents.value = [];
        _notifyEventsChanged();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading personal events: $e');
      }
      personalEvents.value = [];
      _notifyEventsChanged();
    }
  }

  static Future<void> addPersonalEvent(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = [...personalEvents.value, event];
    personalEvents.value = updated;
    _notifyEventsChanged();

    await _savePersonalEvents(user.uid, updated);
  }

  static Future<void> updatePersonalEvent(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = personalEvents.value
        .map((e) => e.id == event.id ? event : e)
        .toList();

    personalEvents.value = updated;
    _notifyEventsChanged();
    await _savePersonalEvents(user.uid, updated);
  }

  static Future<void> deletePersonalEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = personalEvents.value.where((e) => e.id != eventId).toList();

    personalEvents.value = updated;
    _notifyEventsChanged();
    await _savePersonalEvents(user.uid, updated);
  }

  static Future<void> _savePersonalEvents(
    String uid,
    List<CalendarEvent> events,
  ) async {
    await _userEventsRef(uid).set({
      'events': events.map((e) => e.toJson()).toList(),
    }, SetOptions(merge: true));
  }

  static int _compareEvents(CalendarEvent a, CalendarEvent b) {
    if (a.category != b.category) {
      if (a.category == 'bca') return -1;
      if (b.category == 'bca') return 1;
      if (a.category == 'club') return -1;
      if (b.category == 'club') return 1;
    }

    if (a.startTime != null && b.startTime != null) {
      return a.startTime!.compareTo(b.startTime!);
    }
    return 0;
  }

  static List<CalendarEvent> getEventsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedTime = normalizedDate.millisecondsSinceEpoch;

    bool matchesDate(CalendarEvent e) {
      final eventTime = DateTime(
        e.date.year,
        e.date.month,
        e.date.day,
      ).millisecondsSinceEpoch;
      return eventTime == normalizedTime;
    }

    return [
      ...bcaEvents.value.where(matchesDate),
      ...personalEvents.value.where(matchesDate),
      ...clubEvents.value.where(matchesDate),
    ]..sort(_compareEvents);
  }

  static Map<DateTime, List<CalendarEvent>> getEventsForMonth(
    int year,
    int month,
  ) {
    final cacheKey = '$year-$month';

    if (_monthCache.containsKey(cacheKey)) {
      return _monthCache[cacheKey]!;
    }

    final Map<DateTime, List<CalendarEvent>> eventsByDate = {};

    final allEvents = [
      ...bcaEvents.value,
      ...personalEvents.value,
      ...clubEvents.value,
    ];

    for (final event in allEvents) {
      if (event.date.year == year && event.date.month == month) {
        final normalizedDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );

        if (!eventsByDate.containsKey(normalizedDate)) {
          eventsByDate[normalizedDate] = [];
        }
        eventsByDate[normalizedDate]!.add(event);
      }
    }

    _monthCache[cacheKey] = eventsByDate;
    return eventsByDate;
  }

  static Stream<List<CalendarEvent>> upcomingEventsStream({
    int days = 7,
    int limit = 5,
  }) {
    return eventsVersion.toStream().map((_) {
      final now = DateTime.now();
      final cutoff = now.add(Duration(days: days));
      final events = <CalendarEvent>[];

      for (int i = 0; i < days; i++) {
        events.addAll(getEventsForDate(now.add(Duration(days: i))));
      }

      final seen = <String>{};
      final unique = events.where((e) {
        if (seen.contains(e.id)) return false;
        seen.add(e.id);
        return e.date.isBefore(cutoff) || e.date.isAtSameMomentAs(cutoff);
      }).toList();

      unique.sort((a, b) => a.date.compareTo(b.date));
      return unique.take(limit).toList();
    });
  }

  static Future<void> loadAllEvents() async {
    isLoading.value = true;

    await loadPersonalEvents();

    final clubFuture = _updateClubEvents();

    final bcaFuture = fetchBCAEvents();

    await Future.wait([clubFuture, bcaFuture]);

    isLoading.value = false;
  }

  static Future<void> _updateClubEvents() async {
    final user = _auth.currentUser;
    if (user == null) {
      clubEvents.value = [];
      _notifyEventsChanged();
      return;
    }

    try {
      final userGroupsSnapshot = await _firestore
          .collection('groups')
          .where('memberIds', arrayContains: user.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print(
          'Found ${userGroupsSnapshot.docs.length} groups user is member of',
        );
      }

      final eventFutures = userGroupsSnapshot.docs.map((groupDoc) {
        return _firestore
            .collection('groups')
            .doc(groupDoc.id)
            .collection('calendar')
            .doc('events')
            .collection('items')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_eventWindowStart),
            )
            .where(
              'date',
              isLessThanOrEqualTo: Timestamp.fromDate(_eventWindowEnd),
            )
            .orderBy('date')
            .get();
      }).toList();

      final eventSnapshots = await Future.wait(eventFutures);

      final List<CalendarEvent> allClubEvents = [];

      for (var i = 0; i < eventSnapshots.length; i++) {
        for (final eventDoc in eventSnapshots[i].docs) {
          final data = eventDoc.data();
          try {
            final event = CalendarEvent(
              id: data['id'] ?? eventDoc.id,
              title: data['title'] ?? '',
              date: (data['date'] as Timestamp).toDate(),
              description: data['description'] as String?,
              category: 'club',
              isAllDay: data['isAllDay'] as bool? ?? true,
              startTime: data['startTime'] != null
                  ? (data['startTime'] as Timestamp).toDate()
                  : null,
              endTime: data['endTime'] != null
                  ? (data['endTime'] as Timestamp).toDate()
                  : null,
            );
            allClubEvents.add(event);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing club event ${eventDoc.id}: $e');
            }
          }
        }
      }

      clubEvents.value = allClubEvents;
      _notifyEventsChanged();

      if (kDebugMode) {
        print('Total club events loaded: ${allClubEvents.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating club events: $e');
      }
      clubEvents.value = [];
      _notifyEventsChanged();
    }
  }

  static void reset() {
    bcaEvents.value = [];
    personalEvents.value = [];
    clubEvents.value = [];
    isLoading.value = false;
    eventsVersion.value = 0;
    _clearMonthCache();
  }

  static Future<void> addClubEvent(String groupId, CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final doc = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('calendar')
        .doc('events')
        .collection('items')
        .doc();

    await doc.set({
      'id': doc.id,
      'groupId': groupId,
      'title': event.title,
      'description': event.description,
      'date': Timestamp.fromDate(event.date),
      'isAllDay': event.isAllDay,
      'startTime': event.startTime != null
          ? Timestamp.fromDate(event.startTime!)
          : null,
      'endTime': event.endTime != null
          ? Timestamp.fromDate(event.endTime!)
          : null,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'visibility': 'club',
    });

    await _updateClubEvents();
  }

  static Future<void> requestPublicEvent({
    required String groupId,
    required String groupName,
    required CalendarEvent event,
    bool bypassApproval = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final doc = _firestore.collection('public_event_requests').doc();

    await doc.set({
      'id': doc.id,
      'groupId': groupId,
      'groupName': groupName,
      'title': event.title,
      'description': event.description,
      'date': Timestamp.fromDate(event.date),
      'isAllDay': event.isAllDay,
      'startTime': event.startTime != null
          ? Timestamp.fromDate(event.startTime!)
          : null,
      'endTime': event.endTime != null
          ? Timestamp.fromDate(event.endTime!)
          : null,
      'status': bypassApproval ? 'approved' : 'pending',
      'requestedBy': user.uid,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> streamPublicEventRequests() {
    return _firestore
        .collection('public_event_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  static Future<void> approvePublicEventRequest(
    String groupId,
    String requestId,
    Map<String, dynamic> eventData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _firestore.collection('public_event_requests').doc(requestId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': user.uid,
    });

    final eventDoc = _firestore
        .collection('public_data')
        .doc('bca_events')
        .collection('items')
        .doc();

    final eventDate = (eventData['date'] as Timestamp).toDate();

    await eventDoc.set({
      'id': eventDoc.id,
      'title': eventData['title'],
      'description': eventData['description'],
      'date': Timestamp.fromDate(eventDate),
      'isAllDay': eventData['isAllDay'] ?? true,
      'startTime': eventData['startTime'],
      'endTime': eventData['endTime'],
      'approvedBy': user.uid,
      'approvedAt': FieldValue.serverTimestamp(),
      'requestId': requestId,
    });

    await fetchBCAEvents();
  }

  static Future<void> rejectPublicEventRequest(
    String groupId,
    String requestId,
  ) async {
    await _firestore.collection('public_event_requests').doc(requestId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': _auth.currentUser?.uid,
    });
  }
}

extension _ValueNotifierStream<T> on ValueNotifier<T> {
  Stream<T> toStream() {
    late StreamController<T> controller;
    void listener() => controller.add(value);

    controller = StreamController<T>(
      onListen: () {
        addListener(listener);
        controller.add(value);
      },
      onCancel: () => removeListener(listener),
      sync: true,
    );

    return controller.stream;
  }
}
