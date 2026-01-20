import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/join_request.dart';
import '../models/announcement.dart';
import '../models/group_creation_request.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Platform admin email
  static const String platformAdminEmail = 'gr0ve.bca.manager@gmail.com';

  // ========== PLATFORM ADMIN OPERATIONS ==========

  /// Check if current user is platform admin
  Future<bool> isPlatformAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('platformAdmins')
          .doc(user.uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get the user's primary club (Phase 1: first active club membership)
  Future<Group?> getUserClub() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Get all active club-type groups
    final groupsSnapshot = await _firestore
        .collection('groups')
        .where('status', isEqualTo: 'active')
        .where('type', isEqualTo: GroupType.club.toJson())
        .get();

    for (final doc in groupsSnapshot.docs) {
      final memberDoc = await _firestore
          .collection('groups')
          .doc(doc.id)
          .collection('members')
          .doc(user.uid)
          .get();

      if (memberDoc.exists) {
        return Group.fromFirestore(doc);
      }
    }

    return null;
  }

  /// Get all pending group creation requests (platform admin only)
  Stream<List<GroupCreationRequest>> getPendingCreationRequests() {
    return _firestore
        .collection('groupCreationRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupCreationRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Approve group creation request and create the group (platform admin only)
  Future<void> approveGroupCreation(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final request = await _firestore
        .collection('groupCreationRequests')
        .doc(requestId)
        .get();

    if (!request.exists) throw Exception('Request not found');

    final requestData = GroupCreationRequest.fromFirestore(request);

    // Create the group
    final groupRef = await _firestore.collection('groups').add({
      'name': requestData.groupName,
      'description': requestData.description,
      'type': requestData.type,
      'status': 'active',
      'joinCode': _generateJoinCode(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': requestData.requesterId,
      'adminIds': [requestData.requesterId],
      'metadata': requestData.metadata,
    });

    // Add the requester as the first admin member
    await _firestore
        .collection('groups')
        .doc(groupRef.id)
        .collection('members')
        .doc(requestData.requesterId)
        .set({
          'userId': requestData.requesterId,
          'displayName': requestData.requesterName,
          'email': requestData.requesterEmail,
          'role': 'admin',
          'joinedAt': FieldValue.serverTimestamp(),
          'addedBy': user.uid,
        });

    // Update the request status
    await _firestore.collection('groupCreationRequests').doc(requestId).update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': user.uid,
    });
  }

  /// Reject group creation request (platform admin only)
  Future<void> rejectGroupCreation(String requestId, String reason) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _firestore.collection('groupCreationRequests').doc(requestId).update({
      'status': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': user.uid,
      'rejectionReason': reason,
    });
  }

  /// Delete entire group (platform admin only)
  Future<void> deleteGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Delete all subcollections first
    final batch = _firestore.batch();

    // Delete members
    final members = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .get();
    for (var doc in members.docs) {
      batch.delete(doc.reference);
    }

    // Delete join requests
    final requests = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .get();
    for (var doc in requests.docs) {
      batch.delete(doc.reference);
    }

    // Delete announcements
    final announcements = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .get();
    for (var doc in announcements.docs) {
      batch.delete(doc.reference);
    }

    // Delete the group
    batch.delete(_firestore.collection('groups').doc(groupId));

    await batch.commit();
  }
  // ------------------------- MOD/ADMIN OPERATIONS -------------------------

  /// Promote a member to moderator (admin only)
  Future<void> makeModerator(String groupId, String memberId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    final isAdmin = group.isAdmin(user.uid);
    if (!isAdmin) throw Exception('Not authorized');

    if (group.isAdmin(memberId)) {
      throw Exception('Cannot make an admin a moderator');
    }

    final memberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId);

    final memberDoc = await memberRef.get();
    if (!memberDoc.exists) throw Exception('Member not found');

    await memberRef.update({'role': 'moderator'});
  }

  /// Remove moderator status (admin only)
  Future<void> removeModerator(String groupId, String memberId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    final isAdmin = group.isAdmin(user.uid);
    if (!isAdmin) throw Exception('Not authorized');

    final memberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId);

    final memberDoc = await memberRef.get();
    if (!memberDoc.exists) throw Exception('Member not found');

    final role = memberDoc.get('role');
    if (role != 'moderator') {
      throw Exception('Member is not a moderator');
    }

    await memberRef.update({'role': 'member'});
  }

  /// Promote member to admin (original admin only)
  Future<void> makeAdmin(String groupId, String memberId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    // Only the first creator/admin can promote others to admin
    if (group.adminIds.isEmpty || group.adminIds.first != user.uid) {
      throw Exception('Only original admin can promote to admin');
    }

    final memberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId);

    final memberDoc = await memberRef.get();
    if (!memberDoc.exists) throw Exception('Member not found');

    await memberRef.update({'role': 'admin'});

    // Update group's adminIds
    final updatedAdmins = List<String>.from(group.adminIds);
    if (!updatedAdmins.contains(memberId)) updatedAdmins.add(memberId);

    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': updatedAdmins,
    });
  }

  /// Remove admin status (original admin cannot remove themselves)
  Future<void> removeAdmin(String groupId, String memberId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    final isOriginalAdmin =
        group.adminIds.isNotEmpty && group.adminIds.first == memberId;
    if (isOriginalAdmin) throw Exception('Cannot remove the original admin');

    final isRequesterOriginalAdmin = group.adminIds.first == user.uid;
    if (!isRequesterOriginalAdmin)
      throw Exception('Only original admin can remove other admins');

    final memberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId);

    final memberDoc = await memberRef.get();
    if (!memberDoc.exists) throw Exception('Member not found');

    final role = memberDoc.get('role');
    if (role != 'admin') {
      throw Exception('Member is not an admin');
    }

    await memberRef.update({'role': 'member'});

    // Update group's adminIds
    final updatedAdmins = List<String>.from(group.adminIds)..remove(memberId);
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': updatedAdmins,
    });
  }

  /// Remove member with rules:
  /// - Admins can remove anyone except the original admin (first creator)
  /// - Mods can remove themselves
  /// - Members cannot remove anyone else
  Future<void> removeMember(String groupId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    final memberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId);

    final memberDoc = await memberRef.get();
    if (!memberDoc.exists) throw Exception('Member not found');

    final role = memberDoc.get('role') ?? 'member';

    final isRequesterAdmin = group.isAdmin(user.uid);
    final isRequesterMod =
        !isRequesterAdmin &&
        role == 'moderator' &&
        user.uid == userId; // can remove self
    final isSelf = user.uid == userId;

    // Cannot remove original admin
    final isOriginalAdmin =
        group.adminIds.isNotEmpty && group.adminIds.first == userId;
    if (isOriginalAdmin) throw Exception('Cannot remove the original admin');

    if (!isRequesterAdmin && !(isRequesterMod && isSelf)) {
      throw Exception('Not authorized to remove this member');
    }

    await memberRef.delete();

    // Remove from adminIds if needed
    if (role == 'admin') {
      final updatedAdmins = List<String>.from(group.adminIds)..remove(userId);
      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': updatedAdmins,
      });
    }
  }

  // ========== USER OPERATIONS ==========

  /// Request to create a new group (club in Phase 1)
  Future<void> requestGroupCreation({
    required String name,
    required String description,
    String type = 'club',
    Map<String, dynamic> metadata = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _firestore.collection('groupCreationRequests').add({
      'requesterId': user.uid,
      'requesterName': user.displayName ?? 'Unknown',
      'requesterEmail': user.email ?? '',
      'groupName': name,
      'description': description,
      'type': type,
      'metadata': metadata,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': null,
      'rejectionReason': null,
    });
  }

  /// Get user's creation requests
  Stream<List<GroupCreationRequest>> getUserCreationRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('groupCreationRequests')
        .where('requesterId', isEqualTo: user.uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupCreationRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get all active groups (filtered by type if needed)
  Stream<List<Group>> getActiveGroups({GroupType? type}) {
    Query query = _firestore
        .collection('groups')
        .where('status', isEqualTo: 'active');

    if (type != null) {
      query = query.where('type', isEqualTo: type.toJson());
    }

    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList(),
    );
  }

  /// Get groups where user is a member
  Stream<List<Group>> getUserGroups({GroupType? type}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return getActiveGroups(type: type).asyncMap((groups) async {
      final userGroups = <Group>[];
      for (var group in groups) {
        final isMember = await _firestore
            .collection('groups')
            .doc(group.id)
            .collection('members')
            .doc(user.uid)
            .get()
            .then((doc) => doc.exists);
        if (isMember) {
          userGroups.add(group);
        }
      }
      return userGroups;
    });
  }

  /// Get single group by ID
  Future<Group?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return Group.fromFirestore(doc);
  }

  /// Get group by join code
  Future<Group?> getGroupByJoinCode(String joinCode) async {
    final query = await _firestore
        .collection('groups')
        .where('joinCode', isEqualTo: joinCode.toUpperCase())
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return Group.fromFirestore(query.docs.first);
  }

  /// Check if user is admin of a group
  Future<bool> isGroupAdmin(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final group = await getGroup(groupId);
    return group?.isAdmin(user.uid) ?? false;
  }

  /// Check if user is member of a group
  Future<bool> isGroupMember(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  // ========== JOIN CODE & JOIN REQUEST OPERATIONS ==========

  /// Generate a new 6-character join code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Regenerate join code (admin only)
  Future<void> regenerateJoinCode(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore.collection('groups').doc(groupId).update({
      'joinCode': _generateJoinCode(),
    });
  }

  /// Request to join a group using join code
  Future<void> requestToJoin(String joinCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroupByJoinCode(joinCode);
    if (group == null) throw Exception('Invalid join code');

    // Check if already a member
    final isMember = await isGroupMember(group.id);
    if (isMember) throw Exception('Already a member of this group');

    // Check if already has a pending request
    final existingRequest = await _firestore
        .collection('groups')
        .doc(group.id)
        .collection('joinRequests')
        .doc(user.uid)
        .get();

    if (existingRequest.exists) {
      final request = JoinRequest.fromFirestore(existingRequest);
      if (request.isPending) {
        throw Exception('You already have a pending request for this group');
      }
    }

    // Create join request
    await _firestore
        .collection('groups')
        .doc(group.id)
        .collection('joinRequests')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'displayName': user.displayName ?? 'Unknown',
          'email': user.email ?? '',
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'joinCode': joinCode.toUpperCase(),
        });
  }

  /// Get pending join requests for a group (admin only)
  Stream<List<JoinRequest>> getPendingJoinRequests(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => JoinRequest.fromFirestore(doc))
              .toList(),
        );
  }

  /// Approve join request (admin only)
  Future<void> approveJoinRequest(String groupId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    final requestDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(userId)
        .get();

    if (!requestDoc.exists) throw Exception('Request not found');

    final request = JoinRequest.fromFirestore(requestDoc);

    // Add as member
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .set({
          'userId': userId,
          'displayName': request.displayName,
          'email': request.email,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'addedBy': user.uid,
        });

    // Update request status
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(userId)
        .update({'status': 'approved'});
  }

  /// Reject join request (admin only)
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(userId)
        .update({'status': 'rejected'});
  }

  // ========== MEMBER OPERATIONS ==========

  /// Get all members of a group
  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GroupMember.fromFirestore(doc))
              .toList(),
        );
  }

  /// Remove member from group (admin only, or self)

  /// Leave group (convenience method for current user)
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await removeMember(groupId, user.uid);
  }

  // ========== ANNOUNCEMENT OPERATIONS ==========

  /// Get announcements for a group
  Stream<List<Announcement>> getAnnouncements(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Announcement.fromFirestore(doc))
              .toList(),
        );
  }

  /// Post announcement (admin only)
  Future<void> postAnnouncement({
    required String groupId,
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .add({
          'title': title,
          'content': content,
          'authorId': user.uid,
          'authorName': user.displayName ?? 'Unknown',
          'createdAt': FieldValue.serverTimestamp(),
          'isPinned': isPinned,
        });
  }

  /// Delete announcement (admin only)
  Future<void> deleteAnnouncement(String groupId, String announcementId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }

  /// Toggle pin status (admin only)
  Future<void> toggleAnnouncementPin(
    String groupId,
    String announcementId,
    bool isPinned,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .update({'isPinned': isPinned});
  }
}
