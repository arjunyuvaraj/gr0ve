import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gr0ve/utilities/helper_functions.dart';

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

  // METHOD: Sign in the user
  void signInWithGoogle(BuildContext context) async {
    // GOOGLE: Start up the Google popup
    await initializeGoogleSignIn();

    // TRY-CATCH: Prevent any unexpected errors
    try {
      // GOOGLE: Get the user's email
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email'], // Get the email
      );

      // GOOGLE: Get the ID Token to give to Firebase
      final idToken = googleUser.authentication.idToken;

      // FIREBASE: Make sure it's stored with Google
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      // USER: Sign the user in
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      // CHECK: If the user is new, have them fill out which school they are from
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        Navigator.pushNamed(context, '/onboarding');
      } else {
        Navigator.pushNamed(context, '/authentication');
      }
    } on GoogleSignInException catch (e) {
      // ERROR: Some error occurred with Google
      displayMessageToUser(
        'Google Sign-In error: ${e.code} / ${e.description}',
        context,
      );
      return;
    } catch (e) {
      // ERROR: Some error occurred in general
      displayMessageToUser(
        'Unexpected error during Google Sign-In: $e',
        context,
      );
      return;
    }
  }

  void onboardUser(BuildContext context, String name) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final user = auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final email = user.email ?? '';
    final displayName = user.displayName ?? '';

    await firestore.collection('Students').doc(uid).set({
      'name': name,
      'displayName': displayName,
      'email': email,
      'starredTeachers': [],
    });

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
      // GOOGLE: Sign out from Google
      await _googleSignIn.signOut();

      // FIREBASE: Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // NAVIGATE: Re-route to the welcome page
    } catch (e) {
      // ERROR: Something went wrong when signing out
      displayMessageToUser("Error signing out: $e", context);
    }
    Navigator.pushNamed(context, '/authentication');
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
}
