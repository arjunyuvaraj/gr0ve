import 'package:gr0ve/features/counselor/services/counselor_persona_service.dart';

// ─────────────────────────────────────────────────────────────
// DOMAIN
// ─────────────────────────────────────────────────────────────

enum CounselorDomain { general, college, research, ib, art, policy }

// ─────────────────────────────────────────────────────────────
// CHAT MESSAGE
// ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final CounselorPersona? speaker;
  final DateTime timestamp;
  final bool isLoading;
  final String? imagePath;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    this.speaker,
    required this.timestamp,
    this.isLoading = false,
    this.imagePath,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  ChatMessage copyWith({String? text, bool? isLoading}) => ChatMessage(
    id: id,
    text: text ?? this.text,
    isUser: isUser,
    speaker: speaker,
    timestamp: timestamp,
    isLoading: isLoading ?? this.isLoading,
    imagePath: imagePath ?? this.imagePath,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    if (speaker != null) 'speaker': speaker!.id,
    'timestamp': timestamp.millisecondsSinceEpoch,
    if (imagePath != null) 'imagePath': imagePath,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    CounselorPersona? sp;
    if (json['speaker'] != null) {
      sp =
          CounselorPersona.values.firstWhereOrNull(
            (p) => p.id == json['speaker'],
          ) ??
          CounselorPersona.grover;
    }
    return ChatMessage(
      id: json['id'] as String?,
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      speaker: sp,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      imagePath: json['imagePath'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EXTENSIONS
// ─────────────────────────────────────────────────────────────

extension ChatMessageX on ChatMessage {
  bool get isChimePrompt => !isUser && text.startsWith('__chime__:');

  CounselorPersona? get chimePersona {
    if (!isChimePrompt) return null;
    final parts = text.replaceFirst('__chime__:', '').split('|');
    return CounselorPersona.values.firstWhereOrNull((p) => p.id == parts[0]);
  }

  String get chimePrevSpeaker {
    if (!isChimePrompt) return '';
    final parts = text.replaceFirst('__chime__:', '').split('|');
    return parts.length > 1 ? parts[1] : '';
  }
}

extension ListX<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
