import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class AuthenticationService {
  // VARIABLES: Instantiate GoogleSignIn, and create a variable to ensure we don't initialize multiple times
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  // METHOD: Get all of the Google and Authentication stuff ready
  Future<void> initializeGoogleSignIn() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  void signInWithGoogle(BuildContext context) async {
    // WEB: Use FirebaseAuth popup instead of google_sign_in (required)
    if (kIsWeb) {
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        final userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );

        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          Navigator.pushNamed(context, '/onboarding');
        } else {
          Navigator.pushNamed(context, '/authentication');
        }
      } catch (e) {
        displayMessageToUser('Google Web Sign-In failed: $e', context);
      }
      return; // IMPORTANT: Stop here or the mobile flow runs too
    }

    // MOBILE FLOW (unchanged)
    await initializeGoogleSignIn();

    try {
      // Sign in with Google popup
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email'],
      );

      final idToken = (await googleUser.authentication).idToken;

      // Convert to Firebase credential
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // Sign the user in
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // Route based on whether user is new
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        Navigator.pushNamed(context, '/onboarding');
      } else {
        Navigator.pushNamed(context, '/authentication');
      }
    } on GoogleSignInException catch (e) {
      displayMessageToUser(
        'Google Sign-In error: ${e.code} / ${e.description}',
        context,
      );
    } catch (e) {
      displayMessageToUser(
        'Unexpected error during Google Sign-In: $e',
        context,
      );
    }
  }

  void signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      // TRIM — SUPER IMPORTANT
      email = email.trim();

      // VALIDATION
      if (email.isEmpty || password.isEmpty) {
        displayMessageToUser("Email or password cannot be empty.", context);
        return;
      }

      // Must look like an email
      if (!email.contains("@") || !email.contains(".")) {
        displayMessageToUser("Please enter a valid email.", context);
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // MATCH GOOGLE SIGN-IN LOGIC
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        Navigator.pushNamed(context, '/onboarding');
      } else {
        Navigator.pushNamed(context, '/authentication');
      }
    } on FirebaseAuthException catch (e) {
      // HANDLE REAL AUTH CODE ERRORS CLEANLY
      switch (e.code) {
        case "user-not-found":
          displayMessageToUser("No account found for that email.", context);
          break;

        case "wrong-password":
          displayMessageToUser("Incorrect password.", context);
          break;

        case "invalid-email":
          displayMessageToUser(
            "The email address is badly formatted.",
            context,
          );
          Navigator.pushNamed(context, '/onboarding');
          break;

        case "invalid-credential":
          FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          Navigator.pushNamed(context, '/onboarding');
          break;

        default:
          displayMessageToUser("Sign-in error: ${e.code}", context);
      }
    } catch (e) {
      displayMessageToUser("Unexpected error: $e", context);
    }
  }

  void onboardUser(BuildContext context, String name) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final user = auth.currentUser;
    if (user == null) {
      displayMessageToUser(
        'You reached onboarding but is not signed in. Wait a few seconds, or, close and restart the app',
        context,
      );
      return;
    }

    final uid = user.uid;

    try {
      // Create the Firestore doc ONLY ONCE
      await firestore.collection('Students').doc(uid).set({
        'name': name,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'starredTeachers': [],
      });
    } catch (e) {
      print('Onboarding Firestore error: $e');
      return;
    }

    if (!context.mounted) return;

    Navigator.pushReplacementNamed(context, '/navigation');
  }

  Future<Map<String, dynamic>> getCurrentUserDocument(
    BuildContext context,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;
    final data = await firestore.collection('Students').doc(uid).get();
    return data.data()!;
  }

  Future<void> signOutWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        // WEB: Only sign out through Firebase
        await FirebaseAuth.instance.signOut();
      } else {
        // MOBILE: Sign out from Google AND Firebase
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      }

      // NAVIGATE: Go back to authentication
      Navigator.pushNamed(context, '/authentication');
    } catch (e) {
      displayMessageToUser("Error signing out: $e", context);
    }
  }

  void deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        displayMessageToUser("No user found.", context);
        return;
      }
      final uid = user.uid;

      await user.delete();

      await FirebaseFirestore.instance.collection("Students").doc(uid).delete();

      Navigator.pushNamed(context, "/landing");
    } catch (e) {
      displayMessageToUser("Account deletion failed: $e", context);
    }
  }

  bool userLoggedIn() {
    return FirebaseAuth.instance.currentUser == null;
  }
}
