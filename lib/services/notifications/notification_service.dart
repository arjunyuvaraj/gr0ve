import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/services/bus_service.dart';
import 'package:gr0ve/services/starred_bus_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

// Top-level function to handle background messages
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
  final Set<String> _processedIds = {}; // Prevent duplicate notifications

  // Track which buses have already triggered notifications with dates
  final Map<String, DateTime> _notifiedBuses = {};
  Timer? _busCheckTimer;

  // Callback for notification taps
  void Function(NotificationResponse)? _onNotificationTapCallback;

  static const String _notifiedBusesKey = 'notified_buses';

  // Track unread announcements per club (groupId -> count)
  final Map<String, int> _unreadAnnouncementsByClub = {};

  // Track unread counts by type
  final Map<String, int> _unreadCounts = {
    'join_requests': 0,
    'club_requests': 0,
  };

  // Stream controller for unread count updates
  final _unreadCountController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get unreadCountStream =>
      _unreadCountController.stream;

  Map<String, int> get unreadCounts => Map.from(_unreadCounts);
  Map<String, int> get unreadAnnouncementsByClub =>
      Map.from(_unreadAnnouncementsByClub);

  /// Set the callback for when notifications are tapped
  void setNotificationTapCallback(
    void Function(NotificationResponse) callback,
  ) {
    _onNotificationTapCallback = callback;
    print('[NOTIF] Notification tap callback registered');
  }

  /// Initialize the notification service
  Future<void> initialize() async {
    print('[NOTIF] Initializing notification service...');

    // Load previously notified buses from storage
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

  /// Load unread counts from storage
  Future<void> _loadUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _unreadCounts['join_requests'] =
          prefs.getInt('unread_join_requests') ?? 0;
      _unreadCounts['club_requests'] =
          prefs.getInt('unread_club_requests') ?? 0;

      // Load per-club announcement counts
      final clubAnnouncementsJson = prefs.getString(
        'unread_announcements_by_club',
      );
      if (clubAnnouncementsJson != null) {
        final Map<String, dynamic> decoded = json.decode(clubAnnouncementsJson);
        decoded.forEach((key, value) {
          _unreadAnnouncementsByClub[key] = value as int;
        });
      }

      _notifyUnreadCountUpdate();
      print('[NOTIF] Loaded unread counts: $_unreadCounts');
      print('[NOTIF] Loaded club announcements: $_unreadAnnouncementsByClub');
    } catch (e) {
      print('[NOTIF] Error loading unread counts: $e');
    }
  }

  /// Save unread counts to storage
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

      // Save per-club announcement counts
      await prefs.setString(
        'unread_announcements_by_club',
        json.encode(_unreadAnnouncementsByClub),
      );

      _notifyUnreadCountUpdate();
    } catch (e) {
      print('[NOTIF] Error saving unread counts: $e');
    }
  }

  /// Notify listeners of unread count changes
  void _notifyUnreadCountUpdate() {
    if (!_unreadCountController.isClosed) {
      _unreadCountController.add({
        'counts': Map.from(_unreadCounts),
        'announcementsByClub': Map.from(_unreadAnnouncementsByClub),
      });
    }
  }

  /// Increment unread count for a type
  void _incrementUnreadCount(String type) {
    _unreadCounts[type] = (_unreadCounts[type] ?? 0) + 1;
    _saveUnreadCounts();
  }

  /// Increment unread announcement count for a specific club
  void _incrementClubAnnouncementCount(String groupId) {
    _unreadAnnouncementsByClub[groupId] =
        (_unreadAnnouncementsByClub[groupId] ?? 0) + 1;
    _saveUnreadCounts();
    print(
      '[NOTIF] Incremented announcement count for $groupId: ${_unreadAnnouncementsByClub[groupId]}',
    );
  }

  /// Clear unread count for a type
  Future<void> clearUnreadCount(String type) async {
    _unreadCounts[type] = 0;
    await _saveUnreadCounts();
  }

  /// Clear unread announcements for a specific club
  Future<void> clearClubAnnouncementCount(String groupId) async {
    _unreadAnnouncementsByClub[groupId] = 0;
    await _saveUnreadCounts();
    print('[NOTIF] Cleared announcement count for $groupId');
  }

  /// Clear all announcement counts (when user views "My Clubs" tab)
  Future<void> clearAllAnnouncementCounts() async {
    _unreadAnnouncementsByClub.clear();
    await _saveUnreadCounts();
    print('[NOTIF] Cleared all announcement counts');
  }

  /// Get unread count for a specific club
  int getClubUnreadCount(String groupId) {
    return _unreadAnnouncementsByClub[groupId] ?? 0;
  }

  /// Load notified buses from persistent storage
  Future<void> _loadNotifiedBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedData = prefs.getString(_notifiedBusesKey);

      if (storedData != null) {
        final Map<String, dynamic> decoded = json.decode(storedData);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Only load notifications from today
        decoded.forEach((town, timestampString) {
          final notifiedDate = DateTime.parse(timestampString);
          if (!notifiedDate.isBefore(today)) {
            _notifiedBuses[town] = notifiedDate;
          }
        });

        print(
          '[NOTIF] Loaded ${_notifiedBuses.length} bus notifications from storage',
        );
      }
    } catch (e) {
      print('[NOTIF] Error loading notified buses: $e');
    }
  }

  /// Save notified buses to persistent storage
  Future<void> _saveNotifiedBuses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, String> toStore = {};

      _notifiedBuses.forEach((town, dateTime) {
        toStore[town] = dateTime.toIso8601String();
      });

      await prefs.setString(_notifiedBusesKey, json.encode(toStore));
    } catch (e) {
      print('[NOTIF] Error saving notified buses: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    print('[NOTIF] Initializing FCM...');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('[NOTIF] FCM Token obtained: ${token.substring(0, 20)}...');
        await _saveFCMToken(token);
      } else {
        print('[NOTIF] FCM Token is null, waiting for refresh...');
      }
    } catch (e) {
      print('[NOTIF] Error getting FCM token: $e');
    }

    _messaging.onTokenRefresh.listen((token) {
      print('[NOTIF] FCM Token refreshed: ${token.substring(0, 20)}...');
      _saveFCMToken(token);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    print('[NOTIF] FCM initialized');
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[NOTIF] Cannot save FCM token - no user logged in');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('[NOTIF] FCM token saved to Firestore for user: ${user.uid}');
    } catch (e) {
      print('[NOTIF] Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print(
      '[NOTIF] Foreground message received: ${message.notification?.title}',
    );

    if (message.notification != null) {
      _showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data['payload'],
      );
    }
  }

  /// Handle message when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('[NOTIF] App opened from notification: ${message.data}');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    print('[NOTIF] Requesting permissions...');

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('[NOTIF] Permission status: ${settings.authorizationStatus}');

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

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[NOTIF] Notification tapped: ${response.payload}');

    // Call the registered callback if it exists
    if (_onNotificationTapCallback != null) {
      _onNotificationTapCallback!(response);
    } else {
      print('[NOTIF] No tap callback registered');
    }
  }

  /// Start listening for notifications
  Future<void> startListening() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[NOTIF] Cannot start listening - no user logged in');
      return;
    }

    print('[NOTIF] Starting listeners for user: ${user.uid}');

    await stopListening();
    _processedIds.clear();
    // DON'T clear _notifiedBuses - it's loaded from persistent storage

    await _listenForAnnouncements(user.uid);
    await _listenForJoinRequests(user.uid);
    await _listenForClubCreationRequests(user.uid);
    _startBusArrivalMonitoring();

    print(
      '[NOTIF] All listeners started. Active subscriptions: ${_subscriptions.length}',
    );
  }

  /// Stop all listeners
  Future<void> stopListening() async {
    print('[NOTIF] Stopping all listeners...');

    for (var sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    _busCheckTimer?.cancel();
    _busCheckTimer = null;

    print('[NOTIF] All listeners stopped');
  }

  /// Start monitoring for starred bus arrivals
  void _startBusArrivalMonitoring() {
    print('[NOTIF] Starting bus arrival monitoring...');

    // Check every 30 seconds for bus arrivals
    _busCheckTimer?.cancel();
    _busCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkStarredBusArrivals();
    });

    // Do an immediate check
    _checkStarredBusArrivals();
  }

  /// Check if any starred buses have arrived
  Future<void> _checkStarredBusArrivals() async {
    try {
      final starredTowns = StarredBusService.starredTowns.value;
      if (starredTowns.isEmpty) {
        print('[NOTIF] No starred buses to monitor');
        return;
      }

      print('[NOTIF] Checking ${starredTowns.length} starred buses...');
      final routes = await fetchBusRoutes();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final route in routes) {
        // Check if this bus is starred and has arrived
        if (starredTowns.contains(route.town) && route.status == 'Arrived') {
          final lastNotified = _notifiedBuses[route.town];

          // Only notify if we haven't notified today
          if (lastNotified == null || lastNotified.isBefore(today)) {
            // Mark as notified with today's date
            _notifiedBuses[route.town] = now;
            await _saveNotifiedBuses();

            // Send notification
            await _showNotification(
              id: route.town.hashCode,
              title: '🚌 ${route.town}',
              body: 'Parking spot: ${route.code}',
              payload: 'bus:${route.town}',
            );

            print('[NOTIF] Bus arrival notification sent for ${route.town}');
          } else {
            print('[NOTIF] Already notified about ${route.town} today');
          }
        }
      }
    } catch (e) {
      print('[NOTIF] Error checking starred bus arrivals: $e');
    }
  }

  /// Listen for new announcements
  Future<void> _listenForAnnouncements(String userId) async {
    print('[NOTIF] Setting up announcement listeners for user: $userId');

    try {
      // Get all active groups first
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      print(
        '[NOTIF] Found ${groupsSnapshot.docs.length} active groups, checking membership...',
      );

      // Check which groups the user is a member of
      final memberGroups = <String>[];
      for (var groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          memberGroups.add(groupId);
        }
      }

      print('[NOTIF] User is member of ${memberGroups.length} groups');

      for (var groupId in memberGroups) {
        print('[NOTIF] Setting up announcement listener for group: $groupId');

        final sub = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('announcements')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .snapshots()
            .listen((snapshot) {
              print(
                '[NOTIF] Announcement snapshot for group $groupId - docs: ${snapshot.docs.length}',
              );

              if (snapshot.docs.isEmpty) {
                print('[NOTIF] No announcements in group $groupId');
                return;
              }

              if (snapshot.docs.first.metadata.isFromCache) {
                print('[NOTIF] Announcement is from cache, skipping');
                return;
              }

              final doc = snapshot.docs.first;
              final docId = doc.id;

              if (_processedIds.contains(docId)) {
                print(
                  '[NOTIF] Announcement $docId already processed, skipping',
                );
                return;
              }

              _processedIds.add(docId);

              final data = doc.data();
              final authorId = data['authorId'] as String?;
              final createdAt = data['createdAt'] as Timestamp?;

              print(
                '[NOTIF] New announcement: $docId, author: $authorId, createdAt: $createdAt',
              );

              if (authorId == userId) {
                print('[NOTIF] Skipping own announcement');
                return;
              }

              if (createdAt == null) {
                print('[NOTIF] Announcement has no createdAt timestamp');
                return;
              }

              final age = DateTime.now()
                  .difference(createdAt.toDate())
                  .inSeconds;
              print('[NOTIF] Announcement age: $age seconds');

              if (age > 10) {
                print('[NOTIF] Announcement too old, skipping');
                return;
              }

              print('[NOTIF] Fetching group name for notification...');

              _firestore.collection('groups').doc(groupId).get().then((
                groupDoc,
              ) {
                final groupName = groupDoc.data()?['name'] ?? 'Group';
                print(
                  '[NOTIF] Showing announcement notification for group: $groupName',
                );

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

  /// Listen for join requests
  Future<void> _listenForJoinRequests(String userId) async {
    print('[NOTIF] Setting up join request listeners for user: $userId');

    try {
      // Get all active groups
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('status', isEqualTo: 'active')
          .get();

      print(
        '[NOTIF] Found ${groupsSnapshot.docs.length} active groups, checking admin/mod status...',
      );

      // Check which groups the user is admin/moderator of
      final adminGroups = <String>[];
      for (var groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        final memberDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          final role = memberDoc.data()?['role'] as String?;
          if (role == 'admin' || role == 'moderator') {
            adminGroups.add(groupId);
          }
        }
      }

      print('[NOTIF] User is admin/mod of ${adminGroups.length} groups');

      for (var groupId in adminGroups) {
        print('[NOTIF] Setting up join request listener for group: $groupId');

        final sub = _firestore
            .collection('groups')
            .doc(groupId)
            .collection('joinRequests')
            .where('status', isEqualTo: 'pending')
            .snapshots()
            .listen((snapshot) {
              print(
                '[NOTIF] Join request snapshot for group $groupId - changes: ${snapshot.docChanges.length}',
              );

              for (var change in snapshot.docChanges) {
                if (change.type != DocumentChangeType.added) {
                  print('[NOTIF] Join request change is not added, skipping');
                  continue;
                }

                if (change.doc.metadata.isFromCache) {
                  print('[NOTIF] Join request is from cache, skipping');
                  continue;
                }

                final docId = change.doc.id;
                if (_processedIds.contains(docId)) {
                  print(
                    '[NOTIF] Join request $docId already processed, skipping',
                  );
                  continue;
                }

                _processedIds.add(docId);

                final data = change.doc.data()!;
                final requestedAt = data['requestedAt'] as Timestamp?;

                print(
                  '[NOTIF] New join request: $docId, requestedAt: $requestedAt',
                );

                if (requestedAt == null) {
                  print('[NOTIF] Join request has no requestedAt timestamp');
                  continue;
                }

                final age = DateTime.now()
                    .difference(requestedAt.toDate())
                    .inSeconds;
                print('[NOTIF] Join request age: $age seconds');

                if (age > 10) {
                  print('[NOTIF] Join request too old, skipping');
                  continue;
                }

                print(
                  '[NOTIF] Fetching group name for join request notification...',
                );

                _firestore.collection('groups').doc(groupId).get().then((
                  groupDoc,
                ) {
                  final groupName = groupDoc.data()?['name'] ?? 'Group';
                  print(
                    '[NOTIF] Showing join request notification for group: $groupName',
                  );

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

  /// Listen for club creation requests
  Future<void> _listenForClubCreationRequests(String userId) async {
    print('[NOTIF] Checking if user is platform admin...');

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.data()?['isPlatformAdmin'] != true) {
        print(
          '[NOTIF] User is not platform admin, skipping club creation listener',
        );
        return;
      }

      print('[NOTIF] Setting up club creation request listener');

      final sub = _firestore
          .collection('groupCreationRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
            print(
              '[NOTIF] Club creation request snapshot - changes: ${snapshot.docChanges.length}',
            );

            for (var change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) {
                print('[NOTIF] Club creation change is not added, skipping');
                continue;
              }

              if (change.doc.metadata.isFromCache) {
                print('[NOTIF] Club creation request is from cache, skipping');
                continue;
              }

              final docId = change.doc.id;
              if (_processedIds.contains(docId)) {
                print(
                  '[NOTIF] Club creation request $docId already processed, skipping',
                );
                continue;
              }

              _processedIds.add(docId);

              final data = change.doc.data()!;
              final requestedAt = data['requestedAt'] as Timestamp?;

              print(
                '[NOTIF] New club creation request: $docId, requestedAt: $requestedAt',
              );

              if (requestedAt == null) {
                print(
                  '[NOTIF] Club creation request has no requestedAt timestamp',
                );
                continue;
              }

              final age = DateTime.now()
                  .difference(requestedAt.toDate())
                  .inSeconds;
              print('[NOTIF] Club creation request age: $age seconds');

              if (age > 10) {
                print('[NOTIF] Club creation request too old, skipping');
                continue;
              }

              print('[NOTIF] Showing club creation request notification');

              _incrementUnreadCount('club_requests');
              _showNotification(
                id: change.doc.id.hashCode,
                title: '🎯 Club Request',
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

  /// Show a local notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('[NOTIF] Showing notification - ID: $id, Title: $title');

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'gr0ve_channel',
            'gr0ve Notifications',
            channelDescription: 'Notifications for clubs and announcements',
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
      print('[NOTIF] Notification shown successfully');
    } catch (e) {
      print('[NOTIF] Error showing notification: $e');
    }
  }

  /// Test notification
  Future<void> testNotification() async {
    print('[NOTIF] Triggering test notification');

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
}
