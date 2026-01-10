import 'package:flutter/material.dart';
import 'package:gr0ve/pages/bus_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/quick_links_screen.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class NavigationScreen extends StatefulWidget {
  final int initialIndex;

  const NavigationScreen({super.key, this.initialIndex = 0});

  @override
  NavigationScreenState createState() => NavigationScreenState();
}

class NavigationScreenState extends State<NavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;

    return IconButton(
      onPressed: () => changeIndex(index),
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
    final children = <Widget>[
      const HomeScreen(),
      const AbsenceScreen(),
      const BusScreen(),
      const HelpScreen(),
      QuickLinksScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: IndexedStack(index: _selectedIndex, children: children),
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
          children: [
            _buildNavIcon(Icons.home_rounded, 0),
            _buildNavIcon(Icons.person_off_rounded, 1),
            _buildNavIcon(Icons.bus_alert_rounded, 2),
            _buildNavIcon(Icons.help_outline_rounded, 3),
            _buildNavIcon(Icons.link, 4),
          ],
        ),
      ),
    );
  }
}
