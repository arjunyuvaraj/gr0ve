import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementQuestion {
  final String id;
  final String announcementId;
  final String groupId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final bool isAnswered;
  final List<QuestionReply> replies;

  const AnnouncementQuestion({
    required this.id,
    required this.announcementId,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.isAnswered,
    this.replies = const [],
  });

  factory AnnouncementQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementQuestion(
      id: doc.id,
      announcementId: data['announcementId'] ?? '',
      groupId: data['groupId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAnswered: data['isAnswered'] ?? false,
    );
  }
}

class QuestionReply {
  final String id;
  final String authorId;
  final String authorName;
  final bool isStaff; // true if mod or admin
  final String content;
  final DateTime createdAt;

  const QuestionReply({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.isStaff,
    required this.content,
    required this.createdAt,
  });

  factory QuestionReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuestionReply(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      isStaff: data['isStaff'] ?? false,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
