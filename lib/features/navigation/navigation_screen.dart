import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/features/account/account_screen.dart';
import 'package:gr0ve/features/admin/admin_panel_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/features/bus/bus_screen.dart';
import 'package:gr0ve/features/calendar/calendar_screen.dart';
import 'package:gr0ve/features/club/club_screen.dart';
import 'package:gr0ve/features/absence/absence_screen.dart';
import 'package:gr0ve/features/home/home_screen.dart';
import 'package:gr0ve/features/lunch_menu/lunch_menu_screen.dart';
import 'package:gr0ve/features/map/map_screen.dart';
import 'package:gr0ve/features/admin/admin_calendar_requests_screen.dart';
import 'package:gr0ve/core/extensions/context_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/notifications/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'navigation_item.dart';
import 'custom_navigation_drawer.dart';

// SCREEN: Main navigation hub for the application
// LOGIC: Handles top-level navigation, admin checks, and notification routing
class NavigationScreen extends StatefulWidget {
  final int initialIndex;

  const NavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late int _selectedIndex;
  User? user;
  List<Widget> screens = [];
  List<NavigationItem> navigationItems = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isPlatformAdmin = false;

  String _versionCode = '0.0.0';
  StreamSubscription? _unreadCountSubscription;
  Map<String, int> _unreadCounts = {};
  Map<String, int> _unreadAnnouncementsByClub = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    user = FirebaseAuth.instance.currentUser;
    _setupScreens(); // Setup screens immediately with non-admin view
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

  /// Subscribe to unread count updates
  void _subscribeToUnreadCounts() {
    _unreadCountSubscription = NotificationService().unreadCountStream.listen((
      data,
    ) {
      if (mounted) {
        setState(() {
          // Extract both the counts and announcements by club
          // Convert from Map<dynamic, dynamic> to Map<String, int>
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

    // Get initial counts
    setState(() {
      _unreadCounts = NotificationService().unreadCounts;
      _unreadAnnouncementsByClub =
          NotificationService().unreadAnnouncementsByClub;
    });
  }

  // METHOD: Load version information from package info
  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionCode = packageInfo.version;
        });
      }
      print('[NAV] App version: $_versionCode');
    } catch (e) {
      print('[NAV] Error loading version info: $e');
    }
  }

  // METHOD: Check if version is 1.5.0 or above for feature gating
  bool _isVersionAbove150() {
    try {
      final parts = _versionCode.split('.');
      if (parts.length < 2) return false;

      final major = int.tryParse(parts[0]) ?? 0;
      final minor = int.tryParse(parts[1]) ?? 0;

      return major > 1 || (major == 1 && minor >= 5);
    } catch (e) {
      print('[NAV] Error parsing version: $e');
      return false;
    }
  }

  // METHOD: Setup notification tap handler
  // LOGIC: Handles navigation based on payload type (announcement, join_request, etc.)
  void _setupNotificationHandler() {
    print('[NAV] Setting up notification handler');

    NotificationService().setNotificationTapCallback((
      NotificationResponse response,
    ) {
      final payload = response.payload;
      print('[NAV] Notification tapped with payload: $payload');

      if (!_isVersionAbove150()) {
        print('[NAV] Version below 1.5.0, skipping navigation');
        return;
      }

      if (payload == null) {
        print('[NAV] No payload in notification');
        return;
      }

      // Parse the payload
      if (payload.startsWith('announcement:')) {
        // Navigate to clubs screen
        _navigateToClubs();
      } else if (payload.startsWith('join_request:')) {
        // Navigate to club requests admin panel
        _navigateToClubRequests();
        // Clear unread count
        NotificationService().clearUnreadCount('join_requests');
      } else if (payload.startsWith('club_request:')) {
        // Navigate to club requests admin panel
        _navigateToClubRequests();
        // Clear unread count
        NotificationService().clearUnreadCount('club_requests');
      } else if (payload.startsWith('bus:')) {
        // Navigate to bus screen
        _navigateToBus();
      }
    });
  }

  /// Navigate to clubs screen
  void _navigateToClubs() {
    print('[NAV] Navigating to clubs screen');
    final clubIndex = _findScreenIndex(ClubScreen);
    if (clubIndex != -1 && mounted) {
      setState(() {
        _selectedIndex = clubIndex;
      });
    }
  }

  /// Navigate to club requests (admin panel)
  void _navigateToClubRequests() {
    print('[NAV] Navigating to club requests screen');
    final adminPanelIndex = _findScreenIndex(AdminPanelScreen);
    if (adminPanelIndex != -1 && mounted) {
      setState(() {
        _selectedIndex = adminPanelIndex;
      });
    }
  }

  /// Navigate to bus screen
  void _navigateToBus() {
    print('[NAV] Navigating to bus screen');
    final busIndex = _findScreenIndex(BusScreen);
    if (busIndex != -1 && mounted) {
      setState(() {
        _selectedIndex = busIndex;
      });
    }
  }

