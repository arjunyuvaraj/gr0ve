import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StarredTeacherService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static final ValueNotifier<Set<String>> starredTeachers = ValueNotifier(
    <String>{},
  );

  static bool _loaded = false;

  static DocumentReference<Map<String, dynamic>> _docRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('starredTeachers');
  }

  static Future<void> load() async {
    if (_loaded) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _docRef(user.uid).get();

    if (doc.exists) {
      final data = doc.data();
      final List<dynamic>? teachers = data?['teachers'];
      if (teachers != null) {
        starredTeachers.value = teachers.cast<String>().toSet();
      }
    } else {
      await _docRef(user.uid).set({'teachers': []});
      starredTeachers.value = {};
    }

    _loaded = true;
  }

  static Future<void> toggleTeacher(String fullName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = {...starredTeachers.value};

    if (updated.contains(fullName)) {
      updated.remove(fullName);
    } else {
      updated.add(fullName);
    }

    starredTeachers.value = updated;

    await _docRef(
      user.uid,
    ).set({'teachers': updated.toList()}, SetOptions(merge: true));
  }

  static bool isStarred(String name) {
    return starredTeachers.value.contains(name);
  }

  static void reset() {
    starredTeachers.value = {};
    _loaded = false;
  }
}
