import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';

// SERVICE: Handles Firebase Authentication and user profile management
class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // METHOD: specific validation for BCA emails
  bool _isBCAEmail(String email) {
    return email.toLowerCase().endsWith('@bergen.org');
  }

  // METHOD: Creates or updates user document in Firestore on login
  // LOGIC: Updates lastLoginAt if document exists, otherwise creates new user profile
  Future<void> _createUserDocument(User user, {String? email}) async {
    final userEmail = email ?? user.email ?? '';
    final isBCA = userEmail.isNotEmpty ? _isBCAEmail(userEmail) : false;
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': userEmail,
        'isBCA': isBCA,
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  // METHOD: Signs up a new user with email and password
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: trimmedPassword,
          );
      
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!, email: trimmedEmail);
        await userCredential.user?.updateDisplayName(name);
        await userCredential.user?.reload();
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // METHOD: Signs in existing user
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: trimmedEmail,
            password: trimmedPassword,
          );

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!, email: trimmedEmail);
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // METHOD: Signs in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // METHOD: Signs out user and resets app state
  // LOGIC: Explicitly resets StarredTeacherService to prevent state leakage
  Future<void> signOut() async {
    try {
      // Reset services BEFORE signing out
      StarredTeacherService.reset();
      
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // METHOD: Sends password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  // METHOD: Fetches user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch user data.');
    }
  }

  // METHOD: Checks if current user is from BCA domain
  Future<bool> isCurrentUserBCA() async {
    if (currentUser == null) return false;

    try {
      final userData = await getUserData(currentUser!.uid);
      return userData?['isBCA'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // METHOD: Upgrades anonymous account to permanent account
  Future<User?> linkAnonymousToEmailPassword(
    String email,
    String password,
  ) async {
    if (currentUser == null || !currentUser!.isAnonymous) {
      throw Exception('No anonymous user to link.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password.trim(),
      );

      final userCredential = await currentUser!.linkWithCredential(credential);

      if (userCredential.user != null) {
        final trimmedEmail = email.trim();
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
              'email': trimmedEmail,
              'isBCA': _isBCAEmail(trimmedEmail),
              'isAnonymous': false,
            });
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to link account. Please try again.');
    }
  }

  // METHOD: Deletes user account and profile
  Future<void> deleteAccount() async {
    if (currentUser == null) return;

    try {
      final uid = currentUser!.uid;
      await currentUser!.delete();
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  // METHOD: Maps Firebase exceptions to user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
