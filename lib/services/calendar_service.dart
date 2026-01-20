import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/group_service.dart';
import '../models/group.dart';

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
  static const _spreadsheetId = '1Ocm7wpxK9_xlkJGe9z8zH-I5TPsio1fZAxUf0rNs5Jk';
  static const _worksheetTitle = 'Calendar';

  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static late final GSheets _gsheets;
  static Future<void>? _initFuture;

  static final ValueNotifier<List<CalendarEvent>> bcaEvents = ValueNotifier([]);
  static final ValueNotifier<List<CalendarEvent>> personalEvents =
      ValueNotifier([]);
  static final ValueNotifier<List<CalendarEvent>> clubEvents = ValueNotifier(
    [],
  );
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Stream subscriptions for club events
  static StreamSubscription<List<Group>>? _userGroupsSubscription;
  static final Map<String, StreamSubscription> _clubEventSubscriptions = {};

  static Future<void> _initGSheets() {
    _initFuture ??= _loadGSheets();
    return _initFuture!;
  }

  static Future<void> _loadGSheets() async {
    final json = await rootBundle.loadString('assets/credentials/gsheets.json');
    _gsheets = GSheets(json);
  }

  static DocumentReference<Map<String, dynamic>> _userEventsRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('calendar')
        .doc('events');
  }

  /// Fetch BCA events from Google Sheets
  static Future<void> fetchBCAEvents() async {
    await _initGSheets();
    final List<CalendarEvent> events = [];

    try {
      final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
      final sheet = spreadsheet.worksheetByTitle(_worksheetTitle);
      if (sheet == null) {
        bcaEvents.value = [];
        return;
      }
      final rows = await sheet.values.allRows();
      if (rows.isEmpty || rows.length < 2) {
        bcaEvents.value = [];
        return;
      }
      // Skip header row
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        try {
          final dateStr = row.length > 0 ? row[0].toString().trim() : '';
          final title = row.length > 1 ? row[1].toString().trim() : '';
          final description = row.length > 2 ? row[2].toString().trim() : '';

          if (dateStr.isEmpty || title.isEmpty) continue;

          final date = _parseDate(dateStr);
          if (date == null) continue;

          events.add(
            CalendarEvent(
              id: 'bca_${date.millisecondsSinceEpoch}_$i',
              title: title,
              date: date,
              description: description.isEmpty ? null : description,
              category: 'bca',
              isAllDay: true,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing row $i: $e');
          }
        }
      }

      bcaEvents.value = events;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching BCA events: $e');
      }
      bcaEvents.value = [];
    }
  }

  /// Parse date string in various formats
  static DateTime? _parseDate(String dateStr) {
    try {
      // Try parsing as Excel/Sheets serial number
      final serialNumber = int.tryParse(dateStr);
      if (serialNumber != null) {
        // Excel/Sheets epoch: December 30, 1899
        final epoch = DateTime(1899, 12, 30);
        return epoch.add(Duration(days: serialNumber));
      }

      // Try MM/DD/YYYY format
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.tryParse(parts[0]);
        final day = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        if (month != null && day != null && year != null) {
          return DateTime(year, month, day);
        }
      }

      // Try parsing as ISO format
      return DateTime.tryParse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// Load personal events from Firestore
  static Future<void> loadPersonalEvents() async {
    final user = _auth.currentUser;
    if (user == null) {
      personalEvents.value = [];
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
        } else {
          personalEvents.value = [];
        }
      } else {
        await _userEventsRef(user.uid).set({'events': []});
        personalEvents.value = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading personal events: $e');
      }
      personalEvents.value = [];
    }
  }

  /// Add a personal event
  static Future<void> addPersonalEvent(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = [...personalEvents.value, event];
    personalEvents.value = updated;

    await _savePersonalEvents(user.uid, updated);
  }

  /// Update a personal event
  static Future<void> updatePersonalEvent(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = personalEvents.value
        .map((e) => e.id == event.id ? event : e)
        .toList();

    personalEvents.value = updated;
    await _savePersonalEvents(user.uid, updated);
  }

  /// Delete a personal event
  static Future<void> deletePersonalEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = personalEvents.value.where((e) => e.id != eventId).toList();

    personalEvents.value = updated;
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

  /// Get all events for a specific date
  static List<CalendarEvent> getEventsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    return [
      ...bcaEvents.value.where((e) {
        final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
        return eventDate.isAtSameMomentAs(normalizedDate);
      }),
      ...personalEvents.value.where((e) {
        final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
        return eventDate.isAtSameMomentAs(normalizedDate);
      }),
      ...clubEvents.value.where((e) {
        final eventDate = DateTime(e.date.year, e.date.month, e.date.day);
        return eventDate.isAtSameMomentAs(normalizedDate);
      }),
    ]..sort((a, b) {
      // BCA events first, then club, then personal, then sort by time if available
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
    });
  }

  /// Get events for a month
  static Map<DateTime, List<CalendarEvent>> getEventsForMonth(
    int year,
    int month,
  ) {
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

    return eventsByDate;
  }

  /// Load all events (BCA + personal + club)
  static Future<void> loadAllEvents() async {
    isLoading.value = true;
    await Future.wait([fetchBCAEvents(), loadPersonalEvents()]);
    _startListeningToClubEvents();
    isLoading.value = false;
  }

  /// Start listening to club events from all groups user is a member of
  static void _startListeningToClubEvents() {
    final user = _auth.currentUser;
    if (user == null) {
      clubEvents.value = [];
      return;
    }

    // Cancel existing subscriptions
    _stopListeningToClubEvents();

    final groupService = GroupService();

    // Listen to user groups and set up event listeners for each group
    _userGroupsSubscription = groupService.getUserGroups().listen((groups) {
      // Update subscriptions for each group
      final currentGroupIds = groups.map((g) => g.id).toSet();

      // Remove subscriptions for groups user is no longer a member of
      _clubEventSubscriptions.removeWhere((groupId, subscription) {
        if (!currentGroupIds.contains(groupId)) {
          subscription.cancel();
          return true;
        }
        return false;
      });

      // Add subscriptions for new groups
      for (final group in groups) {
        if (!_clubEventSubscriptions.containsKey(group.id)) {
          _clubEventSubscriptions[group.id] = _firestore
              .collection('groups')
              .doc(group.id)
              .collection('calendar')
              .doc('events')
              .collection('items')
              .orderBy('date')
              .snapshots()
              .listen((snapshot) {
                _updateClubEvents();
              });
        }
      }

      // Initial load
      _updateClubEvents();
    });
  }

  /// Stop listening to club events
  static void _stopListeningToClubEvents() {
    _userGroupsSubscription?.cancel();
    _userGroupsSubscription = null;

    for (final subscription in _clubEventSubscriptions.values) {
      subscription.cancel();
    }
    _clubEventSubscriptions.clear();
  }

  /// Update club events from all subscribed groups
  static Future<void> _updateClubEvents() async {
    final user = _auth.currentUser;
    if (user == null) {
      clubEvents.value = [];
      return;
    }

    try {
      // Get all groups user is a member of
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      final List<CalendarEvent> allClubEvents = [];

      for (final groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;

        // Check if user is a member
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(user.uid)
            .get();

        if (!memberDoc.exists) continue;

        // Get all events for this group
        final eventsSnapshot = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('calendar')
            .doc('events')
            .collection('items')
            .orderBy('date')
            .get();

        for (final eventDoc in eventsSnapshot.docs) {
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
    } catch (e) {
      if (kDebugMode) {
        print('Error updating club events: $e');
      }
      clubEvents.value = [];
    }
  }

  /// Reset all data
  static void reset() {
    _stopListeningToClubEvents();
    bcaEvents.value = [];
    personalEvents.value = [];
    clubEvents.value = [];
    isLoading.value = false;
  }

  /// Add a club event (visible to all group members)
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
  }

  /// Submit a public event request (requires admin approval)
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

    // If bypassing approval, immediately add to BCA calendar
    if (bypassApproval) {
      await _addToBCACalendar(doc.id, event);
    }
  }

  /// Stream public event requests (for admin screen)
  static Stream<QuerySnapshot> streamPublicEventRequests() {
    return _firestore
        .collection('public_event_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  /// Approve a public event request
  static Future<void> approvePublicEventRequest(
    String groupId,
    String requestId,
    Map<String, dynamic> eventData,
  ) async {
    // Update request status
    await _firestore.collection('public_event_requests').doc(requestId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': _auth.currentUser?.uid,
    });

    // Add to BCA calendar (Google Sheets)
    final event = CalendarEvent(
      id: requestId,
      title: eventData['title'] as String,
      date: (eventData['date'] as Timestamp).toDate(),
      description: eventData['description'] as String?,
      category: 'bca',
      isAllDay: eventData['isAllDay'] as bool? ?? true,
      startTime: eventData['startTime'] != null
          ? (eventData['startTime'] as Timestamp).toDate()
          : null,
      endTime: eventData['endTime'] != null
          ? (eventData['endTime'] as Timestamp).toDate()
          : null,
    );

    await _addToBCACalendar(requestId, event);

    // Refresh BCA events to show the new event
    await fetchBCAEvents();
  }

  /// Reject a public event request
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

  /// Add event to BCA Google Sheets calendar
  static Future<void> _addToBCACalendar(
    String eventId,
    CalendarEvent event,
  ) async {
    await _initGSheets();

    try {
      final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
      final sheet = spreadsheet.worksheetByTitle(_worksheetTitle);

      if (sheet == null) {
        throw Exception('Calendar worksheet not found');
      }

      // Format date as MM/DD/YYYY
      final dateStr =
          '${event.date.month}/${event.date.day}/${event.date.year}';

      // Append row to sheet
      await sheet.values.appendRow([
        dateStr,
        event.title,
        event.description ?? '',
      ]);

      if (kDebugMode) {
        print('Successfully added event to BCA calendar: ${event.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding to BCA calendar: $e');
      }
      rethrow;
    }
  }
}
