import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group.dart';
import 'group_member.dart';
import '../../models/join_request.dart';
import '../../models/announcement.dart';
import 'group_creation_request.dart';

// SERVICE: Manages group creation, membership, and administration
class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Platform admin email
  static const String platformAdminEmail = 'gr0ve.bca.manager@gmail.com';

  // ========== PROFILE SYNC OPERATIONS ==========

  // METHOD: Helper to sync a single member's data from Firebase Auth
  Future<void> _syncMemberDataFromAuth(String groupId, String userId) async {
    // Get the user's current profile from a users collection or Auth
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final displayName = userData['displayName'] ?? '';
      final email = userData['email'] ?? '';

      // Update member in this group
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .update({'displayName': displayName, 'email': email});
    }
  }

  // METHOD: Sync user profile across all groups they're a member of
  // LOGIC: Handles Firestore batch limits (sets of 450 to be safe)
  Future<void> syncUserProfileAcrossGroups({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    // Get all groups
    final groupsSnapshot = await _firestore.collection('groups').get();

    final batch = _firestore.batch();
    int operationCount = 0;

    for (final groupDoc in groupsSnapshot.docs) {
      // Check if user is a member of this group
      final memberRef = _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('members')
          .doc(userId);

      final memberDoc = await memberRef.get();
      if (memberDoc.exists) {
        // Update member info
        batch.update(memberRef, {'displayName': displayName, 'email': email});
        operationCount++;

        // If we're approaching the 500 operation limit, commit and start new batch
        if (operationCount >= 450) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Also update join requests if any exist
      final joinRequestRef = _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('joinRequests')
          .doc(userId);

      final joinRequestDoc = await joinRequestRef.get();
      if (joinRequestDoc.exists) {
        batch.update(joinRequestRef, {
          'displayName': displayName,
          'email': email,
        });
        operationCount++;

        if (operationCount >= 450) {
          await batch.commit();
          operationCount = 0;
        }
      }
    }

    // Commit any remaining operations
    if (operationCount > 0) {
      await batch.commit();
    }

    // Also update announcements where user is author
    await _syncAnnouncementAuthorInfo(userId, displayName);

    // Update group creation requests
    final creationRequestsSnapshot = await _firestore
        .collection('groupCreationRequests')
        .where('requesterId', isEqualTo: userId)
        .get();

    if (creationRequestsSnapshot.docs.isNotEmpty) {
      final updateBatch = _firestore.batch();
      for (final doc in creationRequestsSnapshot.docs) {
        updateBatch.update(doc.reference, {
          'requesterName': displayName,
          'requesterEmail': email,
        });
      }
      await updateBatch.commit();
    }
  }

  // METHOD: Helper to sync announcement author info across all groups
  Future<void> _syncAnnouncementAuthorInfo(
    String userId,
    String displayName,
  ) async {
    final groupsSnapshot = await _firestore.collection('groups').get();

    for (final groupDoc in groupsSnapshot.docs) {
      final announcementsSnapshot = await _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('announcements')
          .where('authorId', isEqualTo: userId)
          .get();

      if (announcementsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final announcementDoc in announcementsSnapshot.docs) {
          batch.update(announcementDoc.reference, {'authorName': displayName});
        }
        await batch.commit();
      }
    }
  }

  // ========== PLATFORM ADMIN OPERATIONS ==========

  // METHOD: Check if current user is platform admin
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

  // METHOD: Get the user's primary club (Phase 1: first active club membership)
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

  // METHOD: Get all pending group creation requests (platform admin only)
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

  // METHOD: Approve group creation request and create the group (platform admin only)
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
          'role': MemberRole.admin.toJson(),
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

  // METHOD: Reject group creation request (platform admin only)
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

  // METHOD: Delete entire group and subcollections (platform admin only)
  // LOGIC: Deletes all subcollections manually before deleting group doc
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

  // METHOD: Promote a member to moderator (admin only)
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

    await memberRef.update({'role': MemberRole.moderator.toJson()});

    // Reload member data to sync with user profile
    await _syncMemberDataFromAuth(groupId, memberId);
  }

  // METHOD: Remove moderator status (admin only)
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

    final roleStr = memberDoc.get('role');
    final role = MemberRole.fromJson(roleStr);
    if (role != MemberRole.moderator) {
      throw Exception('Member is not a moderator');
    }

    await memberRef.update({'role': MemberRole.member.toJson()});
  }

  // METHOD: Promote member to admin (original admin only)
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

    await memberRef.update({'role': MemberRole.admin.toJson()});

    // Update group's adminIds
    final updatedAdmins = List<String>.from(group.adminIds);
    if (!updatedAdmins.contains(memberId)) updatedAdmins.add(memberId);

    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': updatedAdmins,
    });
  }

  // METHOD: Remove admin status (original admin cannot remove themselves)
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

    final roleStr = memberDoc.get('role');
    final role = MemberRole.fromJson(roleStr);
    if (role != MemberRole.admin) {
      throw Exception('Member is not an admin');
    }

    await memberRef.update({'role': MemberRole.member.toJson()});

    // Update group's adminIds
    final updatedAdmins = List<String>.from(group.adminIds)..remove(memberId);
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': updatedAdmins,
    });
  }

  // METHOD: Remove member with permission checks
  // LOGIC: Enforces hierarchy: Admin > Mod > Member. Original Admin > All.
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

    final targetRoleStr = memberDoc.get('role') ?? 'member';
    final targetRole = MemberRole.fromJson(targetRoleStr);

    final requesterMemberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid);

    final requesterDoc = await requesterMemberRef.get();
    final requesterRoleStr = requesterDoc.exists
        ? (requesterDoc.get('role') ?? 'member')
        : 'member';
    final requesterRole = MemberRole.fromJson(requesterRoleStr);

    final isRequesterAdmin = group.isAdmin(user.uid);
    final isRequesterMod = requesterRole == MemberRole.moderator;
    final isSelf = user.uid == userId;

    // Cannot remove original admin
    final isOriginalAdmin =
        group.adminIds.isNotEmpty && group.adminIds.first == userId;
    if (isOriginalAdmin) throw Exception('Cannot remove the original admin');

    // Permission checks:
    // - Admins can remove anyone (except original admin)
    // - Mods can only remove regular members or themselves
    // - Members can only remove themselves
    if (!isRequesterAdmin) {
      if (isRequesterMod) {
        // Mods can only remove regular members or themselves
        if (targetRole != MemberRole.member && !isSelf) {
          throw Exception('Moderators can only remove regular members');
        }
      } else {
        // Regular members can only remove themselves
        if (!isSelf) {
          throw Exception('Not authorized to remove this member');
        }
      }
    }

    await memberRef.delete();

    // Remove from adminIds if needed
    if (targetRole == MemberRole.admin) {
      final updatedAdmins = List<String>.from(group.adminIds)..remove(userId);
      await _firestore.collection('groups').doc(groupId).update({
        'adminIds': updatedAdmins,
      });
    }
  }

  // ========== USER OPERATIONS ==========

  // METHOD: Request to create a new group (club in Phase 1)
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

  // METHOD: Get user's creation requests
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

  // METHOD: Get all active groups (filtered by type if needed)
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

  // METHOD: Get groups where user is a member
  // LOGIC: Performs client-side filtering of group membership.
  // OPTIMIZE: Consider denormalizing 'memberIds' array in group doc for efficient querying if groups are small.
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

  // METHOD: Get single group by ID
  Future<Group?> getGroup(String groupId) async {
    final doc = await _firestore.collection('groups').doc(groupId).get();
    if (!doc.exists) return null;
    return Group.fromFirestore(doc);
  }

  // METHOD: Get group by join code
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

  // METHOD: Check if user is admin of a group
  Future<bool> isGroupAdmin(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final group = await getGroup(groupId);
    return group?.isAdmin(user.uid) ?? false;
  }

  // METHOD: Check if user is moderator or admin of a group
  Future<bool> isGroupModOrAdmin(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final roleStr = doc.get('role') ?? 'member';
    final role = MemberRole.fromJson(roleStr);
    return role == MemberRole.admin || role == MemberRole.moderator;
  }

  // METHOD: Check if user is member of a group
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

  // METHOD: Generate a new 6-character join code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // METHOD: Regenerate join code (admin only)
  Future<void> regenerateJoinCode(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore.collection('groups').doc(groupId).update({
      'joinCode': _generateJoinCode(),
    });
  }

  // METHOD: Request to join a group using join code
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

  // METHOD: Get pending join requests for a group (admin or moderator)
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

  // METHOD: Approve join request (admin or moderator)
  Future<void> approveJoinRequest(String groupId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isModOrAdmin = await isGroupModOrAdmin(groupId);
    if (!isModOrAdmin) throw Exception('Not authorized');

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
          'role': MemberRole.member.toJson(),
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

  // METHOD: Reject join request (admin or moderator)
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isModOrAdmin = await isGroupModOrAdmin(groupId);
    if (!isModOrAdmin) throw Exception('Not authorized');

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .doc(userId)
        .update({'status': 'rejected'});
  }

  // ========== MEMBER OPERATIONS ==========

  // METHOD: Get all members of a group
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

  // METHOD: Leave group (convenience method for current user)
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await removeMember(groupId, user.uid);
  }

  // ========== ANNOUNCEMENT OPERATIONS ==========

  // METHOD: Get announcements for a group
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

  // METHOD: Post announcement (admin or moderator)
  Future<void> postAnnouncement({
    required String groupId,
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isModOrAdmin = await isGroupModOrAdmin(groupId);
    if (!isModOrAdmin) throw Exception('Not authorized');

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

  // METHOD: Delete announcement (admin only)
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

  // METHOD: Toggle pin status (admin only)
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
