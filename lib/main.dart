import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/landing_screen.dart';
import 'package:gr0ve/pages/landing_screen_web.dart';
import 'package:gr0ve/pages/login_screen.dart';
import 'package:gr0ve/pages/register_screen.dart';
import 'package:gr0ve/pages/navigation_screen.dart';
import 'package:gr0ve/pages/privacy_policy_screen.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/theme/dark_theme.dart';
import 'package:gr0ve/theme/light_theme.dart';
import 'package:gr0ve/utilities/data/teacher_list.dart';
import 'package:gr0ve/utilities/landing_decider.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Replace with your private Google Sheet ID
  const teacherAbsenceSpreadsheetId =
      '1Ocm7wpxK9_xlkJGe9z8zH-I5TPsio1fZAxUf0rNs5Jk';
  const teacherAbsenceWorksheetTitle =
      'Absences'; // or whatever your sheet is named

  try {
    absenceList = await fetchGoogleSheetAbsences(
      spreadsheetId: teacherAbsenceSpreadsheetId,
      worksheetTitle: teacherAbsenceWorksheetTitle,
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error loading teacher absences: $e');
    }
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
      darkTheme: darkTheme,
      theme: lightTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,

      home: Builder(
        builder: (context) => LandingDecider(
          landingPage: kIsWeb
              ? const LandingWebsiteScreen()
              : const LandingScreen(),
          loginPage: const LoginScreen(),
          navigationRoute: '/navigation',
        ),
      ),

      routes: {
        '/home': (context) => const HomeScreen(),
        '/teacher_absence': (context) => const AbsenceScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/navigation': (context) => const NavigationScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
