import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin status is granted exclusively server-side (Admin SDK / Firebase
/// console / a trusted Cloud Function) by writing to `platformAdmins/{uid}`.
/// The Firestore rules for that collection are `allow write: if false`, so
/// no client — including this one — can ever grant admin from the app.
///
/// The old `addCurrentUserAsAdmin` / `addAdminByUid` methods wrote to a
/// different, unprotected collection (`admins`) that the security rules
/// never covered, which meant the "is this the manager account" check below
/// was the *only* thing standing between any signed-in user and admin
/// privileges — and it was trivially bypassable by writing to Firestore
/// directly instead of going through this class. They've been removed
/// rather than fixed, because a client should never be the source of truth
/// for who is an admin. If you need to grant an admin, do it from a Cloud
/// Function or the Firebase console.
class AdminHelper {
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('platformAdmins')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
