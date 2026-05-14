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
      // Wait for the existing fetch to complete (max 5 seconds)
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
      // 1. Try to get from CACHE first with a very short timeout (500ms)
      // This ensures we show data instantly if available offline
      try {
        final cacheDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(milliseconds: 500));
        
        if (cacheDoc.exists) {
          _data = cacheDoc.data();
          if (kDebugMode) print('[UserDocCache] Using CACHE data');
          // We return here to be fast, but we'll kick off a network refresh in the background
          _refreshFromNetwork(user.uid);
          return _data;
        }
      } catch (_) {
        // Ignore cache misses/timeouts and proceed to network
      }

      // 2. If no cache, try NETWORK with 10s timeout
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      _data = doc.data();
      if (kDebugMode) {
        print('[UserDocCache] Fetched user doc (${_data?.keys.length ?? 0} fields)');
      }
    } catch (e) {
      if (kDebugMode) print('[UserDocCache] Error fetching user doc: $e');
      // If network fails, we don't clear _data if we already got it from cache
    } finally {
      _loading = false;
    }

    return _data;
  }

  /// Refreshes the cache in the background without blocking the UI
  static void _refreshFromNetwork(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server))
        .then((doc) {
          if (doc.exists) {
            _data = doc.data();
            if (kDebugMode) print('[UserDocCache] Background refresh complete');
          }
        })
        .catchError((e) {
          if (kDebugMode) print('[UserDocCache] Background refresh failed: $e');
        });
  }

  /// Invalidate the cache (call on logout or when the user doc is updated).
  static void invalidate() {
    _data = null;
    _cachedUid = null;
  }

  /// Manually update the cache with new data (e.g. after a local update).
  static void update(Map<String, dynamic> newData) {
    _data = newData;
    _cachedUid = FirebaseAuth.instance.currentUser?.uid;
  }

  /// Get data synchronously if already cached (returns null if not yet fetched).
  static Map<String, dynamic>? getCached() => _data;
}
