import 'package:flutter/material.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/landing_screen.dart';
import 'package:gr0ve/pages/navigation_screen.dart';
import 'package:gr0ve/pages/privacy_policy_screen.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/theme/dark_theme.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';
import 'package:gr0ve/utilities/landing_decider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const docId =
      "2PACX-1vT_iK6QcUDVJoo_A6Enz5eizn4PzAWGfJBGo1vaC6T2y_0vHaYcL3ZlwcPN4H6pNCNEExNKGwxyktWC";
  const docUrl = 'https://docs.google.com/document/d/e/$docId/pub';

  try {
    absenceList = await fetchGoogleDocMap(docUrl);
  } catch (e) {
    absenceList = {};
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gr0ve',
      theme: darkTheme,
      debugShowCheckedModeBanner: false,
      home: LandingDecider(
        landingPage: const LandingScreen(),
        navigationRoute: '/navigation',
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/teacher_absence': (context) => const AbsenceScreen(),
        '/landing': (context) => const LandingScreen(),
        '/navigation': (context) => const NavigationScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
