import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gr0ve/core/services/user_doc_cache.dart';

class GroveUnlockService {
  GroveUnlockService._();

  static final ValueNotifier<bool> isUnlocked = ValueNotifier<bool>(false);
  static const _field = 'grove_unlocked_easter_egg';

  static Future<void> init({Map<String, dynamic>? cachedUserData}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final data = cachedUserData ?? await UserDocCache.get();
      isUnlocked.value = (data?[_field] as bool?) ?? false;
    } catch (_) {}
  }

  static Future<void> unlock() async {
    if (isUnlocked.value) return;
    isUnlocked.value = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          _field: true,
        }, SetOptions(merge: true));
        final cached = UserDocCache.getCached();
        if (cached != null) {
          UserDocCache.update({...cached, _field: true});
        }
      } catch (_) {}
    }
  }
}
