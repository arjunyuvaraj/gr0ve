import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StarredBusService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  static final ValueNotifier<Set<String>> starredTowns = ValueNotifier(
    <String>{},
  );

  static bool _loaded = false;

  static DocumentReference<Map<String, dynamic>> _docRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('starredTowns');
  }

  static Future<void> load() async {
    if (_loaded) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _docRef(user.uid).get();

    if (doc.exists) {
      final data = doc.data();
      final List<dynamic>? towns = data?['towns'];
      if (towns != null) {
        starredTowns.value = towns.cast<String>().toSet();
      }
    } else {
      await _docRef(user.uid).set({'towns': []});
      starredTowns.value = {};
    }

    _loaded = true;
  }

  static Future<void> toggleTown(String town) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updated = {...starredTowns.value};

    if (updated.contains(town)) {
      updated.remove(town);
    } else {
      updated.add(town);
    }

    starredTowns.value = updated;

    await _docRef(
      user.uid,
    ).set({'towns': updated.toList()}, SetOptions(merge: true));
  }

  static bool isStarred(String town) {
    return starredTowns.value.contains(town);
  }

  static void reset() {
    starredTowns.value = {};
    _loaded = false;
  }
}
