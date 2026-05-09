import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Singleton cache for the user's Firestore document.
///
/// During boot, multiple services (CounselorPersona, ProfilePicture,
/// DawnUnlock, NavigationPersistence, onboarding checks) all independently
/// read `users/{uid}`. Each read opens a new gRPC stream on cold start,
/// costing ~100–300ms each. By reading once and sharing, we cut 4–5
/// sequential round-trips down to 1.
class UserDocCache {
  UserDocCache._();

  static Map<String, dynamic>? _data;
  static String? _cachedUid;
  static bool _loading = false;

  /// Returns the cached user document data, fetching it if necessary.
  /// Returns null if the user is not authenticated.
  static Future<Map<String, dynamic>?> get() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // If we already have data for this user, return it
    if (_data != null && _cachedUid == user.uid) return _data;

    // Prevent duplicate fetches if called concurrently
    if (_loading && _cachedUid == user.uid) {
      // Wait for the existing fetch to complete
      while (_loading) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return _data;
    }

    _loading = true;
    _cachedUid = user.uid;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      _data = doc.data();
      if (kDebugMode) {
        print('[UserDocCache] Fetched user doc (${_data?.keys.length ?? 0} fields)');
      }
    } catch (e) {
      if (kDebugMode) print('[UserDocCache] Error fetching user doc: $e');
      _data = null;
    } finally {
      _loading = false;
    }

    return _data;
  }

  /// Invalidate the cache (call on logout or when the user doc is updated).
  static void invalidate() {
    _data = null;
    _cachedUid = null;
  }

  /// Get data synchronously if already cached (returns null if not yet fetched).
  static Map<String, dynamic>? getCached() => _data;
}
