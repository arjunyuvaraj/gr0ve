import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gr0ve/models/announcement_question.dart';
import 'package:gr0ve/models/group.dart';
import 'package:gr0ve/models/group_member.dart';
import 'package:gr0ve/models/join_request.dart';
import 'package:gr0ve/models/announcement.dart';
import 'package:gr0ve/models/group_creation_request.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String platformAdminEmail = 'gr0ve.bca.manager@gmail.com';

  Future<void> _syncMemberDataFromAuth(String groupId, String userId) async {
    final userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get()
        .timeout(const Duration(seconds: 5));

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final displayName = userData['displayName'] ?? '';
      final email = userData['email'] ?? '';

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .update({'displayName': displayName, 'email': email});
    }
  }

  Future<void> syncUserProfileAcrossGroups({
    required String userId,
    required String displayName,
    required String email,
  }) async {
    final groupsSnapshot = await _firestore
        .collection('groups')
        .get()
        .timeout(const Duration(seconds: 5));

    final batch = _firestore.batch();
    int operationCount = 0;

    for (final groupDoc in groupsSnapshot.docs) {
      final memberRef = _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('members')
          .doc(userId);

      final memberDoc = await memberRef.get().timeout(
        const Duration(seconds: 5),
      );
      if (memberDoc.exists) {
        batch.update(memberRef, {'displayName': displayName, 'email': email});
        operationCount++;

        if (operationCount >= 450) {
          await batch.commit();
          operationCount = 0;
        }
      }

      final joinRequestRef = _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('joinRequests')
          .doc(userId);

      final joinRequestDoc = await joinRequestRef.get().timeout(
        const Duration(seconds: 5),
      );
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

    if (operationCount > 0) {
      await batch.commit();
    }

    await _syncAnnouncementAuthorInfo(userId, displayName);

    final creationRequestsSnapshot = await _firestore
        .collection('groupCreationRequests')
        .where('requesterId', isEqualTo: userId)
        .get()
        .timeout(const Duration(seconds: 5));

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

  Future<void> _syncAnnouncementAuthorInfo(
    String userId,
    String displayName,
  ) async {
    final groupsSnapshot = await _firestore
        .collection('groups')
        .get()
        .timeout(const Duration(seconds: 5));

    for (final groupDoc in groupsSnapshot.docs) {
      final announcementsSnapshot = await _firestore
          .collection('groups')
          .doc(groupDoc.id)
          .collection('announcements')
          .where('authorId', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (announcementsSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final announcementDoc in announcementsSnapshot.docs) {
          batch.update(announcementDoc.reference, {'authorName': displayName});
        }
        await batch.commit();
      }
    }
  }

  Future<bool> isPlatformAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore
          .collection('platformAdmins')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<Group?> getUserClub() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final groupsSnapshot = await _firestore
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .get()
        .timeout(const Duration(seconds: 5));

    for (final doc in groupsSnapshot.docs) {
      final group = Group.fromFirestore(doc);
      if (group.isActive && group.type == GroupType.club) return group;
    }

    return null;
  }

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

  Future<void> approveGroupCreation(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final request = await _firestore
        .collection('groupCreationRequests')
        .doc(requestId)
        .get()
        .timeout(const Duration(seconds: 5));

    if (!request.exists) throw Exception('Request not found');

    final requestData = GroupCreationRequest.fromFirestore(request);

    final groupRef = await _firestore.collection('groups').add({
      'name': requestData.groupName,
      'description': requestData.description,
      'type': requestData.type,
      'status': 'active',
      'joinCode': _generateJoinCode(),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': requestData.requesterId,
      'adminIds': [requestData.requesterId],
      'memberIds': [requestData.requesterId],
      'metadata': requestData.metadata,
    });

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

    await _firestore.collection('groupCreationRequests').doc(requestId).update({
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': user.uid,
    });
  }

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

  Future<void> deleteGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final batch = _firestore.batch();

    final members = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .get()
        .timeout(const Duration(seconds: 5));
    for (var doc in members.docs) {
      batch.delete(doc.reference);
    }

    final requests = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('joinRequests')
        .get()
        .timeout(const Duration(seconds: 5));
    for (var doc in requests.docs) {
      batch.delete(doc.reference);
    }

    final announcements = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .get()
        .timeout(const Duration(seconds: 5));
    for (var doc in announcements.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection('groups').doc(groupId));

    await batch.commit();
  }

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

    final memberDoc = await memberRef.get().timeout(const Duration(seconds: 5));
    if (!memberDoc.exists) throw Exception('Member not found');

    await memberRef.update({'role': MemberRole.moderator.toJson()});

    await _syncMemberDataFromAuth(groupId, memberId);
  }

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

    final memberDoc = await memberRef.get().timeout(const Duration(seconds: 5));
    if (!memberDoc.exists) throw Exception('Member not found');

    final roleStr = memberDoc.get('role');
    final role = MemberRole.fromJson(roleStr);
    if (role != MemberRole.moderator) {
      throw Exception('Member is not a moderator');
    }

    await memberRef.update({'role': MemberRole.member.toJson()});
  }

  Future<void> makeAdmin(String groupId, String memberId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroup(groupId);
    if (group == null) throw Exception('Group not found');

    if (group.adminIds.isEmpty || group.adminIds.first != user.uid) {
      throw Exception('Only original admin can promote to admin');
    }

    final memberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(memberId);

    final memberDoc = await memberRef.get().timeout(const Duration(seconds: 5));
    if (!memberDoc.exists) throw Exception('Member not found');

    await memberRef.update({'role': MemberRole.admin.toJson()});

    final updatedAdmins = List<String>.from(group.adminIds);
    if (!updatedAdmins.contains(memberId)) updatedAdmins.add(memberId);

    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': updatedAdmins,
    });
  }

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

    final memberDoc = await memberRef.get().timeout(const Duration(seconds: 5));
    if (!memberDoc.exists) throw Exception('Member not found');

    final roleStr = memberDoc.get('role');
    final role = MemberRole.fromJson(roleStr);
    if (role != MemberRole.admin) {
      throw Exception('Member is not an admin');
    }

    await memberRef.update({'role': MemberRole.member.toJson()});

    final updatedAdmins = List<String>.from(group.adminIds)..remove(memberId);
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': updatedAdmins,
    });
  }

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

    final memberDoc = await memberRef.get().timeout(const Duration(seconds: 5));
    if (!memberDoc.exists) throw Exception('Member not found');

    final targetRoleStr = memberDoc.get('role') ?? 'member';
    final targetRole = MemberRole.fromJson(targetRoleStr);

    final requesterMemberRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid);

    final requesterDoc = await requesterMemberRef.get().timeout(
      const Duration(seconds: 5),
    );
    final requesterRoleStr = requesterDoc.exists
        ? (requesterDoc.get('role') ?? 'member')
        : 'member';
    final requesterRole = MemberRole.fromJson(requesterRoleStr);

    final isRequesterAdmin = group.isAdmin(user.uid);
    final isRequesterMod = requesterRole == MemberRole.moderator;
    final isSelf = user.uid == userId;

    final isOriginalAdmin =
        group.adminIds.isNotEmpty && group.adminIds.first == userId;
    if (isOriginalAdmin) throw Exception('Cannot remove the original admin');

    if (!isRequesterAdmin) {
      if (isRequesterMod) {
        if (targetRole != MemberRole.member && !isSelf) {
          throw Exception('Moderators can only remove regular members');
        }
      } else {
        if (!isSelf) {
          throw Exception('Not authorized to remove this member');
        }
      }
    }

    final groupUpdates = <String, dynamic>{
      'memberIds': FieldValue.arrayRemove([userId]),
    };

    if (targetRole == MemberRole.admin) {
      final updatedAdmins = List<String>.from(group.adminIds)..remove(userId);
      groupUpdates['adminIds'] = updatedAdmins;
    }

    final batch = _firestore.batch();
    batch.delete(memberRef);
    batch.update(_firestore.collection('groups').doc(groupId), groupUpdates);
    await batch.commit();
  }

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

  Stream<List<Group>> getUserGroups({GroupType? type}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs.map((doc) => Group.fromFirestore(doc));
          return groups
              .where((group) => group.isActive)
              .where((group) => type == null || group.type == type)
              .toList();
        });
  }

  Future<Group?> getGroup(String groupId) async {
    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .get()
        .timeout(const Duration(seconds: 5));
    if (!doc.exists) return null;
    return Group.fromFirestore(doc);
  }

  Future<Group?> getGroupByJoinCode(String joinCode) async {
    final query = await _firestore
        .collection('groups')
        .where('joinCode', isEqualTo: joinCode.toUpperCase())
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 5));

    if (query.docs.isEmpty) return null;
    return Group.fromFirestore(query.docs.first);
  }

  Future<bool> isGroupAdmin(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final group = await getGroup(groupId);
    return group?.isAdmin(user.uid) ?? false;
  }

  Future<bool> isGroupModOrAdmin(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 5));

    if (!doc.exists) return false;

    final roleStr = doc.get('role') ?? 'member';
    final role = MemberRole.fromJson(roleStr);
    return role == MemberRole.admin || role == MemberRole.moderator;
  }

  Future<bool> isGroupMember(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 5));

    return doc.exists;
  }

  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> regenerateJoinCode(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isAdmin = await isGroupAdmin(groupId);
    if (!isAdmin) throw Exception('Not authorized');

    await _firestore.collection('groups').doc(groupId).update({
      'joinCode': _generateJoinCode(),
    });
  }

  Future<void> requestToJoin(String joinCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final group = await getGroupByJoinCode(joinCode);
    if (group == null) throw Exception('Invalid join code');

    final isMember = await isGroupMember(group.id);
    if (isMember) throw Exception('Already a member of this group');

    final existingRequest = await _firestore
        .collection('groups')
        .doc(group.id)
        .collection('joinRequests')
        .doc(user.uid)
        .get()
        .timeout(const Duration(seconds: 5));

    if (existingRequest.exists) {
      final request = JoinRequest.fromFirestore(existingRequest);
      if (request.isPending) {
        throw Exception('You already have a pending request for this group');
      }
    }

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
        .get()
        .timeout(const Duration(seconds: 5));

    if (!requestDoc.exists) throw Exception('Request not found');

    final request = JoinRequest.fromFirestore(requestDoc);

    final groupRef = _firestore.collection('groups').doc(groupId);
    final batch = _firestore.batch();

    batch.set(groupRef.collection('members').doc(userId), {
      'userId': userId,
      'displayName': request.displayName,
      'email': request.email,
      'role': MemberRole.member.toJson(),
      'joinedAt': FieldValue.serverTimestamp(),
      'addedBy': user.uid,
    });
    batch.update(groupRef, {
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    batch.update(groupRef.collection('joinRequests').doc(userId), {
      'status': 'approved',
    });

    await batch.commit();
  }

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

  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    await removeMember(groupId, user.uid);
  }

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

  Stream<List<AnnouncementQuestion>> getAnnouncementQuestions(
    String groupId,
    String announcementId,
    String currentUserId,
    bool isModOrAdmin,
  ) {
    Query query = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .orderBy('createdAt', descending: true);

    if (!isModOrAdmin) {
      query = query.where('authorId', isEqualTo: currentUserId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => AnnouncementQuestion.fromFirestore(doc))
          .toList(),
    );
  }

  Stream<int> getUnansweredQuestionCount(
    String groupId,
    String announcementId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .where('isAnswered', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<List<QuestionReply>> getQuestionReplies(
    String groupId,
    String announcementId,
    String questionId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .doc(questionId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => QuestionReply.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> postQuestion({
    required String groupId,
    required String announcementId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isMember = await isGroupMember(groupId);
    if (!isMember) throw Exception('Not a member of this group');

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .add({
          'groupId': groupId,
          'announcementId': announcementId,
          'authorId': user.uid,
          'authorName': user.displayName ?? 'Unknown',
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
          'isAnswered': false,
        });
  }

  Future<void> replyToQuestion({
    required String groupId,
    required String announcementId,
    required String questionId,
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isModOrAdmin = await isGroupModOrAdmin(groupId);
    final isMember = await isGroupMember(groupId);
    if (!isMember) throw Exception('Not a member of this group');

    final questionDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .doc(questionId)
        .get();

    if (!questionDoc.exists) throw Exception('Question not found');
    final authorId = questionDoc.get('authorId') as String;

    if (user.uid != authorId && !isModOrAdmin) {
      throw Exception('Not authorized to reply to this question');
    }

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .doc(questionId)
        .collection('replies')
        .add({
          'authorId': user.uid,
          'authorName': user.displayName ?? 'Unknown',
          'isStaff': isModOrAdmin,
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
        });

    if (isModOrAdmin) {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('announcements')
          .doc(announcementId)
          .collection('questions')
          .doc(questionId)
          .update({'isAnswered': true});
    }
  }

  Future<void> deleteQuestion({
    required String groupId,
    required String announcementId,
    required String questionId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final isModOrAdmin = await isGroupModOrAdmin(groupId);

    final questionDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .doc(questionId)
        .get();

    if (!questionDoc.exists) throw Exception('Question not found');
    final authorId = questionDoc.get('authorId') as String;

    if (user.uid != authorId && !isModOrAdmin) {
      throw Exception('Not authorized to delete this question');
    }

    final replies = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('announcements')
        .doc(announcementId)
        .collection('questions')
        .doc(questionId)
        .collection('replies')
        .get();

    final batch = _firestore.batch();
    for (final reply in replies.docs) {
      batch.delete(reply.reference);
    }
    batch.delete(questionDoc.reference);
    await batch.commit();
  }
}
