import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final String groupId;
  final String groupName;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String status;
  final DateTime requestedAt;
  final String requesterId;
  final String requesterName;
  final String? rejectionReason;

  CalendarEvent({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.status = 'pending',
    required this.requestedAt,
    required this.requesterId,
    required this.requesterName,
    this.rejectionReason,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      groupName: data['groupName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'],
      status: data['status'] ?? 'pending',
      requestedAt: (data['requestedAt'] as Timestamp? ?? Timestamp.now())
          .toDate(),
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown',
      rejectionReason: data['rejectionReason'],
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
