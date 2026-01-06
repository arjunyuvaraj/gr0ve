import 'package:flutter/material.dart';
import 'package:gr0ve/pages/account_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/landing_screen.dart';
import 'package:gr0ve/pages/navigation_screen.dart';
import 'package:gr0ve/pages/privacy_policy_screen.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/theme/light_theme.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fetch absence list (NO Firebase)
  const docId =
      "2PACX-1vT_iK6QcUDVJoo_A6Enz5eizn4PzAWGfJBGo1vaC6T2y_0vHaYcL3ZlwcPN4H6pNCNEExNKGwxyktWC";
  const docUrl = 'https://docs.google.com/document/d/e/$docId/pub';

  try {
    absenceList = await fetchGoogleDocMap(docUrl);
  } catch (e) {
    absenceList = {};
    debugPrint("Failed to fetch absence list: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gr0ve',
      theme: lightTheme,
      debugShowCheckedModeBanner: false,

      // 🚀 Direct entry — no auth gate
      home: const NavigationScreen(),

      routes: {
        '/home': (context) => const AbsenceScreen(),
        '/landing': (context) => const LandingScreen(),
        '/navigation': (context) => const NavigationScreen(),
        '/account': (context) => const AccountScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
