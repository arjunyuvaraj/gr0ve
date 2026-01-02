import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gr0ve/utilities/helper_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationService {
  // VARIABLES: Instantiate GoogleSignIn, and create a variable to ensure we don't initialize multiple times
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;
  bool _appleSigningIn = false;

  // METHOD: Get all Google Sign-In resources ready
  Future<void> initializeGoogleSignIn() async {
    if (!_initialized) {
      await _googleSignIn.initialize();
      _initialized = true;
    }
  }

  void signInWithGoogle(BuildContext context) async {
    // WEB: Firebase popup flow
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
      return;
    }

    // MOBILE FLOW
    await initializeGoogleSignIn();

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email'],
      );

      final idToken = (await googleUser.authentication).idToken;

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

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
      displayMessageToUser('Unexpected Google Sign-In error: $e', context);
    }
  }

  Future<UserCredential?> signInWithApple(BuildContext context) async {
    // Debounce: prevent overlapping auth sessions
    if (_appleSigningIn) return null;
    _appleSigningIn = true;

    try {
      // Step 1: Request Apple credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Step 2: Create Firebase OAuth credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Step 3: Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );

      // Step 4: Navigate ONLY on success
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/authentication');
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User tapped "Cancel" → SILENT
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }

      // Any other Apple auth error → silent fail
      return null;
    } on FirebaseAuthException {
      // Firebase rejected credential → silent fail
      return null;
    } catch (_) {
      // Native iOS errors (ERR1000, etc.) → swallow
      return null;
    } finally {
      // ALWAYS reset debounce flag
      _appleSigningIn = false;
    }
  }

  void signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      email = email.trim();

      if (email.isEmpty || password.isEmpty) {
        displayMessageToUser("Email or password cannot be empty.", context);
        return;
      }

      if (!email.contains("@") || !email.contains(".")) {
        displayMessageToUser("Please enter a valid email.", context);
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        Navigator.pushNamed(context, '/onboarding');
      } else {
        Navigator.pushNamed(context, '/authentication');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "wrong-password":
          displayMessageToUser("Incorrect password.", context);
          break;

        case "user-not-found":
          displayMessageToUser("No account found.", context);
          break;

        case "account-exists-with-different-credential":
        case "invalid-credential":
          displayMessageToUser(
            "This email belongs to a Google account. Redirecting...",
            context,
          );
          signInWithGoogle(context);
          break;

        case "invalid-email":
          displayMessageToUser("Invalid email format.", context);
          break;

        default:
          displayMessageToUser("Sign-in error: ${e.code}", context);
          break;
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
        'You reached onboarding but are not signed in.',
        context,
      );
      return;
    }

    final uid = user.uid;

    try {
      await firestore.collection('Students').doc(uid).set({
        'name': name,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'starredTeachers': [],
      });
    } catch (e) {
      displayMessageToUser("Onboarding Error: $e", context);
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
    final data = await FirebaseFirestore.instance
        .collection('Students')
        .doc(uid)
        .get();
    return data.data()!;
  }

  Future<void> signOutWithGoogle(BuildContext context) async {
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signOut();
      } else {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      }

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
