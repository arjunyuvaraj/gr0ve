import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gr0ve/features/navigation/screens/navigation_screen.dart';
import 'package:flutter/material.dart';

/// Handle notification taps and navigate to appropriate screens
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Set the navigator key for navigation
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Handle notification tap
  void handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || _navigatorKey == null) return;

    print('[NOTIF_HANDLER] Handling payload: $payload');

    // Parse payload
    if (payload.startsWith('bus:')) {
      // Bus notification - navigate to bus screen
      _navigateToBusScreen();
    } else if (payload.startsWith('announcement:')) {
      // Announcement notification - navigate to group
      final groupId = payload.substring('announcement:'.length);
      _navigateToGroup(groupId);
    } else if (payload.startsWith('join_request:')) {
      // Join request - navigate to join requests screen
      final groupId = payload.substring('join_request:'.length);
      _navigateToJoinRequests(groupId);
    } else if (payload.startsWith('club_request:')) {
      // Club creation request - navigate to admin panel
      _navigateToAdminPanel();
    }
  }

  void _navigateToBusScreen() {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    // Navigate to NavigationScreen with the bus tab selected (index 2)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const NavigationScreen(initialIndex: 2),
      ),
      (route) => false,
    );
  }

  void _navigateToGroup(String groupId) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    // Navigate to the group screen
    // You'll need to implement this based on your routing setup
    Navigator.of(context).pushNamed('/group', arguments: groupId);
  }

  void _navigateToJoinRequests(String groupId) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    Navigator.of(context).pushNamed('/club/join-requests', arguments: groupId);
  }

  void _navigateToAdminPanel() {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    Navigator.of(context).pushNamed('/admin');
  }
}
