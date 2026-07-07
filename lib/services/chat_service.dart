import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/chat_room.dart';
import '../models/chat_message.dart';
import 'supabase_service.dart';
import '../core/utils/stream_utils.dart';

class ChatService {
  final SupabaseClient _supabase = SupabaseService.instance.client;

  Future<String> createOrGetDirectChatRoom({
    required String userA,
    required String userB,
  }) async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (supabaseUrl.isEmpty || anonKey.isEmpty) {
        throw Exception('Supabase not configured');
      }
      final edgeFunctionUrl =
          '$supabaseUrl/functions/v1/create-direct-chat-room';

      final response = await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode({'userA': userA, 'userB': userB}),
      );

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
            'Edge Function failed: ${errorBody['error'] ?? response.body}');
      }

      final data = jsonDecode(response.body);
      final roomId = data['roomId'] as String;
      return roomId;
    } catch (e) {
      debugPrint(
          '❌ Error creating/getting direct chat room via Edge Function: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSizeBytes,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'type': type.name,
        'attachment_url': attachmentUrl,
        'attachment_name': attachmentName,
        'attachment_size_bytes': attachmentSizeBytes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Safety update for installations where DB trigger is not applied yet.
      await _supabase
          .from('chat_rooms')
          .update({
            'last_message': type == MessageType.text
                ? content
                : (type == MessageType.image ? '[image]' : '[${type.name}]'),
            'last_message_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', roomId);
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  Future<void> sendImageMessage({
    required String roomId,
    required String senderId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = 'chat/$roomId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _supabase.storage.from('chat-attachments').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: false),
    );
    final url = _supabase.storage.from('chat-attachments').getPublicUrl(path);
    await sendMessage(
      roomId: roomId,
      senderId: senderId,
      content: url,
      type: MessageType.image,
      attachmentUrl: url,
      attachmentName: fileName,
      attachmentSizeBytes: bytes.length,
    );
  }

  // Get chat stream (newest first)
  Stream<List<ChatMessage>> getChatStream(String roomId) {
    return resilientStream(() => _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((m) => ChatMessage.fromMap(m)).toList()));
  }

  // Get user's chat rooms
  Stream<List<ChatRoom>> getUserChats(String userId) {
    if (userId.isEmpty) {
      return Stream.value(const <ChatRoom>[]);
    }

    return resilientStream(() {
      final baseStream = _supabase
          .from('chat_rooms')
          .stream(primaryKey: ['id'])
          .order('updated_at', ascending: false);

      return baseStream.asyncMap((rooms) async {
      try {
        if (rooms.isEmpty) return <ChatRoom>[];
        final roomIds = rooms.map((r) => r['id'].toString()).toList();

        List<Map<String, dynamic>> ownParticipantRows;
        try {
          ownParticipantRows = await _supabase
              .from('chat_participants')
              .select('room_id, unread_count')
              .eq('user_id', userId)
              .inFilter('room_id', roomIds);
        } catch (e) {
          debugPrint('⚠️ chat_participants query failed (RLS): $e');
          return <ChatRoom>[];
        }

        if (ownParticipantRows.isEmpty) {
          return <ChatRoom>[];
        }

        final ownByRoom = <String, int>{};
        for (final row in ownParticipantRows) {
          final map = Map<String, dynamic>.from(row);
          final roomId = map['room_id']?.toString() ?? '';
          if (roomId.isEmpty) continue;
          ownByRoom[roomId] = map['unread_count'] is int
              ? map['unread_count'] as int
              : int.tryParse(map['unread_count']?.toString() ?? '') ?? 0;
        }

        final visibleRoomIds = ownByRoom.keys.toSet();
        if (visibleRoomIds.isEmpty) {
          return <ChatRoom>[];
        }

        final participantsByRoom = <String, List<String>>{};
        try {
          final participantRows = await _supabase
              .from('chat_participants')
              .select('room_id, user_id')
              .inFilter('room_id', visibleRoomIds.toList());

          for (final row in participantRows) {
            final map = Map<String, dynamic>.from(row);
            final roomId = map['room_id']?.toString() ?? '';
            final participantId = map['user_id']?.toString() ?? '';
            if (roomId.isEmpty || participantId.isEmpty) continue;
            participantsByRoom.putIfAbsent(roomId, () => []).add(participantId);
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch all room participants (RLS likely): $e');
        }

        final visibleRooms = <ChatRoom>[];
        for (final room in rooms) {
          final roomMap = Map<String, dynamic>.from(room);
          final roomId = roomMap['id'].toString();
          if (!visibleRoomIds.contains(roomId)) continue;
          final participants = participantsByRoom[roomId] ?? [userId];

          visibleRooms.add(
            ChatRoom.fromMap({
              ...roomMap,
              'participants': participants,
              'unread_count': ownByRoom[roomId] ?? 0,
            }),
          );
        }
        return visibleRooms;
      } catch (e) {
        debugPrint('❌ getUserChats asyncMap error: $e');
        return <ChatRoom>[];
      }
      }).handleError((error, stackTrace) {
        debugPrint('❌ getUserChats asyncMap error: $error');
        return <ChatRoom>[];
      });
    });
  }

  // Get chat room by ID
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final room = await _supabase
          .from('chat_rooms')
          .select()
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return null;

      final participantsRes = await _supabase
          .from('chat_participants')
          .select('user_id')
          .eq('room_id', roomId);
      final participants = participantsRes
          .map((row) => row['user_id'].toString())
          .toList();

      return ChatRoom.fromMap({
        ...room,
        'participants': participants,
      });
    } catch (e) {
      debugPrint('❌ Error getting chat room: $e');
      return null;
    }
  }

  Future<void> markRoomAsRead({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _supabase.rpc('chat_mark_room_read', params: {
        'p_room_id': roomId,
        'p_user_id': userId,
      });
    } catch (_) {
      // Fallback if RPC not deployed yet.
      try {
        await _supabase
            .from('chat_participants')
            .update({
              'unread_count': 0,
              'last_read_at': DateTime.now().toIso8601String(),
            })
            .eq('room_id', roomId)
            .eq('user_id', userId);
      } catch (e) {
        debugPrint('❌ Error marking room read: $e');
      }
    }
  }

  Stream<bool> streamTyping({
    required String roomId,
    required String watcherUserId,
  }) async* {
    // Typing feature is temporarily disabled.
    yield false;
  }

  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) async {
    // Typing feature is temporarily disabled.
    return;
  }
}
