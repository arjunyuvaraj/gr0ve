import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gr0ve/pages/account_deletion_screen.dart';
import 'package:gr0ve/pages/admin_panel_screen.dart';
import 'package:gr0ve/pages/help_screen.dart';
import 'package:gr0ve/pages/absence_screen.dart';
import 'package:gr0ve/pages/home_screen.dart';
import 'package:gr0ve/pages/join_requests_screen.dart';
import 'package:gr0ve/pages/landing_screen.dart';
import 'package:gr0ve/pages/landing_screen_web.dart';
import 'package:gr0ve/pages/login_screen.dart';
import 'package:gr0ve/pages/lunch_menu_screen.dart';
import 'package:gr0ve/pages/register_screen.dart';
import 'package:gr0ve/pages/navigation_screen.dart';
import 'package:gr0ve/pages/privacy_policy_screen.dart';
import 'package:gr0ve/services/notification_service.dart';
import 'package:gr0ve/services/teacher_service.dart';
import 'package:gr0ve/theme/dark_theme.dart';
import 'package:gr0ve/theme/light_theme.dart';
import 'package:gr0ve/utilities/landing_decider.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/utilities/teacher_utils.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load teacher list from Firestore
  try {
    teacherList = await fetchTeacherListFromFirebase();
  } catch (e) {
    if (kDebugMode) {
      print('Error loading teachers: $e');
    }
    teacherList = {};
  }

  // NO MORE GOOGLE SHEETS CALLS AT STARTUP!
  // Absences are now loaded from Firestore when the user opens the absence screen
  // This fixes the security vulnerability
  absenceList = {};

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User logged in - start listening for notifications
        NotificationService().startListening();
      } else {
        // User logged out - stop listening
        NotificationService().stopListening();
      }
    });
  }

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
        '/admin': (context) => const AdminPanelScreen(),
        '/register': (context) => const RegisterScreen(),
        '/navigation': (context) => const NavigationScreen(),
        '/privacy_policy': (context) => const PrivacyPolicyScreen(),
        '/help': (context) => const HelpScreen(),
        '/account_deletion': (context) => const AccountDeletionInfoScreen(),
        '/lunch_menu': (context) => const LunchMenuScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/club/join-requests') {
          final groupId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (context) => JoinRequestsScreen(groupId: groupId),
          );
        }
        return null;
      },
    );
  }
}
