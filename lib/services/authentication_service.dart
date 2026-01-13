import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/starred_teacher_service.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is from BCA domain
  bool _isBCAEmail(String email) {
    return email.toLowerCase().endsWith('@bergen.org');
  }

  // Create or update user document in Firestore
  Future<void> _createUserDocument(User user, {String? email}) async {
    final userEmail = email ?? user.email ?? '';
    final isBCA = userEmail.isNotEmpty ? _isBCAEmail(userEmail) : false;
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    if (!docSnapshot.exists) {
      // Create new user document
      await userDoc.set({
        'uid': user.uid,
        'email': userEmail,
        'isBCA': isBCA,
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Update existing user document
      await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
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
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign in with email and password
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

  // Sign in anonymously
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

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      StarredTeacherService.reset();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch user data.');
    }
  }

  // Check if current user is BCA
  Future<bool> isCurrentUserBCA() async {
    if (currentUser == null) return false;

    try {
      final userData = await getUserData(currentUser!.uid);
      return userData?['isBCA'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Link anonymous account to email/password
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
        // Update user document with email and BCA status
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

  // Delete current user account
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

  // Handle Firebase Auth exceptions
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
