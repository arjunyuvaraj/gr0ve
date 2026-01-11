// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingDecider extends StatefulWidget {
  final Widget landingPage;
  final String navigationRoute;

  const LandingDecider({
    super.key,
    required this.landingPage,
    required this.navigationRoute,
  });

  static Future<void> markLandingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('landing_seen', true);
  }

  @override
  State<LandingDecider> createState() => _LandingDeciderState();
}

class _LandingDeciderState extends State<LandingDecider> {
  bool _loading = true;
  bool _showLanding = true;

  @override
  void initState() {
    super.initState();
    _checkLandingStatus();
  }

  Future<void> _checkLandingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('landing_seen') ?? false;

    if (!mounted) return;

    if (seen) {
      // Already seen → go straight to the main app
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(widget.navigationRoute);
      });
    } else {
      // First time → show landing page
      setState(() {
        _showLanding = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return widget.landingPage;
  }
}
