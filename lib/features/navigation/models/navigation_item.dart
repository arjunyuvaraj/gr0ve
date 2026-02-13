import 'package:flutter/material.dart';

// MODEL: Legacy navigation item model (kept for backward compatibility)
// NOTE: The main NavigationScreen now uses NavConfig internally
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
