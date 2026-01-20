import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;
  
  static RequestStatus fromJson(String json) {
    return RequestStatus.values.firstWhere((e) => e.name == json);
  }
}

class GroupCreationRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String groupName;
  final String description;
  final String type;
  final Map<String, dynamic> metadata;
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  GroupCreationRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.groupName,
    required this.description,
    required this.type,
    this.metadata = const {},
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  factory GroupCreationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupCreationRequest(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterEmail: data['requesterEmail'] ?? '',
      groupName: data['groupName'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'club',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      status: RequestStatus.fromJson(data['status'] ?? 'pending'),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'groupName': groupName,
      'description': description,
      'type': type,
      'metadata': metadata,
      'status': status.toJson(),
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  bool get isPending => status == RequestStatus.pending;
  bool get isApproved => status == RequestStatus.approved;
  bool get isRejected => status == RequestStatus.rejected;
}
