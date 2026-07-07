enum ChatRoomStatus { active, archived }

class ChatRoom {
  final String id;
  final List<String> participants;
  final ChatRoomStatus status;
  final String roomType;
  final String? directKey;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.status,
    required this.createdAt,
    this.roomType = 'direct',
    this.directKey,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'status': status.name,
      'room_type': roomType,
      'direct_key': directKey,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id']?.toString() ?? '',
      participants: (map['participants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: ChatRoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChatRoomStatus.active,
      ),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      roomType: map['room_type']?.toString() ?? 'direct',
      directKey: map['direct_key']?.toString(),
      lastMessage: map['last_message']?.toString(),
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.tryParse(map['last_message_time'].toString())
          : null,
      unreadCount: map['unread_count'] as int? ?? 0,
    );
  }
}