  /// Find index of screen by type
  int _findScreenIndex(Type screenType) {
    for (int i = 0; i < screens.length; i++) {
      if (screens[i].runtimeType == screenType) {
        return i;
      }
    }
    return -1;
  }

  Future<void> _checkAdminStatus() async {
    if (user != null) {
      try {
        // Check if user is the platform admin email
        final email = user!.email ?? '';
        final isManagerEmail = email == "gr0ve.bca.manager@gmail.com";

        // Check Firestore admins collection
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user!.uid)
            .get();

        if (mounted) {
          setState(() {
            _isPlatformAdmin = adminDoc.exists || isManagerEmail;
            _setupScreens(); // Re-setup screens with admin status
          });
        }
      } catch (e) {
        // Error checking admin status, continue with non-admin setup
        if (mounted) {
          _setupScreens();
        }
      }
    }
  }

  void _setupScreens() {
    final email = user?.email ?? '';
    if (user == null) {
      screens = const [BusScreen(), HelpScreen(), AccountScreen()];
      navigationItems = [
        NavigationItem(icon: Icons.bus_alert_rounded, label: 'Bus'),
        NavigationItem(icon: Icons.help_outline_rounded, label: 'Help'),
        NavigationItem(icon: Icons.person_rounded, label: 'Account'),
      ];
    } else if (email.endsWith('@bergen.org') ||
        email == "gr0ve.bca.manager@gmail.com") {
      screens = [
        const HomeScreen(),
        const AbsenceScreen(),
        const BusScreen(),
        const LunchMenuScreen(),
        const CalendarScreen(),
        // TODO: Comment out if switching version
        const ClubScreen(),
        const MapScreen(),
        const HelpScreen(),
        const AccountScreen(),
      ];

      navigationItems = [
        NavigationItem(icon: Icons.home_rounded, label: 'Home'),
        NavigationItem(
          icon: Icons.person_remove_alt_1_outlined,
          label: 'Absence',
        ),
        NavigationItem(icon: Icons.bus_alert_rounded, label: 'Bus'),
        NavigationItem(icon: Icons.lunch_dining_rounded, label: 'Lunch Menu'),
        NavigationItem(icon: Icons.calendar_month, label: 'Calendar'),
        // TODO: Comment out if switching version
        NavigationItem(
          icon: Icons.group,
          label: 'Clubs',
          showClubNotifications: true,
        ),
        NavigationItem(icon: Icons.map_rounded, label: 'Maps'),
        NavigationItem(icon: Icons.help_outline_rounded, label: 'Help'),
        NavigationItem(icon: Icons.person_rounded, label: 'Account'),
      ];

      // Add admin screen if platform admin
      if (_isPlatformAdmin) {
        screens.insert(5, const AdminCalendarRequestsScreen());
        screens.insert(6, const AdminPanelScreen());
        navigationItems.insert(
          5,
          NavigationItem(
            icon: Icons.pending_actions,
            label: 'Event Requests',
            isAdminOnly: true,
          ),
        );
        navigationItems.insert(
          6,
          NavigationItem(
            icon: Icons.pending_actions,
            label: 'Club Requests',
            isAdminOnly: true,
            unreadCountKey: 'club_requests',
          ),
        );
      }
    } else {
      screens = const [
        HomeScreen(),
        BusScreen(),
        LunchMenuScreen(),
        HelpScreen(),
        AccountScreen(),
      ];
      navigationItems = [
        NavigationItem(icon: Icons.home_rounded, label: 'Home'),
        NavigationItem(icon: Icons.bus_alert_rounded, label: 'Bus'),
        NavigationItem(icon: Icons.lunch_dining_rounded, label: 'Lunch Menu'),
        NavigationItem(icon: Icons.help_outline_rounded, label: 'Help'),
        NavigationItem(icon: Icons.person_rounded, label: 'Account'),
      ];
    }
  }

  void _changeIndex(int index) {
    // Clear unread count when navigating to a screen
    final item = navigationItems[index];
    if (item.unreadCountKey != null) {
      NotificationService().clearUnreadCount(item.unreadCountKey!);
    }

    // Clear all club announcement counts when going to clubs screen
    if (item.showClubNotifications) {
      NotificationService().clearAllAnnouncementCounts();
    }

    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if there are ANY unread notifications
    final hasAnyUnread =
        _unreadCounts.values.any((count) => count > 0) ||
        _unreadAnnouncementsByClub.values.any((count) => count > 0);

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomNavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changeIndex,
        navigationItems: navigationItems,
        unreadCounts: _unreadCounts,
        unreadAnnouncementsByClub: _unreadAnnouncementsByClub,
        isDarkMode: isDarkMode,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: IndexedStack(index: _selectedIndex, children: screens),
            ),

            // Hamburger button with notification indicator
            Positioned(
              top: 16,
              left: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.menu_rounded,
                      size: 28,
                      color: context.colors.onSurface,
                    ),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  // Red dot indicator if any unread notifications
                  if (hasAnyUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.colors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
