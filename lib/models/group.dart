import 'package:cloud_firestore/cloud_firestore.dart';

// ENUM: Defines the type of group (Club or Academy)
enum GroupType {
  club,
  academy;

  String toJson() => name;
  
  static GroupType fromJson(String json) {
    return GroupType.values.firstWhere((e) => e.name == json);
  }
}

// ENUM: Defines the current status of the group
enum GroupStatus {
  pending,
  active,
  archived;

  String toJson() => name;
  
  static GroupStatus fromJson(String json) {
    return GroupStatus.values.firstWhere((e) => e.name == json);
  }
}

// MODEL: Represents a user group with metadata and status
class Group {
  final String id;
  final String name;
  final String description;
  final GroupType type;
  final GroupStatus status;
  final String joinCode;
  final DateTime createdAt;
  final String createdBy;
  final List<String> adminIds;
  final Map<String, dynamic> metadata;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.joinCode,
    required this.createdAt,
    required this.createdBy,
    required this.adminIds,
    this.metadata = const {},
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: GroupType.fromJson(data['type'] ?? 'club'),
      status: GroupStatus.fromJson(data['status'] ?? 'active'),
      joinCode: data['joinCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      adminIds: List<String>.from(data['adminIds'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toJson(),
      'status': status.toJson(),
      'joinCode': joinCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'adminIds': adminIds,
      'metadata': metadata,
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    GroupType? type,
    GroupStatus? status,
    String? joinCode,
    DateTime? createdAt,
    String? createdBy,
    List<String>? adminIds,
    Map<String, dynamic>? metadata,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      joinCode: joinCode ?? this.joinCode,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      adminIds: adminIds ?? this.adminIds,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive => status == GroupStatus.active;
  bool isAdmin(String userId) => adminIds.contains(userId);
}
