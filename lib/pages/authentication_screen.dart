import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gr0ve/pages/landing_screen.dart';
import 'package:gr0ve/pages/navigation_screen.dart';

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        // FIREBASE-AUTH: Checking for any state changes, when the user logs in, or logs out
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // FIREBASE-AUTH: User is logged in
          if (snapshot.hasData) {
            print("HERE");
            return NavigationScreen();
          }
          // FIREBASE-AUTH: User is not logged in
          else {
            return LandingScreen();
          }
        },
      ),
    );
  }
}
