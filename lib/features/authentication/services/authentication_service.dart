import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gr0ve/services/starred/starred_teacher_service.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  bool _isBCAEmail(String email) {
    return email.toLowerCase().endsWith('@bergen.org');
  }

  Future<void> _createUserDocument(
    User user, {
    String? email,
    String? displayName,
  }) async {
    final userEmail = email ?? user.email ?? '';
    final isBCA = userEmail.isNotEmpty ? _isBCAEmail(userEmail) : false;
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get().timeout(
      const Duration(seconds: 10),
    );

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': userEmail,
        'displayName': displayName ?? user.displayName ?? '',
        'isBCA': isBCA,
        'isAnonymous': user.isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.update({'lastLoginAt': FieldValue.serverTimestamp()});
    }
  }

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
        // Update display name first so _createUserDocument can read it.
        await userCredential.user?.updateDisplayName(name);
        try {
          await _createUserDocument(
            userCredential.user!,
            email: trimmedEmail,
            displayName: name,
          );
        } catch (firestoreError) {
          // Document creation failed (e.g. rules / network), but the Auth
          // account already exists. Log and continue — do NOT block the user.
          print('[AuthService] Warning: failed to create user document: $firestoreError');
        }
        await userCredential.user?.reload();
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

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
        try {
          await _createUserDocument(
            userCredential.user!,
            email: trimmedEmail,
          );
        } catch (firestoreError) {
          print('[AuthService] Warning: failed to update user document on login: $firestoreError');
        }
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
      StarredTeacherService.reset();

      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to send reset email. Please try again.');
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch user data.');
    }
  }

  Future<bool> isCurrentUserBCA() async {
    if (currentUser == null) return false;

    try {
      final userData = await getUserData(currentUser!.uid);
      return userData?['isBCA'] ?? false;
    } catch (e) {
      return false;
    }
  }

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

  Future<void> deleteAccount(String password) async {
    if (currentUser == null) return;

    try {
      final uid = currentUser!.uid;
      final email = currentUser!.email!;

      try {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await currentUser!.reauthenticateWithCredential(credential);
      } catch (e) {
        throw Exception('Failed to verify password: ${e.toString()}');
      }

      await _firestore.collection('users').doc(uid).delete();

      await currentUser!.delete();

      signOut();
    } catch (e) {
      throw Exception(
        'Failed to delete account. Please try again.' + e.toString(),
      );
    }
  }

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
