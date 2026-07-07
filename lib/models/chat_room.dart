/// Trạng thái phòng chat
enum ChatRoomStatus { active, archived }

class ChatRoom {
  final String id;
  final List<String> participants;
  final ChatRoomStatus status;
  final DateTime createdAt;
  final String roomType;
  final String? directKey;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

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

  /// Chuyển object thành map để lưu Supabase
  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'room_type': roomType,
      'direct_key': directKey,
      'created_at': createdAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> data) {
    return ChatRoom(
      id: data['id']?.toString() ?? '',
      participants: _parseParticipants(data['participants']),
      status: _parseStatus(data['status']),
      createdAt: _parseDateTime(data['created_at']),
      roomType: data['room_type']?.toString() ?? 'direct',
      directKey: data['direct_key']?.toString(),
      lastMessage: data['last_message']?.toString(),
      lastMessageTime: _parseNullableDateTime(data['last_message_time']),
      unreadCount: data['unread_count'] is int
          ? data['unread_count'] as int
          : int.tryParse(data['unread_count']?.toString() ?? '') ?? 0,
    );
  }

  // ---------------------------------------------------------------------------
  // 🔒 SAFE PARSERS – Tránh crash nếu dữ liệu bị thiếu hoặc sai format
  // ---------------------------------------------------------------------------

  static List<String> _parseParticipants(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static ChatRoomStatus _parseStatus(dynamic value) {
    if (value is String) {
      return ChatRoomStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ChatRoomStatus.active,
      );
    }
    return ChatRoomStatus.active;
  }

  static DateTime _parseDateTime(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic ts) {
    if (ts == null) return null;
    return _parseDateTime(ts);
  }
}
