import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUid => _auth.currentUser?.uid;

  // Follow a user (Single direction)
  static Future<void> followUser(String targetUid) async {
    final uid = currentUid;
    if (uid == null || uid == targetUid) return;

    final batch = _firestore.batch();

    // Add to my following
    batch.set(
      _firestore.collection('users').doc(uid).collection('following').doc(targetUid),
      {'timestamp': FieldValue.serverTimestamp()},
    );

    // Add to their followers
    batch.set(
      _firestore.collection('users').doc(targetUid).collection('followers').doc(uid),
      {'timestamp': FieldValue.serverTimestamp()},
    );

    await batch.commit();
  }

  // Unfollow a user
  static Future<void> unfollowUser(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return;

    final batch = _firestore.batch();

    batch.delete(
      _firestore.collection('users').doc(uid).collection('following').doc(targetUid),
    );
    batch.delete(
      _firestore.collection('users').doc(targetUid).collection('followers').doc(uid),
    );

    await batch.commit();
  }

  // Stream of mutual friends' UIDs
  static Stream<List<String>> getMutualFriendUids() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnap) async {
      final followingUids = followingSnap.docs.map((d) => d.id).toSet();
      
      final followersSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('followers')
          .get();
      
      final followersUids = followersSnap.docs.map((d) => d.id).toSet();

      // Intersection = Mutual
      return followingUids.intersection(followersUids).toList();
    });
  }

  // Search users by name or email
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // Search by displayName
    final nameSnapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: cleanQuery)
        .where('displayName', isLessThanOrEqualTo: '$cleanQuery\uf8ff')
        .limit(10)
        .get();

    // Search by email
    final emailSnapshot = await _firestore
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: cleanQuery.toLowerCase())
        .where('email', isLessThanOrEqualTo: '${cleanQuery.toLowerCase()}\uf8ff')
        .limit(10)
        .get();

    final results = <String, Map<String, dynamic>>{};

    for (var doc in nameSnapshot.docs) {
      if (doc.id != currentUid) {
        results[doc.id] = {'uid': doc.id, ...doc.data()};
      }
    }

    for (var doc in emailSnapshot.docs) {
      if (doc.id != currentUid) {
        results[doc.id] = {'uid': doc.id, ...doc.data()};
      }
    }

    return results.values.toList();
  }
}
