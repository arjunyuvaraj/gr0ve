import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/features/club/services/group_service.dart';
import 'package:gr0ve/models/group.dart';

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
  // SECURITY FIX: No more Google Sheets
  // BCA events are now stored directly in Firestore
  // Admins upload events using the Python upload script

  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static final ValueNotifier<List<CalendarEvent>> bcaEvents = ValueNotifier([]);
  static final ValueNotifier<List<CalendarEvent>> personalEvents =
      ValueNotifier([]);
  static final ValueNotifier<List<CalendarEvent>> clubEvents = ValueNotifier(
    [],
  );
  static final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // Single notifier to trigger rebuilds - more efficient than triple nesting
  static final ValueNotifier<int> eventsVersion = ValueNotifier(0);

  // Cache for monthly events
  static final Map<String, Map<DateTime, List<CalendarEvent>>> _monthCache = {};

  // Stream subscriptions for club events
  static StreamSubscription<List<Group>>? _userGroupsSubscription;
  static final Map<String, StreamSubscription> _clubEventSubscriptions = {};

  // Debounce timer for club events
  static Timer? _clubEventsDebounceTimer;

  static DocumentReference<Map<String, dynamic>> _userEventsRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('calendar')
        .doc('events');
  }

  /// Notify listeners that events have changed
  static void _notifyEventsChanged() {
    eventsVersion.value++;
    _clearMonthCache();
  }

  /// Clear the monthly events cache
  static void _clearMonthCache() {
    _monthCache.clear();
  }

  /// Fetch BCA events from Firestore
  static Future<void> fetchBCAEvents() async {
    // SECURITY: Verify user authentication and bergen.org email
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
      // Read BCA events from Firestore
      final snapshot = await _firestore
          .collection('public_data')
          .doc('bca_events')
          .collection('items')
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

  /// Load personal events from Firestore
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

  /// Add a personal event
  static Future<void> addPersonalEvent(CalendarEvent event) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = [...personalEvents.value, event];
    personalEvents.value = updated;
    _notifyEventsChanged();

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
    _notifyEventsChanged();
    await _savePersonalEvents(user.uid, updated);
  }

  /// Delete a personal event
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

  /// Compare two events for sorting
  static int _compareEvents(CalendarEvent a, CalendarEvent b) {
    // BCA events first, then club, then personal
    if (a.category != b.category) {
      if (a.category == 'bca') return -1;
      if (b.category == 'bca') return 1;
      if (a.category == 'club') return -1;
      if (b.category == 'club') return 1;
    }
    // Then sort by time if available
    if (a.startTime != null && b.startTime != null) {
      return a.startTime!.compareTo(b.startTime!);
    }
    return 0;
  }

  /// Get all events for a specific date (optimized)
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

  /// Get events for a month (with caching)
  static Map<DateTime, List<CalendarEvent>> getEventsForMonth(
    int year,
    int month,
  ) {
    final cacheKey = '$year-$month';

    // Check cache first
    if (_monthCache.containsKey(cacheKey)) {
      return _monthCache[cacheKey]!;
    }

    // Build events map
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

    // Cache the result
    _monthCache[cacheKey] = eventsByDate;
    return eventsByDate;
  }

  /// Load all events (BCA + personal + club) - optimized order
  static Future<void> loadAllEvents() async {
    isLoading.value = true;

    // Load personal events first (fastest - single Firestore doc)
    await loadPersonalEvents();

    // Start listening to club events (sets up streams)
    _startListeningToClubEvents();

    // Load club events immediately (parallel with BCA)
    final clubFuture = _updateClubEvents();

    // Load BCA events from Firestore
    final bcaFuture = fetchBCAEvents();

    // Wait for both to complete
    await Future.wait([clubFuture, bcaFuture]);

    isLoading.value = false;
  }

  /// Start listening to club events from all groups user is a member of
  static void _startListeningToClubEvents() {
    final user = _auth.currentUser;
    if (user == null) {
      clubEvents.value = [];
      _notifyEventsChanged();
      return;
    }

    // Cancel existing subscriptions
    _stopListeningToClubEvents();

    final groupService = GroupService();

    // Listen to user groups and set up event listeners for each group
    _userGroupsSubscription = groupService.getUserGroups().listen((groups) {
      if (kDebugMode) {
        print('User is member of ${groups.length} groups');
      }

      // Debounce updates to avoid excessive rebuilds
      _clubEventsDebounceTimer?.cancel();
      _clubEventsDebounceTimer = Timer(const Duration(milliseconds: 300), () {
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
                  if (kDebugMode) {
                    print(
                      'Group ${group.id} events updated: ${snapshot.docs.length} events',
                    );
                  }
                  // Debounce event updates
                  _debouncedUpdateClubEvents();
                });
          }
        }

        // Initial load
        _updateClubEvents();
      });
    });
  }

  /// Debounced version of _updateClubEvents
  static Timer? _updateClubEventsTimer;
  static void _debouncedUpdateClubEvents() {
    _updateClubEventsTimer?.cancel();
    _updateClubEventsTimer = Timer(const Duration(milliseconds: 500), () {
      _updateClubEvents();
    });
  }

  /// Stop listening to club events
  static void _stopListeningToClubEvents() {
    _userGroupsSubscription?.cancel();
    _userGroupsSubscription = null;
    _clubEventsDebounceTimer?.cancel();
    _clubEventsDebounceTimer = null;
    _updateClubEventsTimer?.cancel();
    _updateClubEventsTimer = null;

    for (final subscription in _clubEventSubscriptions.values) {
      subscription.cancel();
    }
    _clubEventSubscriptions.clear();
  }

  /// Update club events from all subscribed groups (OPTIMIZED)
  static Future<void> _updateClubEvents() async {
    final user = _auth.currentUser;
    if (user == null) {
      clubEvents.value = [];
      _notifyEventsChanged();
      return;
    }

    try {
      // OPTIMIZATION: Query groups where user is a member directly
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

        // Fetch all events in parallel
        final eventFutures = userGroupsSnapshot.docs.map((groupDoc) {
          return _firestore
              .collection('groups')
              .doc(groupDoc.id)
              .collection('calendar')
              .doc('events')
              .collection('items')
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
        return;
      } catch (e) {
        if (kDebugMode) {
          print('Optimized query failed, falling back to old method: $e');
        }
      }

      // FALLBACK: Original method if memberIds field doesn't exist
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      if (kDebugMode) {
        print(
          'Found ${groupsSnapshot.docs.length} active groups (fallback method)',
        );
      }

      // Check membership in parallel
      final membershipFutures = groupsSnapshot.docs.map((groupDoc) {
        return _firestore
            .collection('groups')
            .doc(groupDoc.id)
            .collection('members')
            .doc(user.uid)
            .get()
            .then((doc) => doc.exists ? groupDoc.id : null);
      }).toList();

      final memberGroupIds = (await Future.wait(
        membershipFutures,
      )).where((id) => id != null).cast<String>().toList();

      if (kDebugMode) {
        print('User is member of ${memberGroupIds.length} groups');
      }

      // Fetch events for member groups in parallel
      final eventFutures = memberGroupIds.map((groupId) {
        return _firestore
            .collection('groups')
            .doc(groupId)
            .collection('calendar')
            .doc('events')
            .collection('items')
            .orderBy('date')
            .get();
      }).toList();

      final eventSnapshots = await Future.wait(eventFutures);

      final List<CalendarEvent> allClubEvents = [];

      for (final eventsSnapshot in eventSnapshots) {
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

  /// Reset all data
  static void reset() {
    _stopListeningToClubEvents();
    bcaEvents.value = [];
    personalEvents.value = [];
    clubEvents.value = [];
    isLoading.value = false;
    eventsVersion.value = 0;
    _clearMonthCache();
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

    // Manually trigger update after adding event
    await _updateClubEvents();
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
  }

  /// Stream public event requests (for admin screen)
  static Stream<QuerySnapshot> streamPublicEventRequests() {
    return _firestore
        .collection('public_event_requests')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  /// Approve a public event request (adds to BCA calendar)
  static Future<void> approvePublicEventRequest(
    String groupId,
    String requestId,
    Map<String, dynamic> eventData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Update request status
    await _firestore.collection('public_event_requests').doc(requestId).update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': user.uid,
    });

    // Add to BCA calendar
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

    // Refresh BCA events
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
}
