import 'package:flutter/material.dart';
import 'package:gr0ve/pages/account_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/privacy_policy_screen.dart';
import 'package:gr0ve/utilities/context_extensions.dart';

class NavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialStore;

  const NavigationScreen({super.key, this.initialIndex = 0, this.initialStore});

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
    Navigator.pop(context);
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      HomeScreen(),
      AccountScreen(),
      PrivacyPolicyScreen(),
      HelpScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          Positioned(
            top: 54,
            left: 24,
            child: GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: context.colors.onSurface,
                  size: 28,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: IndexedStack(index: _selectedIndex, children: children),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  "gr0ve".capitalized,
                  style: context.text.displayMedium?.copyWith(
                    color: context.colors.onPrimary.withAlpha(200),
                  ),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text("Home"),
              onTap: () => changeIndex(0),
            ),

            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text("Account"),
              onTap: () => changeIndex(1),
            ),

            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text("Privacy Policy"),
              onTap: () => changeIndex(2),
            ),

            ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text("Contact Us"),
              onTap: () => changeIndex(3),
            ),
          ],
        ),
      ),
    );
  }
}
