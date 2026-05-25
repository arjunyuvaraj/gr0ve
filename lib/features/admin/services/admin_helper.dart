import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHelper {
  static Future<void> addCurrentUserAsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ No user is logged in');
      return;
    }

    if (user.email != 'gr0ve.bca.manager@gmail.com') {
      print('❌ Current user is not the manager account');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).set({
        'email': user.email,
        'role': 'platform_admin',
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully added ${user.email} as platform admin');
      print('   User ID: ${user.uid}');
    } catch (e) {
      print('❌ Error adding admin: $e');
    }
  }

  static Future<void> addAdminByUid(String uid, String email) async {
    try {
      await FirebaseFirestore.instance.collection('admins').doc(uid).set({
        'email': email,
        'role': 'platform_admin',
        'addedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Successfully added $email as platform admin');
    } catch (e) {
      print('❌ Error adding admin: $e');
    }
  }

  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      final isManagerEmail = user.email == 'gr0ve.bca.manager@gmail.com';
      return doc.exists || isManagerEmail;
    } catch (e) {
      final isManagerEmail = user.email == 'gr0ve.bca.manager@gmail.com';
      if (isManagerEmail) return true;
      print('Error checking admin status: $e');
      return false;
    }
  }
}
