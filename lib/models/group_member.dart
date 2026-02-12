import 'package:cloud_firestore/cloud_firestore.dart';

/// ---------------------- MEMBER ROLES ----------------------
enum MemberRole {
  admin,
  moderator,
  member;

  /// Convert to Firestore string
  String toJson() => name;

  /// Convert from Firestore string
  static MemberRole fromJson(String json) {
    return MemberRole.values.firstWhere(
      (e) => e.name == json,
      orElse: () => MemberRole.member,
    );
  }
}

/// ---------------------- GROUP MEMBER ----------------------
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

  /// Create a GroupMember from Firestore document
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

  /// Convert GroupMember to Firestore map
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

/// ---------------------- EXTENSIONS ----------------------
extension GroupMemberExtensions on GroupMember {
  /// True if member is admin
  bool get isAdmin => role == MemberRole.admin;

  /// True if member is moderator
  bool get isMod => role == MemberRole.moderator;
}
