enum MessageType { text, image, file, system }

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final MessageType type;
  final bool isPinned;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSizeBytes;
  final DateTime? readAt;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isPinned = false,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSizeBytes,
    this.readAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'is_pinned': isPinned,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'attachment_size_bytes': attachmentSizeBytes,
      'read_at': readAt?.toIso8601String(),
      'created_at': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      roomId: map['room_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isPinned: map['is_pinned'] as bool? ?? false,
      attachmentUrl: map['attachment_url']?.toString(),
      attachmentName: map['attachment_name']?.toString(),
      attachmentSizeBytes: map['attachment_size_bytes'] as int?,
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'].toString())
          : null,
    );
  }
}
