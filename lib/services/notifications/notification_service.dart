import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/features/bus/services/bus_service.dart';
import 'package:gr0ve/services/starred/starred_bus_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[NOTIF] Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<StreamSubscription> _subscriptions = [];
  final Set<String> _processedIds = {};
  final Map<String, DateTime> _notifiedBuses = {};
  final Map<String, DateTime> _lastShownPayloads = {};
  Timer? _busCheckTimer;

  void Function(NotificationResponse)? _onNotificationTapCallback;

  static const String _notifiedBusesKey = 'notified_buses';

  // Unread tracking
  final Map<String, int> _unreadAnnouncementsByClub = {};
  final Map<String, int> _unreadQAByClub = {};
  final Map<String, int> _unreadQAByAnnouncement =
      {}; // NEW: unread Q&A by announcement
  final Map<String, int> _unreadQuestionsById =
      {}; // NEW: unread by question ID
  final Map<String, int> _unreadCounts = {
    'join_requests': 0,
    'club_requests': 0,
    'bus': 0,
    'qa_replies': 0,
    'unread_questions': 0,
  };

  final _unreadCountController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get unreadCountStream =>
      _unreadCountController.stream;

  Map<String, int> get unreadCounts => Map.from(_unreadCounts);
  Map<String, int> get unreadAnnouncementsByClub =>
      Map.from(_unreadAnnouncementsByClub);
  Map<String, int> get unreadQAByClub => Map.from(_unreadQAByClub);
  Map<String, int> get unreadQAByAnnouncement =>
      Map.from(_unreadQAByAnnouncement);
  Map<String, int> get unreadQuestionsById => Map.from(_unreadQuestionsById);

  void setNotificationTapCallback(
    void Function(NotificationResponse) callback,
  ) {
    _onNotificationTapCallback = callback;
    print('[NOTIF] Notification tap callback registered');
  }

  // ---------------------------------------------------------------------------
  // Initialise
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    print('[NOTIF] Initializing notification service...');

    await _loadNotifiedBuses();
    await _loadUnreadCounts();

    const androidSettings = AndroidInitializationSettings(
      'ic_stat_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    await _initializeFCM();

    print('[NOTIF] Notification service initialized');
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _unreadCounts['join_requests'] =
          prefs.getInt('unread_join_requests') ?? 0;
      _unreadCounts['club_requests'] =
          prefs.getInt('unread_club_requests') ?? 0;
      _unreadCounts['bus'] = prefs.getInt('unread_bus') ?? 0;
      _unreadCounts['qa_replies'] = prefs.getInt('unread_qa_replies') ?? 0;
      _unreadCounts['unread_questions'] = prefs.getInt('unread_questions') ?? 0;

      final clubAnnouncementsJson = prefs.getString(
        'unread_announcements_by_club',
      );
      if (clubAnnouncementsJson != null) {
        final Map<String, dynamic> decoded = json.decode(clubAnnouncementsJson);
        decoded.forEach((key, value) {
          _unreadAnnouncementsByClub[key] = value as int;
        });
      }

      final clubQAJson = prefs.getString('unread_qa_by_club');
      if (clubQAJson != null) {
        final Map<String, dynamic> decoded = json.decode(clubQAJson);
        decoded.forEach((key, value) {
          _unreadQAByClub[key] = value as int;
        });
      }

      final annQAJson = prefs.getString('unread_qa_by_announcement');
      if (annQAJson != null) {
        final Map<String, dynamic> decoded = json.decode(annQAJson);
        decoded.forEach((key, value) {
          _unreadQAByAnnouncement[key] = value as int;
        });
      }

      final qIdJson = prefs.getString('unread_questions_by_id');
      if (qIdJson != null) {
        final Map<String, dynamic> decoded = json.decode(qIdJson);
        decoded.forEach((key, value) {
          _unreadQuestionsById[key] = value as int;
        });
      }

      _notifyUnreadCountUpdate();
      print('[NOTIF] Loaded unread counts: $_unreadCounts');
    } catch (e) {
      print('[NOTIF] Error loading unread counts: $e');
    }
  }

  Future<void> _saveUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'unread_join_requests',
        _unreadCounts['join_requests'] ?? 0,
      );
      await prefs.setInt(
        'unread_club_requests',
        _unreadCounts['club_requests'] ?? 0,
      );
      await prefs.setInt('unread_bus', _unreadCounts['bus'] ?? 0);
      await prefs.setInt('unread_qa_replies', _unreadCounts['qa_replies'] ?? 0);
      await prefs.setInt(
        'unread_questions',
        _unreadCounts['unread_questions'] ?? 0,
      );
      await prefs.setString(
        'unread_announcements_by_club',
        json.encode(_unreadAnnouncementsByClub),
      );
      await prefs.setString('unread_qa_by_club', json.encode(_unreadQAByClub));
      await prefs.setString(
        'unread_qa_by_announcement',
        json.encode(_unreadQAByAnnouncement),
      );
      await prefs.setString(
        'unread_questions_by_id',
        json.encode(_unreadQuestionsById),
      );
      _notifyUnreadCountUpdate();
    } catch (e) {
      print('[NOTIF] Error saving unread counts: $e');
    }
  }

  void _notifyUnreadCountUpdate() {
    if (!_unreadCountController.isClosed) {
      _unreadCountController.add({
        'counts': Map.from(_unreadCounts),
        'announcementsByClub': Map.from(_unreadAnnouncementsByClub),
        'qaByClub': Map.from(_unreadQAByClub),
        'qaByAnnouncement': Map.from(_unreadQAByAnnouncement),
        'questionsById': Map.from(_unreadQuestionsById),
      });
    }
  }

  void _incrementQuestionUnreadCount(String questionId) {
    _unreadQuestionsById[questionId] =
        (_unreadQuestionsById[questionId] ?? 0) + 1;
    _saveUnreadCounts();
  }

  Future<void> clearQuestionUnreadCount(String questionId) async {
    _unreadQuestionsById[questionId] = 0;
    await _saveUnreadCounts();
  }

  int getQuestionUnreadCount(String questionId) =>
      _unreadQuestionsById[questionId] ?? 0;

  void _incrementUnreadCount(String type) {
    _unreadCounts[type] = (_unreadCounts[type] ?? 0) + 1;
    _saveUnreadCounts();
  }

  void _incrementClubAnnouncementCount(String groupId) {
    _unreadAnnouncementsByClub[groupId] =
        (_unreadAnnouncementsByClub[groupId] ?? 0) + 1;
    _saveUnreadCounts();
  }

  void _incrementClubQACount(String groupId) {
    _unreadQAByClub[groupId] = (_unreadQAByClub[groupId] ?? 0) + 1;
    _saveUnreadCounts();
  }

  void _incrementAnnouncementQACount(String groupId, String announcementId) {
    _unreadQAByAnnouncement[announcementId] =
        (_unreadQAByAnnouncement[announcementId] ?? 0) + 1;
    _saveUnreadCounts();
  }

  Future<void> clearUnreadCount(String type) async {
    _unreadCounts[type] = 0;
    await _saveUnreadCounts();
  }

  Future<void> clearClubAnnouncementCount(String groupId) async {
    _unreadAnnouncementsByClub[groupId] = 0;
    _unreadQAByClub[groupId] = 0;
    await _saveUnreadCounts();
  }

  Future<void> clearClubQACount(String groupId) async {
    _unreadQAByClub[groupId] = 0;
    await _saveUnreadCounts();
  }

  Future<void> clearAnnouncementQACount(
    String groupId,
    String announcementId,
  ) async {
    final count = _unreadQAByAnnouncement[announcementId] ?? 0;
    _unreadQAByAnnouncement[announcementId] = 0;
    _unreadQAByClub[groupId] = (_unreadQAByClub[groupId] ?? 0) - count;
    if (_unreadQAByClub[groupId]! < 0) _unreadQAByClub[groupId] = 0;
    await _saveUnreadCounts();
  }

  Future<void> clearAllAnnouncementCounts() async {
    _unreadAnnouncementsByClub.clear();
    _unreadQAByClub.clear();
    _unreadQAByAnnouncement.clear();
    _unreadCounts['qa_replies'] = 0;
    _unreadCounts['unread_questions'] = 0;
    await _saveUnreadCounts();
  }

  int getClubUnreadCount(String groupId) =>
      (_unreadAnnouncementsByClub[groupId] ?? 0) +
      (_unreadQAByClub[groupId] ?? 0);

  int getAnnouncementUnreadQACount(String announcementId) =>
      _unreadQAByAnnouncement[announcementId] ?? 0;

  // ---------------------------------------------------------------------------
  // Persisted bus tracking
  // ---------------------------------------------------------------------------

  Future<void> _loadNotifiedBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_notifiedBusesKey);
      if (storedData != null) {
        final Map<String, dynamic> decoded = json.decode(storedData);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        decoded.forEach((town, timestampString) {
          final notifiedDate = DateTime.parse(timestampString);
          if (!notifiedDate.isBefore(today)) {
            _notifiedBuses[town] = notifiedDate;
          }
        });
      }
    } catch (e) {
      print('[NOTIF] Error loading notified buses: $e');
    }
  }

  Future<void> _saveNotifiedBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> toStore = {};
      _notifiedBuses.forEach((town, dt) {
        toStore[town] = dt.toIso8601String();
      });
      await prefs.setString(_notifiedBusesKey, json.encode(toStore));
    } catch (e) {
      print('[NOTIF] Error saving notified buses: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // FCM
  // ---------------------------------------------------------------------------

  Future<void> _initializeFCM() async {
    print('[NOTIF] Initializing FCM...');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('[NOTIF] FCM Token: ${token.substring(0, 20)}...');
        await _saveFCMToken(token);
      }
    } catch (e) {
      print('[NOTIF] Error getting FCM token: $e');
    }
    _messaging.onTokenRefresh.listen(_saveFCMToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    print('[NOTIF] FCM initialized');
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('[NOTIF] Error saving FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data['payload'],
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('[NOTIF] App opened from notification: ${message.data}');
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('[NOTIF] Notification tapped: ${response.payload}');
    _onNotificationTapCallback?.call(response);
  }

  // ---------------------------------------------------------------------------
  // Start / Stop
  // ---------------------------------------------------------------------------

  Future<void> startListening() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('[NOTIF] Starting listeners for user: ${user.uid}');

    await stopListening();
    _processedIds.clear();

    await _listenForAnnouncements(user.uid);
    await _listenForJoinRequests(user.uid);
    await _listenForClubCreationRequests(user.uid);
    await _listenForQAReplies(user.uid);
    await _listenForNewQuestions(
      user.uid,
    ); // NEW: Notify staff of new questions
    _startBusArrivalMonitoring();

    print('[NOTIF] All listeners started');
  }

  Future<void> stopListening() async {
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _busCheckTimer?.cancel();
    _busCheckTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Bus monitoring
  // ---------------------------------------------------------------------------

  void _startBusArrivalMonitoring() {
    _busCheckTimer?.cancel();
    _busCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkStarredBusArrivals(),
    );
    _checkStarredBusArrivals();
  }

  Future<void> _checkStarredBusArrivals() async {
    try {
      final now = DateTime.now();
      final currentTime = now.hour * 60 + now.minute;
      final lunchStart = 12 * 60;
      final lunchEnd = 13 * 60 + 30;
      final afternoonStart = 15 * 60 + 45;
      final afternoonEnd = 17 * 60 + 45;
      final isAllowed =
          (currentTime >= lunchStart && currentTime <= lunchEnd) ||
          (currentTime >= afternoonStart && currentTime <= afternoonEnd);
      if (!isAllowed) return;

      final starredTowns = StarredBusService.starredTowns.value;
      if (starredTowns.isEmpty) return;

      final routes = await fetchBusRoutes();
      final today = DateTime(now.year, now.month, now.day);

      for (final route in routes) {
        if (starredTowns.contains(route.town) && route.status == 'Arrived') {
          final lastNotified = _notifiedBuses[route.town];
          if (lastNotified == null || lastNotified.isBefore(today)) {
            _notifiedBuses[route.town] = now;
            await _saveNotifiedBuses();
            await _showNotification(
              id: route.town.hashCode,
              title: '🚌 ${route.town}',
              body: 'Parking spot: ${route.code}',
              payload: 'bus:${route.town}',
            );
          }
        }
      }
    } catch (e) {
      print('[NOTIF] Error checking starred bus arrivals: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Announcement listener
  // ---------------------------------------------------------------------------

  Future<void> _listenForAnnouncements(String userId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      final memberGroups = <String>[];
      for (var groupDoc in groupsSnapshot.docs) {
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupDoc.id)
            .collection('members')
            .doc(userId)
            .get();
        if (memberDoc.exists) memberGroups.add(groupDoc.id);
      }

      for (var groupId in memberGroups) {
        final sub = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
              if (snapshot.docs.isEmpty) return;
              if (snapshot.docs.first.metadata.isFromCache) return;

              final doc = snapshot.docs.first;
              if (_processedIds.contains(doc.id)) return;
              _processedIds.add(doc.id);

              final data = doc.data();
              final createdAt = data['createdAt'] as Timestamp?;
              // We removed the authorId check so markers show for authors too
              if (createdAt == null) return;
              if (DateTime.now().difference(createdAt.toDate()).inSeconds > 10)
                return;

              _firestore.collection('groups').doc(groupId).get().then((
                groupDoc,
              ) {
                final groupName = groupDoc.data()?['name'] ?? 'Group';
                _incrementClubAnnouncementCount(groupId);
                _showNotification(
                  id: doc.id.hashCode,
                  title: '📢 $groupName',
                  body: data['title'] ?? 'New announcement',
                  payload: 'announcement:$groupId',
                );
              });
            });
        _subscriptions.add(sub);
      }
    } catch (e) {
      print('[NOTIF] Error setting up announcement listeners: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Q&A reply listener (NEW)
  // Notifies a member when a staff member replies to one of their questions,
  // and notifies staff when a member follows up on a question they've replied to.
  // ---------------------------------------------------------------------------

  Future<void> _listenForQAReplies(String userId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      for (final groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId)
            .get();
        if (!memberDoc.exists) continue;

        final roleStr = memberDoc.data()?['role'] as String? ?? 'member';
        final isStaff = roleStr == 'admin' || roleStr == 'moderator';
        final groupName = groupDoc.data()['name'] ?? 'Group';

        // Track per-question reply subscriptions dynamically
        final Map<String, StreamSubscription> questionReplySubs = {};

        // REACTIVE: Watch the questions collection for this group
        // Uses a Firestore collection group query for efficiency.
        final announcementsRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('announcements');

        // Subscribe to new announcements in real-time so we pick up future ones.
        final announcementSub = announcementsRef.snapshots().listen((
          announcementSnapshot,
        ) {
          for (final announcementChange in announcementSnapshot.docChanges) {
            if (announcementChange.type == DocumentChangeType.removed) continue;
            final announcementDoc = announcementChange.doc;
            final announcementId = announcementDoc.id;
            final announcementTitle =
                (announcementDoc.data() as Map<String, dynamic>)['title']
                    as String? ??
                'Announcement';

            // For this announcement, watch the relevant questions.
            Query questionsQuery = announcementsRef
                .doc(announcementId)
                .collection('questions');

            if (!isStaff) {
              questionsQuery = questionsQuery.where(
                'authorId',
                isEqualTo: userId,
              );
            }

            // REACTIVE: Watch questions for new ones
            final questionSub = questionsQuery.snapshots().listen((
              questionsSnapshot,
            ) {
              for (final questionChange in questionsSnapshot.docChanges) {
                if (questionChange.type == DocumentChangeType.removed) continue;
                final questionDoc = questionChange.doc;
                final questionId = questionDoc.id;
                final questionAuthorId =
                    (questionDoc.data() as Map<String, dynamic>)['authorId']
                        as String? ??
                    '';

                // Watch this question's replies if not already watching it
                final replySubKey = '$announcementId:$questionId';
                if (questionReplySubs.containsKey(replySubKey)) continue;

                final replySub = announcementsRef
                    .doc(announcementId)
                    .collection('questions')
                    .doc(questionId)
                    .collection('replies')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .snapshots()
                    .listen((replySnapshot) {
                      if (replySnapshot.docs.isEmpty) return;
                      if (replySnapshot.docs.first.metadata.isFromCache) return;

                      final replyDoc = replySnapshot.docs.first;
                      final replyId = '${questionId}_${replyDoc.id}';
                      if (_processedIds.contains(replyId)) return;
                      _processedIds.add(replyId);

                      final data = replyDoc.data();
                      final replyAuthorId = data['authorId'] as String? ?? '';
                      final isStaffReply = data['isStaff'] as bool? ?? false;
                      final createdAt = data['createdAt'] as Timestamp?;
                      final replyAuthorName =
                          data['authorName'] as String? ?? 'Someone';

                      if (replyAuthorId == userId) return;
                      if (createdAt == null) return;
                      if (DateTime.now()
                              .difference(createdAt.toDate())
                              .inSeconds >
                          10)
                        return;

                      // Notify the question author
                      if (questionAuthorId == userId) {
                        _incrementUnreadCount('qa_replies');
                        _incrementClubQACount(groupId);
                        _incrementAnnouncementQACount(groupId, announcementId);
                        _incrementQuestionUnreadCount(questionId);
                        _showNotification(
                          id: replyId.hashCode,
                          title: '💬 New reply',
                          body:
                              '$replyAuthorName replied to your question in $groupName',
                          payload:
                              'qa_reply:$groupId:$announcementId:$questionId',
                        );
                      }
                      // Notify staff when a member follows up
                      else if (isStaff && !isStaffReply) {
                        _incrementUnreadCount('qa_replies');
                        _incrementUnreadCount('unread_questions');
                        _incrementClubQACount(groupId);
                        _incrementAnnouncementQACount(groupId, announcementId);
                        _incrementQuestionUnreadCount(questionId);
                        _showNotification(
                          id: replyId.hashCode,
                          title: '💬 Follow-up in $groupName',
                          body:
                              '$replyAuthorName followed up on "$announcementTitle"',
                          payload:
                              'qa_reply:$groupId:$announcementId:$questionId',
                        );
                      }
                    });

                questionReplySubs[replySubKey] = replySub;
                _subscriptions.add(replySub);
              }
            });

            _subscriptions.add(questionSub);
          }
        });
        _subscriptions.add(announcementSub);
      }
    } catch (e) {
      print('[NOTIF] Error setting up Q&A reply listeners: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Join request listener
  // ---------------------------------------------------------------------------

  Future<void> _listenForJoinRequests(String userId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      final adminGroups = <String>[];
      for (var groupDoc in groupsSnapshot.docs) {
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupDoc.id)
            .collection('members')
            .doc(userId)
            .get();
        if (memberDoc.exists) {
          final role = memberDoc.data()?['role'] as String?;
          if (role == 'admin' || role == 'moderator') {
            adminGroups.add(groupDoc.id);
          }
        }
      }

      for (var groupId in adminGroups) {
        final sub = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('joinRequests')
            .where('status', isEqualTo: 'pending')
            .snapshots()
            .listen((snapshot) {
              for (var change in snapshot.docChanges) {
                if (change.type != DocumentChangeType.added) continue;
                if (change.doc.metadata.isFromCache) continue;

                final docId = change.doc.id;
                if (_processedIds.contains(docId)) continue;
                _processedIds.add(docId);

                final data = change.doc.data()!;
                final requestedAt = data['requestedAt'] as Timestamp?;
                if (requestedAt == null) continue;
                if (DateTime.now().difference(requestedAt.toDate()).inSeconds >
                    10)
                  continue;

                _firestore.collection('groups').doc(groupId).get().then((
                  groupDoc,
                ) {
                  final groupName = groupDoc.data()?['name'] ?? 'Group';
                  _incrementUnreadCount('join_requests');
                  _showNotification(
                    id: change.doc.id.hashCode,
                    title: '👋 Join Request',
                    body:
                        '${data['requesterName'] ?? 'Someone'} wants to join $groupName',
                    payload: 'join_request:$groupId',
                  );
                });
              }
            });
        _subscriptions.add(sub);
      }
    } catch (e) {
      print('[NOTIF] Error setting up join request listeners: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Club creation request listener (platform admin)
  // ---------------------------------------------------------------------------

  Future<void> _listenForClubCreationRequests(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.data()?['isPlatformAdmin'] != true) return;

      final sub = _firestore
          .collection('groupCreationRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) continue;
              if (change.doc.metadata.isFromCache) continue;

              final docId = change.doc.id;
              if (_processedIds.contains(docId)) continue;
              _processedIds.add(docId);

              final data = change.doc.data()!;
              final requestedAt = data['requestedAt'] as Timestamp?;
              if (requestedAt == null) continue;
              if (DateTime.now().difference(requestedAt.toDate()).inSeconds >
                  10)
                continue;

              _incrementUnreadCount('club_requests');
              _showNotification(
                id: change.doc.id.hashCode,
                title: '🎯 Group Request',
                body:
                    '${data['requesterName'] ?? 'Someone'} wants to create "${data['groupName'] ?? 'a group'}"',
                payload: 'club_request:${change.doc.id}',
              );
            }
          });
      _subscriptions.add(sub);
    } catch (e) {
      print('[NOTIF] Error setting up club creation listener: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Show notification
  // ---------------------------------------------------------------------------

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Deduplicate by payload within a short window (5 seconds)
    if (payload != null) {
      final now = DateTime.now();
      final lastShown = _lastShownPayloads[payload];
      if (lastShown != null && now.difference(lastShown).inSeconds < 5) {
        print('[NOTIF] Skipping duplicate notification for payload: $payload');
        return;
      }
      _lastShownPayloads[payload] = now;
    }

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'gr0ve_channel',
            'gr0ve Notifications',
            channelDescription: 'Notifications for groups and announcements',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      print('[NOTIF] Error showing notification: $e');
    }
  }

  Future<void> testNotification() async {
    await _showNotification(
      id: 999999,
      title: 'Test Notification',
      body: 'Notifications are working!',
      payload: 'test',
    );
  }

  void dispose() {
    _unreadCountController.close();
  }

  // ---------------------------------------------------------------------------
  // New Question listener
  // Notifies mod/admin when a member asks a question in an announcement.
  // ---------------------------------------------------------------------------

  Future<void> _listenForNewQuestions(String userId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      for (final groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId)
            .get();
        if (!memberDoc.exists) continue;

        final roleStr = memberDoc.data()?['role'] as String? ?? 'member';
        final isStaff = roleStr == 'admin' || roleStr == 'moderator';
        if (!isStaff) continue;

        final groupName = groupDoc.data()['name'] ?? 'Group';
        final announcementsRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('announcements');

        // REACTIVE: Watch announcements stream so new ones get monitored too.
        final announcementSub = announcementsRef.snapshots().listen((
          announcementSnapshot,
        ) {
          for (final announcementChange in announcementSnapshot.docChanges) {
            if (announcementChange.type == DocumentChangeType.removed) continue;

            final announcementDoc = announcementChange.doc;
            final announcementId = announcementDoc.id;
            final announcementTitle =
                (announcementDoc.data() as Map<String, dynamic>)['title']
                    as String? ??
                'Announcement';

            // Watch all questions in this announcement, sorted newest-first.
            final sub = announcementsRef
                .doc(announcementId)
                .collection('questions')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .snapshots()
                .listen((snapshot) {
                  if (snapshot.docs.isEmpty) return;
                  if (snapshot.docs.first.metadata.isFromCache) return;

                  final doc = snapshot.docs.first;
                  if (_processedIds.contains(doc.id)) return;
                  _processedIds.add(doc.id);

                  final data = doc.data();
                  final authorId = data['authorId'] as String?;
                  final createdAt = data['createdAt'] as Timestamp?;

                  // Skip own questions
                  if (authorId == userId) return;
                  // Skip stale questions (older than 10 seconds)
                  if (createdAt == null) return;
                  if (DateTime.now().difference(createdAt.toDate()).inSeconds >
                      10)
                    return;

                  _incrementUnreadCount('unread_questions');
                  _incrementClubQACount(groupId);
                  _incrementAnnouncementQACount(groupId, announcementId);
                  _showNotification(
                    id: doc.id.hashCode,
                    title: '❓ Question in $groupName',
                    body:
                        'New question on "$announcementTitle": ${data['content'] ?? ""}',
                    payload: 'qa_question:$groupId:$announcementId:${doc.id}',
                  );
                });
            _subscriptions.add(sub);
          }
        });
        _subscriptions.add(announcementSub);
      }
    } catch (e) {
      print('[NOTIF] Error setting up new question listeners: $e');
    }
  }
}
