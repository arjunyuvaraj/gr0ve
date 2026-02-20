import 'package:flutter/material.dart';

enum UserRole { guest, parent, student }

class NavConfig {
  final String id;
  final dynamic iconData;
  final String label;
  final Widget screen;
  final bool isAdminOnly;
  final String? notificationKey;
  final bool showClubNotifications;

  NavConfig({
    required this.id,
    required this.iconData,
    required this.label,
    required this.screen,
    this.isAdminOnly = false,
    this.notificationKey,
    this.showClubNotifications = false,
  });

  NavConfig copyWith({
    String? id,
    dynamic iconData,
    String? label,
    Widget? screen,
    bool? isAdminOnly,
    String? notificationKey,
    bool? showClubNotifications,
  }) {
    return NavConfig(
      id: id ?? this.id,
      iconData: iconData ?? this.iconData,
      label: label ?? this.label,
      screen: screen ?? this.screen,
      isAdminOnly: isAdminOnly ?? this.isAdminOnly,
      notificationKey: notificationKey ?? this.notificationKey,
      showClubNotifications:
          showClubNotifications ?? this.showClubNotifications,
    );
  }
}
