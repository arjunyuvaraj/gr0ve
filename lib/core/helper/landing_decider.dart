import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gr0ve/core/widgets/misc/premium_loading_indicator.dart';

class LandingDecider extends StatefulWidget {
  final Widget landingPage;
  final Widget loginPage;
  final String navigationRoute;

  const LandingDecider({
    super.key,
    required this.landingPage,
    required this.loginPage,
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

  @override
  void initState() {
    super.initState();
    _checkAuthAndLandingStatus();
  }

  Future<void> _checkAuthAndLandingStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('landing_seen') ?? false;

    if (!mounted) return;

    if (seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(widget.navigationRoute);
        }
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: PremiumLoadingIndicator());
    }

    return widget.landingPage;
  }
}
