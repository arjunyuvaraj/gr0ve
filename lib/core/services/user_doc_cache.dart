import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserDocCache {
  UserDocCache._();

  static Map<String, dynamic>? _data;
  static String? _cachedUid;
  static bool _loading = false;

  static Future<Map<String, dynamic>?> get() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (_data != null && _cachedUid == user.uid) return _data;

    if (_loading && _cachedUid == user.uid) {
      int attempts = 0;
      while (_loading && attempts < 500) {
        await Future.delayed(const Duration(milliseconds: 10));
        attempts++;
      }
      return _data;
    }

    _loading = true;
    _cachedUid = user.uid;

    try {
      try {
        final cacheDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 500));

        if (cacheDoc.exists) {
          _data = cacheDoc.data();
          if (kDebugMode) print('[UserDocCache] Using CACHE data');
          return _data;
        }
      } catch (_) {}

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      _data = doc.data();
      if (kDebugMode) {
        print(
          '[UserDocCache] Fetched user doc (${_data?.keys.length ?? 0} fields)',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[UserDocCache] Error fetching user doc: $e');
    } finally {
      _loading = false;
    }

    return _data;
  }

  static void invalidate() {
    _data = null;
    _cachedUid = null;
  }

  static void update(Map<String, dynamic> newData) {
    _data = newData;
    _cachedUid = FirebaseAuth.instance.currentUser?.uid;
  }

  static Map<String, dynamic>? getCached() => _data;
}
