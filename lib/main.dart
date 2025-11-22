import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/firebase_options.dart';
import 'package:gr0ve/pages/account_screen.dart';
import 'package:gr0ve/pages/authentication_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/landing_screen.dart';
import 'package:gr0ve/pages/navigation_screen.dart';
import 'package:gr0ve/pages/onboarding_screen.dart';
import 'package:gr0ve/pages/privacy_policy_screen.dart';
import 'package:gr0ve/theme/light_theme.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  String docId =
      "2PACX-1vT_iK6QcUDVJoo_A6Enz5eizn4PzAWGfJBGo1vaC6T2y_0vHaYcL3ZlwcPN4H6pNCNEExNKGwxyktWC";
  String docUrl = 'https://docs.google.com/document/d/e/$docId/pub';
  Map<String, String> content = await fetchGoogleDocMap(docUrl);
  absenceList = content;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: lightTheme,
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => AuthenticationScreen(),
        '/authentication': (context) => AuthenticationScreen(),
        '/landing': (context) => LandingScreen(),
        '/home': (context) => HomeScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/account': (context) => AccountScreen(),
        '/privacy_policy': (context) => PrivacyPolicyScreen(),
        '/navigation': (context) => NavigationScreen(),
        '/help': (context) => HelpScreen(),
      },
    );
  }
}
