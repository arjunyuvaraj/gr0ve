import 'package:cloud_firestore/cloud_firestore.dart';

enum JoinRequestStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;

  static JoinRequestStatus fromJson(String json) {
    return JoinRequestStatus.values.firstWhere((e) => e.name == json);
  }
}

class JoinRequest {
  final String userId;
  final String displayName;
  final String email;
  final DateTime requestedAt;
  final JoinRequestStatus status;
  final String joinCode;

  JoinRequest({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.requestedAt,
    required this.status,
    required this.joinCode,
  });

  factory JoinRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JoinRequest(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      status: JoinRequestStatus.fromJson(data['status'] ?? 'pending'),
      joinCode: data['joinCode'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.toJson(),
      'joinCode': joinCode,
    };
  }

  bool get isPending => status == JoinRequestStatus.pending;
}
