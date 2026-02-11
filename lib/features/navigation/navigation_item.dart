import 'package:flutter/material.dart';

// MODEL: Represents a navigation item in the drawer
class NavigationItem {
  final IconData icon;
  final String label;
  final bool isAdminOnly;
  final String? unreadCountKey;
  final bool showClubNotifications;

  NavigationItem({
    required this.icon,
    required this.label,
    this.isAdminOnly = false,
    this.unreadCountKey,
    this.showClubNotifications = false,
  });
}
