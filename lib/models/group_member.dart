import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberRole {
  admin,
  moderator,
  member;

  String toJson() => name;

  static MemberRole fromJson(String json) {
    return MemberRole.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MemberRole.member,
    );
  }
}

class GroupMember {
  final String userId;
  final String displayName;
  final String email;
  final MemberRole role;
  final DateTime joinedAt;
  final String addedBy;

  GroupMember({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.role,
    required this.joinedAt,
    required this.addedBy,
  });

  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMember(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: MemberRole.fromJson(data['role'] ?? 'member'),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      addedBy: data['addedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'role': role.toJson(),
      'joinedAt': Timestamp.fromDate(joinedAt),
      'addedBy': addedBy,
    };
  }
}

extension GroupMemberExtensions on GroupMember {
  bool get isAdmin => role == MemberRole.admin;

  bool get isMod => role == MemberRole.moderator;
}
