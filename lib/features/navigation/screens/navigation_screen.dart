import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

// Import your screens
import 'package:gr0ve/features/account/screens/account_screen.dart';
import 'package:gr0ve/features/admin/screens/admin_panel_screen.dart';
import 'package:gr0ve/features/admin/screens/admin_calendar_requests_screen.dart';
import 'package:gr0ve/features/bus/screens/bus_screen.dart';
import 'package:gr0ve/features/calendar/screens/calendar_screen.dart';
import 'package:gr0ve/features/club/screens/club_screen.dart';
import 'package:gr0ve/features/absence/screens/absence_screen.dart';
import 'package:gr0ve/features/home/screens/home_screen.dart';
import 'package:gr0ve/features/lunch_menu/screens/lunch_menu_screen.dart';
import 'package:gr0ve/features/map/screens/map_screen.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// SCREEN: Main navigation hub with role-based access control
class NavigationScreen extends StatefulWidget {
  final int initialIndex;

  const NavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late int _selectedIndex;
  User? _user;
  UserRole _userRole = UserRole.guest;
  bool _isPlatformAdmin = false;

  List<NavConfig> _navConfigs = [];
  List<Widget> _screens = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _versionCode = '0.0.0';
  StreamSubscription? _unreadCountSubscription;
  Map<String, int> _unreadCounts = {};
  Map<String, int> _unreadAnnouncementsByClub = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _user = FirebaseAuth.instance.currentUser;
    _determineUserRole();
    _checkAdminStatus();
    _loadVersionInfo();
    _setupNotificationHandler();
    _subscribeToUnreadCounts();
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    super.dispose();
  }

  // ============================================================================
  // USER ROLE & ACCESS CONTROL
  // ============================================================================

  void _determineUserRole() {
    final email = _user?.email ?? '';

    if (_user == null) {
      _userRole = UserRole.guest;
    } else if (email.endsWith('@bergen.org') ||
        email == "gr0ve.bca.manager@gmail.com") {
      _userRole = UserRole.student;
    } else {
      _userRole = UserRole.parent;
    }

    _buildNavigation();
  }

  Future<void> _checkAdminStatus() async {
    if (_user == null) return;

    try {
      final email = _user!.email ?? '';
      final isManagerEmail = email == "gr0ve.bca.manager@gmail.com";

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(_user!.uid)
          .get();

      if (mounted) {
        setState(() {
          _isPlatformAdmin = adminDoc.exists || isManagerEmail;
          _buildNavigation();
        });
      }
    } catch (e) {
      print('[NAV] Error checking admin status: $e');
    }
  }

  // ============================================================================
  // NAVIGATION CONFIGURATION
  // ============================================================================

  void _buildNavigation() {
    _navConfigs = _getNavigationForRole(_userRole, _isPlatformAdmin);
    _screens = _navConfigs.map((config) => config.screen).toList();
  }

  /// Central configuration for all navigation items by role
  List<NavConfig> _getNavigationForRole(UserRole role, bool isAdmin) {
    switch (role) {
      case UserRole.guest:
        return [
          NavConfig(
            iconData: HugeIcons.strokeRoundedBus02,
            label: 'Bus',
            screen: const BusScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedHelpCircle,
            label: 'Help',
            screen: const Center(child: Text('Help Screen')),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedUser,
            label: 'Account',
            screen: const AccountScreen(),
          ),
        ];

      case UserRole.student:
        final baseNav = [
          NavConfig(
            iconData: HugeIcons.strokeRoundedHome01,
            label: 'Home',
            screen: const HomeScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedUserRemove02,
            label: 'Absence',
            screen: const AbsenceScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedBus02,
            label: 'Bus',
            screen: const BusScreen(),
            notificationKey: 'bus',
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedRestaurant02,
            label: 'Lunch Menu',
            screen: const LunchMenuScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedCalendar03,
            label: 'Calendar',
            screen: const CalendarScreen(),
          ),
        ];

        // Add admin-only screens
        if (isAdmin) {
          baseNav.addAll([
            NavConfig(
              iconData: HugeIcons.strokeRoundedTaskDaily02,
              label: 'Event Requests',
              screen: const AdminCalendarRequestsScreen(),
              isAdminOnly: true,
            ),
            NavConfig(
              iconData: HugeIcons.strokeRoundedUserQuestion01,
              label: 'Club Requests',
              screen: const AdminPanelScreen(),
              isAdminOnly: true,
              notificationKey: 'club_requests',
            ),
          ]);
        }

        // Add remaining screens
        baseNav.addAll([
          NavConfig(
            iconData: HugeIcons.strokeRoundedUserGroup,
            label: 'Clubs',
            screen: const ClubScreen(),
            showClubNotifications: true,
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedMaps,
            label: 'Maps',
            screen: const MapScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedHelpCircle,
            label: 'Help',
            screen: const Center(child: Text('Help Screen')),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedUser,
            label: 'Account',
            screen: const AccountScreen(),
          ),
        ]);

        return baseNav;

      case UserRole.parent:
        return [
          NavConfig(
            iconData: HugeIcons.strokeRoundedHome01,
            label: 'Home',
            screen: const HomeScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedBus02,
            label: 'Bus',
            screen: const BusScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedRestaurant02,
            label: 'Lunch Menu',
            screen: const LunchMenuScreen(),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedHelpCircle,
            label: 'Help',
            screen: const Center(child: Text('Help Screen')),
          ),
          NavConfig(
            iconData: HugeIcons.strokeRoundedUser,
            label: 'Account',
            screen: const AccountScreen(),
          ),
        ];
    }
  }

  // ============================================================================
  // NOTIFICATION HANDLING
  // ============================================================================

  void _subscribeToUnreadCounts() {
    _unreadCountSubscription = NotificationService().unreadCountStream.listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          final countsMap = data['counts'] as Map<dynamic, dynamic>?;
          final announcementsMap =
              data['announcementsByClub'] as Map<dynamic, dynamic>?;

          _unreadCounts =
              countsMap?.map(
                (key, value) => MapEntry(key.toString(), value as int),
              ) ??
              {};
          _unreadAnnouncementsByClub =
              announcementsMap?.map(
                (key, value) => MapEntry(key.toString(), value as int),
              ) ??
              {};
        });
      }
    });

    setState(() {
      _unreadCounts = NotificationService().unreadCounts;
      _unreadAnnouncementsByClub =
          NotificationService().unreadAnnouncementsByClub;
    });
  }

  void _setupNotificationHandler() {
    print('[NAV] Setting up notification handler');

    NotificationService().setNotificationTapCallback((
      NotificationResponse response,
    ) {
      final payload = response.payload;
      print('[NAV] Notification tapped with payload: $payload');

      if (!_isVersionAbove150() || payload == null) return;

      if (payload.startsWith('announcement:')) {
        _navigateToScreenByType(ClubScreen);
      } else if (payload.startsWith('join_request:') ||
          payload.startsWith('club_request:')) {
        _navigateToScreenByType(AdminPanelScreen);
        NotificationService().clearUnreadCount('join_requests');
        NotificationService().clearUnreadCount('club_requests');
      } else if (payload.startsWith('bus:')) {
        _navigateToScreenByType(BusScreen);
      }
    });
  }

  void _navigateToScreenByType(Type screenType) {
    final index = _screens.indexWhere(
      (screen) => screen.runtimeType == screenType,
    );
    if (index != -1 && mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  // ============================================================================
  // VERSION MANAGEMENT
  // ============================================================================

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _versionCode = packageInfo.version);
      }
      print('[NAV] App version: $_versionCode');
    } catch (e) {
      print('[NAV] Error loading version info: $e');
    }
  }

  bool _isVersionAbove150() {
    try {
      final parts = _versionCode.split('.');
      if (parts.length < 2) return false;

      final major = int.tryParse(parts[0]) ?? 0;
      final minor = int.tryParse(parts[1]) ?? 0;

      return major > 1 || (major == 1 && minor >= 5);
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // NAVIGATION LOGIC
  // ============================================================================

  void _changeIndex(int index) {
    if (index == -1 || index >= _navConfigs.length) return;

    final config = _navConfigs[index];

    // Clear notifications
    if (config.notificationKey != null) {
      NotificationService().clearUnreadCount(config.notificationKey!);
    }
    if (config.showClubNotifications) {
      NotificationService().clearAllAnnouncementCounts();
    }

    setState(() => _selectedIndex = index);
  }

  int _getTotalUnreadCount(NavConfig config) {
    if (config.showClubNotifications) {
      return _unreadAnnouncementsByClub.values.fold(
        0,
        (sum, count) => sum + count,
      );
    } else if (config.notificationKey != null) {
      return _unreadCounts[config.notificationKey] ?? 0;
    }
    return 0;
  }

  // ============================================================================
  // UI - MORE MENU
  // ============================================================================

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMoreMenu(),
    );
  }

  Widget _buildMoreMenu() {
    final colors = Theme.of(context).colorScheme;
    final moreItems = _navConfigs.length > 5 ? _navConfigs.sublist(4) : [];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'More Options',
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: moreItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final actualIndex = index + 4;
                final config = moreItems[index];
                final isSelected = _selectedIndex == actualIndex;
                final unreadCount = _getTotalUnreadCount(config);

                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _changeIndex(actualIndex);
                  },
                  leading: AnimatedScale(
                    scale: isSelected ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: HugeIcon(
                      icon: config.iconData,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurface.withOpacity(0.4),
                    ),
                  ),
                  title: Text(
                    config.label,
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (isSelected) ...[
                        if (unreadCount > 0) const SizedBox(width: 8),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                          color: colors.primary,
                          size: 20.0,
                        ),
                      ],
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: isSelected
                      ? colors.primary.withOpacity(0.05)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================================
  // UI - MAIN BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final int displayCount = _navConfigs.length > 5 ? 4 : _navConfigs.length;
    final List<Widget> navItems = [];

    for (int i = 0; i < displayCount; i++) {
      final config = _navConfigs[i];
      final isSelected = _selectedIndex == i;
      navItems.add(_buildNavItem(i, config, isSelected));
    }

    if (_navConfigs.length > 5) {
      final anyMoreSelected = _selectedIndex >= 4;
      navItems.add(_buildMoreNavItem(anyMoreSelected));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: colors.surface,
        systemNavigationBarIconBrightness:
            Theme.of(context).brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_selectedIndex),
                    child: _screens[_selectedIndex],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: navItems,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavConfig config, bool isSelected) {
    final unreadCount = _getTotalUnreadCount(config);

    return GestureDetector(
      onTap: () => _changeIndex(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              HugeIcon(
                icon: config.iconData,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface.withOpacity(0.5),
                size: 28.0,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreNavItem(bool isSelected) {
    bool hasNotificationsInRange = false;

    for (int i = 4; i < _navConfigs.length; i++) {
      if (_getTotalUnreadCount(_navConfigs[i]) > 0) {
        hasNotificationsInRange = true;
        break;
      }
    }

    return GestureDetector(
      onTap: _showMoreMenu,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: AnimatedScale(
          scale: isSelected ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedMoreHorizontal,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface.withOpacity(0.5),
                size: 28.0,
              ),
              if (hasNotificationsInRange)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CONFIGURATION MODELS
// ============================================================================

enum UserRole { guest, parent, student }

class NavConfig {
  final dynamic iconData; // Compatible with older Hugeicons package
  final String label;
  final Widget screen;
  final bool isAdminOnly;
  final String? notificationKey;
  final bool showClubNotifications;

  NavConfig({
    required this.iconData,
    required this.label,
    required this.screen,
    this.isAdminOnly = false,
    this.notificationKey,
    this.showClubNotifications = false,
  });
}
