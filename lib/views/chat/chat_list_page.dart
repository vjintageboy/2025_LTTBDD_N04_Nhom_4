import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/chat_service.dart';
import '../../services/supabase_service.dart';
import '../../models/chat_room.dart';
import 'chat_detail_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final SupabaseService _supabaseService = SupabaseService.instance;
  String get _currentAuthId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getUserChats(_currentAuthId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('❌ Chat List Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có tin nhắn nào',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: Column(
                      children: [
                        Text(
                          'Current Auth ID: $_currentAuthId',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const Text(
                          'Querying: Supabase chat_participants by current user',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Chats Found: ${chatRooms.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chatRooms.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return _buildChatListItem(chatRoom);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatListItem(ChatRoom chatRoom) {
    final otherUserId = chatRoom.participants.firstWhere(
      (id) => id != _currentAuthId,
      orElse: () => '',
    );

    return FutureBuilder<Map<String, String>>(
      future: otherUserId.isNotEmpty ? _fetchUserInfo(otherUserId) : null,
      builder: (context, snapshot) {
        String displayName = 'Người dùng';
        String avatarUrl = '';

        if (snapshot.hasData) {
          displayName = snapshot.data!['name'] ?? 'Người dùng';
          avatarUrl = snapshot.data!['avatar'] ?? '';
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
          ),
          title: Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Text(
            chatRoom.lastMessage ?? 'Chưa có tin nhắn',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w400,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (chatRoom.lastMessageTime != null)
                Text(
                  DateFormat('HH:mm').format(chatRoom.lastMessageTime!),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              if (chatRoom.unreadCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${chatRoom.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  roomId: chatRoom.id,
                  targetName: displayName,
                  targetAvatarUrl: avatarUrl,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, String>> _fetchUserInfo(String userId) async {
    String displayName = 'Người dùng';
    String avatarUrl = '';

    try {
      final profile = await _supabaseService.getUserProfile(userId);
      if (profile != null) {
        displayName = profile['full_name']?.toString().trim().isNotEmpty == true
            ? profile['full_name'].toString()
            : displayName;
        avatarUrl = profile['avatar_url']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching user info: $e');
    }

    return {'name': displayName, 'avatar': avatarUrl};
  }
}
