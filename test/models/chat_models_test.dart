import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/models/chat_message.dart';
import 'package:n04_app/models/chat_room.dart';

void main() {
  group('ChatMessage model', () {
    test('creates with required fields', () {
      final msg = ChatMessage(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        content: 'Hello!',
        type: MessageType.text,
        timestamp: DateTime(2024, 4, 1, 10, 0),
      );

      expect(msg.isPinned, isFalse);
      expect(msg.attachmentUrl, isNull);
      expect(msg.attachmentName, isNull);
      expect(msg.attachmentSizeBytes, isNull);
      expect(msg.readAt, isNull);
    });

    test('toMap produces correct keys', () {
      final msg = ChatMessage(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        content: 'Hello',
        type: MessageType.text,
        timestamp: DateTime(2024, 4, 1, 10, 0),
        isPinned: true,
      );

      final map = msg.toMap();
      expect(map['id'], 'msg-1');
      expect(map['room_id'], 'room-1');
      expect(map['sender_id'], 'user-1');
      expect(map['content'], 'Hello');
      expect(map['type'], 'text');
      expect(map['is_pinned'], isTrue);
    });

    test('fromMap parses text message', () {
      final data = {
        'id': 'msg-1',
        'room_id': 'room-1',
        'sender_id': 'user-1',
        'content': 'Hi there',
        'type': 'text',
        'created_at': '2024-04-01T10:00:00.000',
        'is_pinned': false,
      };

      final msg = ChatMessage.fromMap(data);
      expect(msg.id, 'msg-1');
      expect(msg.roomId, 'room-1');
      expect(msg.senderId, 'user-1');
      expect(msg.content, 'Hi there');
      expect(msg.type, MessageType.text);
      expect(msg.isPinned, isFalse);
    });

    test('fromMap handles unknown message type', () {
      final data = {
        'id': 'msg-1',
        'room_id': 'room-1',
        'sender_id': 'user-1',
        'content': 'Test',
        'type': 'unknown_type',
        'created_at': '2024-04-01T10:00:00.000',
      };

      final msg = ChatMessage.fromMap(data);
      expect(msg.type, MessageType.text); // orElse fallback
    });

    test('fromMap parses image message with attachment', () {
      final data = {
        'id': 'msg-2',
        'room_id': 'room-1',
        'sender_id': 'user-1',
        'content': 'Check this',
        'type': 'image',
        'created_at': '2024-04-01T10:00:00.000',
        'is_pinned': false,
        'attachment_url': 'https://example.com/img.png',
        'attachment_name': 'img.png',
        'attachment_size_bytes': 1024,
      };

      final msg = ChatMessage.fromMap(data);
      expect(msg.type, MessageType.image);
      expect(msg.attachmentUrl, 'https://example.com/img.png');
      expect(msg.attachmentName, 'img.png');
      expect(msg.attachmentSizeBytes, 1024);
    });

    test('fromMap handles nullable read_at', () {
      final data = {
        'id': 'msg-1',
        'room_id': 'room-1',
        'sender_id': 'user-1',
        'content': 'Test',
        'type': 'text',
        'created_at': '2024-04-01T10:00:00.000',
        'read_at': '2024-04-01T10:05:00.000',
      };

      final msg = ChatMessage.fromMap(data);
      expect(msg.readAt, isA<DateTime>());

      final dataNoRead = {
        'id': 'msg-2',
        'room_id': 'room-1',
        'sender_id': 'user-1',
        'content': 'Test',
        'type': 'text',
        'created_at': '2024-04-01T10:00:00.000',
        'read_at': null,
      };

      final msgUnread = ChatMessage.fromMap(dataNoRead);
      expect(msgUnread.readAt, isNull);
    });

    test('fromMap handles missing fields gracefully', () {
      final data = {
        'id': null,
        'room_id': null,
        'sender_id': null,
        'content': null,
        'type': null,
        'created_at': null,
      };

      final msg = ChatMessage.fromMap(data);
      expect(msg.id, '');
      expect(msg.roomId, '');
      expect(msg.senderId, '');
      expect(msg.content, '');
      expect(msg.type, MessageType.text);
    });

    test('message type enum has all expected values', () {
      expect(MessageType.values.length, 4);
      expect(MessageType.values, contains(MessageType.text));
      expect(MessageType.values, contains(MessageType.image));
      expect(MessageType.values, contains(MessageType.file));
      expect(MessageType.values, contains(MessageType.system));
    });
  });

  group('ChatRoom model', () {
    test('creates with required fields', () {
      final room = ChatRoom(
        id: 'room-1',
        participants: ['user-1', 'user-2'],
        status: ChatRoomStatus.active,
        createdAt: DateTime(2024, 4, 1),
      );

      expect(room.roomType, 'direct'); // default
      expect(room.directKey, isNull);
      expect(room.lastMessage, isNull);
      expect(room.lastMessageTime, isNull);
      expect(room.unreadCount, 0);
    });

    test('toMap produces correct keys', () {
      final room = ChatRoom(
        id: 'room-1',
        participants: ['user-1', 'user-2'],
        status: ChatRoomStatus.active,
        createdAt: DateTime(2024, 4, 1, 10, 0),
        lastMessage: 'Hello',
        lastMessageTime: DateTime(2024, 4, 1, 10, 0),
      );

      final map = room.toMap();
      expect(map['status'], 'active');
      expect(map['room_type'], 'direct');
      expect(map['last_message'], 'Hello');
    });

    test('toMap handles empty appointmentId', () {
      final room = ChatRoom(
        id: 'room-1',
        participants: ['user-1'],
        status: ChatRoomStatus.active,
        createdAt: DateTime(2024, 4, 1),
      );

      final map = room.toMap();
      expect(map.containsKey('appointment_id'), isFalse);
    });

    test('fromMap parses room correctly', () {
      final data = {
        'id': 'room-1',
        'participants': ['user-1', 'user-2'],
        'status': 'active',
        'room_type': 'direct',
        'created_at': '2024-04-01T10:00:00.000',
        'last_message': 'Hi',
        'last_message_time': '2024-04-01T10:05:00.000',
        'unread_count': 2,
      };

      final room = ChatRoom.fromMap(data);
      expect(room.id, 'room-1');
      expect(room.participants, ['user-1', 'user-2']);
      expect(room.status, ChatRoomStatus.active);
      expect(room.lastMessage, 'Hi');
      expect(room.unreadCount, 2);
    });

    test('fromMap handles archived status', () {
      final data = {
        'id': 'room-1',
        'participants': ['user-1'],
        'status': 'archived',
        'created_at': '2024-04-01T10:00:00.000',
      };

      final room = ChatRoom.fromMap(data);
      expect(room.status, ChatRoomStatus.archived);
    });

    test('fromMap handles unknown status gracefully', () {
      final data = {
        'id': 'room-1',
        'participants': ['user-1'],
        'status': 'nonexistent',
        'created_at': '2024-04-01T10:00:00.000',
      };

      final room = ChatRoom.fromMap(data);
      expect(room.status, ChatRoomStatus.active); // orElse fallback
    });

    test('fromMap handles missing participants', () {
      final data = {
        'id': 'room-1',
        'participants': null,
        'status': 'active',
        'created_at': '2024-04-01T10:00:00.000',
      };

      final room = ChatRoom.fromMap(data);
      expect(room.participants, isEmpty);
    });

    test('fromMap handles direct_key', () {
      final data = {
        'id': 'room-1',
        'participants': ['user-1', 'user-2'],
        'status': 'active',
        'room_type': 'direct',
        'direct_key': 'user-1_user-2',
        'created_at': '2024-04-01T10:00:00.000',
      };

      final room = ChatRoom.fromMap(data);
      expect(room.roomType, 'direct');
      expect(room.directKey, 'user-1_user-2');
    });

    test('fromMap handles missing fields gracefully', () {
      final data = {
        'id': null,
        'participants': null,
        'status': null,
        'created_at': null,
      };

      final room = ChatRoom.fromMap(data);
      expect(room.id, '');
      expect(room.participants, isEmpty);
      expect(room.status, ChatRoomStatus.active);
    });

    test('ChatRoomStatus enum has expected values', () {
      expect(ChatRoomStatus.values.length, 2);
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.active));
      expect(ChatRoomStatus.values, contains(ChatRoomStatus.archived));
    });
  });
}
