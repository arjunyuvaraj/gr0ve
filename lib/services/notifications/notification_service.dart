import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode)
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
  final Map<String, DateTime> _lastShownPayloads = {};
  static bool realtimeUnreadListenersEnabled = false;

  void Function(NotificationResponse)? _onNotificationTapCallback;

  final Map<String, int> _unreadAnnouncementsByClub = {};
  final Map<String, int> _unreadQAByClub = {};
  final Map<String, int> _unreadQAByAnnouncement = {};
  final Map<String, int> _unreadQuestionsById = {};
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
    if (kDebugMode) print('[NOTIF] Notification tap callback registered');
  }

  Future<void> initialize() async {
    if (kDebugMode) print('[NOTIF] Initializing notification service...');

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

    if (kDebugMode) print('[NOTIF] Notification service initialized');
  }

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
      if (kDebugMode) print('[NOTIF] Loaded unread counts: $_unreadCounts');
    } catch (e) {
      if (kDebugMode) print('[NOTIF] Error loading unread counts: $e');
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
      if (kDebugMode) print('[NOTIF] Error saving unread counts: $e');
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

  Future<void> _initializeFCM() async {
    if (kDebugMode) print('[NOTIF] Initializing FCM...');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode)
          print('[NOTIF] FCM Token: ${token.substring(0, 20)}...');
        await _saveFCMToken(token);
      }
    } catch (e) {
      if (kDebugMode) print('[NOTIF] Error getting FCM token: $e');
    }
    _messaging.onTokenRefresh.listen(_saveFCMToken);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    if (kDebugMode) print('[NOTIF] FCM initialized');
  }

  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('[NOTIF] Error saving FCM token: $e');
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
    if (kDebugMode)
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
    if (kDebugMode) print('[NOTIF] Notification tapped: ${response.payload}');
    _onNotificationTapCallback?.call(response);
  }

  Future<void> startListening() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (kDebugMode) print('[NOTIF] Starting listeners for user: ${user.uid}');

    await stopListening();
    _processedIds.clear();

    if (!realtimeUnreadListenersEnabled) {
      if (kDebugMode) print('[NOTIF] Realtime unread listeners disabled');
      return;
    }

    final memberGroups = <String>[];
    final staffGroups = <String, String>{};
    QuerySnapshot? groupsSnapshot;

    try {
      groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get()
          .timeout(const Duration(seconds: 8));

      final membershipFutures = groupsSnapshot.docs.map((groupDoc) async {
        try {
          final memberDoc = await _firestore
              .collection('groups')
              .doc(groupDoc.id)
              .collection('members')
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 5));
          if (memberDoc.exists) {
            memberGroups.add(groupDoc.id);
            final role = memberDoc['role'] as String? ?? 'member';
            if (role == 'admin' || role == 'moderator') {
              staffGroups[groupDoc.id] = groupDoc['name'] as String? ?? 'Group';
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '[NOTIF] Error checking membership for group ${groupDoc.id}: $e',
            );
          }
        }
      });
      await Future.wait(membershipFutures);

      if (kDebugMode) {
        print(
          '[NOTIF] Resolved membership: ${memberGroups.length} groups, ${staffGroups.length} staff',
        );
      }
    } catch (e) {
      if (kDebugMode)
        print('[NOTIF] Critical error fetching groups collection: $e');

      return;
    }

    _listenForAnnouncementsResolved(user.uid, memberGroups);
    _listenForJoinRequestsResolved(user.uid, staffGroups);
    _listenForClubCreationRequestsResolved(user.uid);
    _listenForQARepliesResolved(
      user.uid,
      groupsSnapshot,
      memberGroups,
      staffGroups,
    );
    _listenForNewQuestionsResolved(user.uid, staffGroups);

    if (kDebugMode) print('[NOTIF] All listeners started');
  }

  Future<void> stopListening() async {
    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
  }

  void _listenForAnnouncementsResolved(
    String userId,
    List<String> memberGroups,
  ) {
    try {
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
              if (createdAt == null) return;
              if (DateTime.now().difference(createdAt.toDate()).inSeconds > 10)
                return;

              _firestore.collection('groups').doc(groupId).get().then((
                groupDoc,
              ) {
                final groupName = groupDoc['name'] ?? 'Group';
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
      if (kDebugMode)
        print('[NOTIF] Error setting up announcement listeners: $e');
    }
  }

  void _listenForQARepliesResolved(
    String userId,
    QuerySnapshot groupsSnapshot,
    List<String> memberGroups,
    Map<String, String> staffGroups,
  ) {
    try {
      for (final groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        if (!memberGroups.contains(groupId)) continue;

        final isStaff = staffGroups.containsKey(groupId);
        final groupName =
            (groupDoc.data() as Map<String, dynamic>)['name'] ?? 'Group';

        final Map<String, StreamSubscription> questionReplySubs = {};

        final announcementsRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('announcements');

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

            Query questionsQuery = announcementsRef
                .doc(announcementId)
                .collection('questions');

            if (!isStaff) {
              questionsQuery = questionsQuery.where(
                'authorId',
                isEqualTo: userId,
              );
            }

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
                      } else if (isStaff && !isStaffReply) {
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
      if (kDebugMode) print('[NOTIF] Error setting up Q&A reply listeners: $e');
    }
  }

  void _listenForJoinRequestsResolved(
    String userId,
    Map<String, String> staffGroups,
  ) {
    try {
      for (var entry in staffGroups.entries) {
        final groupId = entry.key;
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
                  final groupName = groupDoc['name'] ?? 'Group';
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
      if (kDebugMode)
        print('[NOTIF] Error setting up join request listeners: $e');
    }
  }

  void _listenForClubCreationRequestsResolved(String userId) {
    try {
      final data = UserDocCache.getCached();
      if (data?['isPlatformAdmin'] != true) return;

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
      if (kDebugMode)
        print('[NOTIF] Error setting up club creation listener: $e');
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (payload != null) {
      final now = DateTime.now();
      if (_lastShownPayloads.containsKey(payload)) {
        if (kDebugMode)
          print(
            '[NOTIF] Skipping duplicate notification for payload: $payload',
          );
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
      if (kDebugMode) print('[NOTIF] Error showing notification: $e');
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

  void _listenForNewQuestionsResolved(
    String userId,
    Map<String, String> staffGroups,
  ) {
    try {
      for (final entry in staffGroups.entries) {
        final groupId = entry.key;
        final groupName = entry.value;

        final announcementsRef = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('announcements');

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

                  if (authorId == userId) return;

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
      if (kDebugMode)
        print('[NOTIF] Error setting up new question listeners: $e');
    }
  }
}
