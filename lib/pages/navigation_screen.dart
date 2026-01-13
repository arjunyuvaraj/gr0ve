import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/pages/account_screen.dart';
import 'package:gr0ve/pages/bus_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart'; // Treat as Teacher/Absence
import 'package:gr0ve/pages/home_screen.dart';
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
  late List<IconData> icons;

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
      icons = [
        Icons.bus_alert_rounded,
        Icons.help_outline_rounded,
        Icons.person_rounded,
      ];
    } else if (email.endsWith('@bergen.org')) {
      screens = const [
        HomeScreen(),
        AbsenceScreen(),
        BusScreen(),
        HelpScreen(),
        AccountScreen(),
      ];
      icons = [
        Icons.home_rounded,
        Icons.person_remove_alt_1_outlined,
        Icons.bus_alert_rounded,
        Icons.help_outline_rounded,
        Icons.person_rounded,
      ];
    } else {
      screens = const [
        HomeScreen(),
        BusScreen(),
        HelpScreen(),
        AccountScreen(),
      ];
      icons = [
        Icons.home_rounded,
        Icons.bus_alert_rounded,
        Icons.help_outline_rounded,
        Icons.person_rounded,
      ];
    }
  }

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () => _changeIndex(index),
      icon: Icon(
        icon,
        size: 28,
        color: isSelected
            ? context.colors.primary
            : context.colors.onSurface.withAlpha(140),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: IndexedStack(index: _selectedIndex, children: screens),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.onSurface.withAlpha(30),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 24,
          top: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            icons.length,
            (index) => _buildNavIcon(icons[index], index),
          ),
        ),
      ),
    );
  }
}
