import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/pages/account_screen.dart';
import 'package:gr0ve/pages/bus_screen.dart';
import 'package:gr0ve/pages/calendar_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/lunch_menu_screen.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class NavigationScreen extends StatefulWidget {
  final int initialIndex;

  const NavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late int _selectedIndex;
  User? user;
  late List<Widget> screens;
  late List<NavigationItem> navigationItems;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    user = FirebaseAuth.instance.currentUser;
    _setupScreens();
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
    } else if (email.endsWith('@bergen.org')) {
      screens = const [
        HomeScreen(),
        AbsenceScreen(),
        BusScreen(),
        LunchMenuScreen(),
        CalendarScreen(),
        HelpScreen(),
        AccountScreen(),
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
        NavigationItem(icon: Icons.help_outline_rounded, label: 'Help'),
        NavigationItem(icon: Icons.person_rounded, label: 'Account'),
      ];
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
      leading: Icon(
        item.icon,
        color: isSelected
            ? context.colors.primary
            : context.colors.onSurface.withAlpha(140),
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

  NavigationItem({required this.icon, required this.label});
}
