// ADD_ADMIN_HELPER.dart
// This is a one-time helper script to add the gr0ve.bca.manager@gmail.com user as a platform admin
// You can run this once when logged in as that user, or manually add to Firestore

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHelper {
  /// Call this method once when logged in as gr0ve.bca.manager@gmail.com
  /// to add the user to the admins collection
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

  /// Manually add a user as admin by their UID
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

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}

/* 
USAGE:

Option 1 - From a button in your app (recommended):
----------------------------------------
ElevatedButton(
  onPressed: () async {
    await AdminHelper.addCurrentUserAsAdmin();
    // Then restart the app or navigate back to home
  },
  child: Text('Make Me Admin'),
)


Option 2 - From initState or main.dart:
----------------------------------------
void initState() {
  super.initState();
  AdminHelper.addCurrentUserAsAdmin(); // Run once
}


Option 3 - Manually in Firebase Console:
----------------------------------------
1. Go to Firebase Console → Firestore Database
2. Create a collection called "admins"
3. Add a document with the user's UID as the document ID
4. Add fields:
   - email: "gr0ve.bca.manager@gmail.com"
   - role: "platform_admin"
   - addedAt: (timestamp) now


SECURITY RULES:
---------------
Make sure to update your Firestore security rules:

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admins collection
    match /admins/{userId} {
      allow read: if request.auth != null;
      allow write: if false; // Only create manually or through admin panel
    }
  }
}
*/
