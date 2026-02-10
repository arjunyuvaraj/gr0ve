import 'package:gr0ve/core/utilities/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/pages/account_screen.dart';
import 'package:gr0ve/pages/admin_panel_screen.dart';
import 'package:gr0ve/pages/bus_screen.dart';
import 'package:gr0ve/pages/calendar_screen.dart';
import 'package:gr0ve/pages/club_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/lunch_menu_screen.dart';
import 'package:gr0ve/pages/map_screen.dart';
import 'package:gr0ve/pages/admin_calendar_requests_screen.dart';
import 'package:gr0ve/core/utilities/extensions/context_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

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
  bool _isLoading = true;
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

  /// Load version information
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

  /// Check if version is 1.5.0 or above
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

  /// Setup notification tap handler
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
            _isLoading = false;
            _setupScreens(); // Re-setup screens with admin status
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  Widget _buildDrawerItem(NavigationItem item, int index) {
    final isSelected = _selectedIndex == index;

    // Calculate unread count
    int unreadCount = 0;
    if (item.showClubNotifications) {
      // Sum all club announcement counts
      unreadCount = _unreadAnnouncementsByClub.values.fold(
        0,
        (sum, count) => sum + count,
      );
    } else if (item.unreadCountKey != null) {
      unreadCount = _unreadCounts[item.unreadCountKey] ?? 0;
    }

    final hasUnread = unreadCount > 0;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface.withAlpha(140),
              ),
              if (hasUnread)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 12,
                    height: 12,
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
          if (item.isAdminOnly) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: isSelected
                    ? context.colors.primary
                    : context.colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 20),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: context.colors.primary.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () => _changeIndex(index),
    );
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
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.onSurface.withOpacity(0.1),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          isDarkMode
                              ? "assets/appicon_dark.png"
                              : "assets/app_icon.png",
                          width: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'gr0ve'.capitalized,
                      style: context.text.displayLarge?.copyWith(fontSize: 48),
                    ),
                  ],
                ),
              ),

              Divider(
                thickness: 1,
                color: context.colors.onSurface.withOpacity(0.1),
                indent: 20,
                endIndent: 20,
              ),

              const SizedBox(height: 8),

              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: List.generate(
                    navigationItems.length,
                    (index) => _buildDrawerItem(navigationItems[index], index),
                  ),
                ),
              ),
            ],
          ),
        ),
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
