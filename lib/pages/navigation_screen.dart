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
import 'package:gr0ve/utilities/context_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // ignore: unused_field
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    user = FirebaseAuth.instance.currentUser;
    _setupScreens(); // Setup screens immediately with non-admin view
    _checkAdminStatus();
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
      // Base screens for @bergen.org users
      screens = [
        const HomeScreen(),
        const AbsenceScreen(),
        const BusScreen(),
        const LunchMenuScreen(),
        const CalendarScreen(),
        const ClubScreen(),
        // const MapScreen(),
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
        NavigationItem(icon: Icons.group, label: 'Clubs'),
        // NavigationItem(icon: Icons.map_rounded, label: 'Maps'),
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
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  Widget _buildDrawerItem(NavigationItem item, int index) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: isSelected
                ? context.colors.primary
                : context.colors.onSurface.withAlpha(140),
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
      title: Text(
        item.label,
        style: TextStyle(
          color: isSelected ? context.colors.primary : context.colors.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
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

            // Hamburger button - simple, not floating
            Positioned(
              top: 16,
              left: 24,
              child: IconButton(
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

  NavigationItem({
    required this.icon,
    required this.label,
    this.isAdminOnly = false,
  });
}
