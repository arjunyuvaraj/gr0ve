import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

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

  /// Initialize the notification service
  Future<void> initialize() async {
    print('[NOTIF] Initializing notification service...');

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

    await _listenForAnnouncements(user.uid);
    await _listenForJoinRequests(user.uid);
    await _listenForClubCreationRequests(user.uid);

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

    print('[NOTIF] All listeners stopped');
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
}
