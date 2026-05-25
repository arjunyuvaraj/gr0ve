import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gr0ve/features/navigation/screens/navigation_screen.dart';
import 'package:flutter/material.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || _navigatorKey == null) return;

    print('[NOTIF_HANDLER] Handling payload: $payload');

    if (payload.startsWith('bus:')) {
      _navigateToBusScreen();
    } else if (payload.startsWith('announcement:')) {
      final groupId = payload.substring('announcement:'.length);
      _navigateToGroup(groupId);
    } else if (payload.startsWith('join_request:')) {
      final groupId = payload.substring('join_request:'.length);
      _navigateToJoinRequests(groupId);
    } else if (payload.startsWith('club_request:')) {
      _navigateToAdminPanel();
    } else if (payload.startsWith('qa_reply:')) {
      final parts = payload.substring('qa_reply:'.length).split(':');
      if (parts.isNotEmpty) {
        _navigateToGroup(parts[0]);
      }
    }
  }

  void _navigateToBusScreen() {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
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
