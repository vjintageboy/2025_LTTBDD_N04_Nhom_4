import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/chatbot_provider.dart';
import '../../core/services/localization_service.dart';
import '../../services/ai_chatbot_service.dart';

/// Chatbot Page - Full screen AI chat interface
/// Redesigned with Organic Sanctuary design system
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  @override
  void initState() {
    super.initState();
    // Always start a new chat session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatbot = context.read<ChatbotProvider>();
      chatbot.startNewConversation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom TopAppBar with glassmorphism
            _buildTopAppBar(),
            // Messages
            Expanded(child: _MessageList()),
            // Quick Replies
            const _QuickReplies(),
            // Input Field
            const _InputField(),
            // Bottom Navigation Bar
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.osSurface.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.osOnSurface.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(IconsaxPlusLinear.arrow_left, color: AppColors.osPrimary, size: 24),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          // AI Avatar with status indicator
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.osPrimaryContainer,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.osSurfaceContainer,
                    child: const Icon(
                      PhosphorIconsRegular.robot,
                      color: AppColors.osPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.osPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.osSurface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.aiAssistant,
                  style: const TextStyle(
                    color: AppColors.osPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: AppColors.osOnSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.osPrimaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(IconsaxPlusLinear.more, color: AppColors.osPrimary, size: 20),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            shadowColor: AppColors.osOnSurface.withValues(alpha: 0.12),
            color: AppColors.osSurfaceContainerLowest,
            position: PopupMenuPosition.under,
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  context.read<ChatbotProvider>().startNewConversation();
                  break;
                case 'history':
                  _showConversationHistory();
                  break;
                case 'clear_chat':
                  _showClearChatDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              _buildMenuItem(
                IconsaxPlusLinear.message_add_1,
                'Chat mới',
                AppColors.osPrimary,
                'new_chat',
              ),
              _buildMenuItem(
                PhosphorIconsRegular.clockCounterClockwise,
                'Lịch sử cuộc trò chuyện',
                AppColors.osPrimary,
                'history',
              ),
              const PopupMenuDivider(height: 8),
              _buildMenuItem(
                IconsaxPlusLinear.trash,
                context.l10n.clearChatHistory,
                Colors.red,
                'clear_chat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceBright.withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(
            color: AppColors.osOnSurface.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(IconsaxPlusLinear.messages_2, 'Chat', true),
          _buildNavItem(PhosphorIconsRegular.clockCounterClockwise, 'History', false, onTap: _showConversationHistory),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, String label, Color color, String value) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color == Colors.red ? Colors.red : AppColors.osOnSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.osPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.osOnPrimary : AppColors.osOnSurface.withValues(alpha: 0.7),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.osOnPrimary : AppColors.osOnSurface.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.osSurfaceContainerLowest,
        title: Text(
          context.l10n.clearChatHistory,
          style: const TextStyle(color: AppColors.osOnSurface),
        ),
        content: Text(
          context.l10n.clearChatConfirmation,
          style: const TextStyle(color: AppColors.osOnSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: AppColors.osPrimary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await this.context.read<ChatbotProvider>().clearChat();
            },
            child: Text(
              context.l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<ChatbotProvider>(
          builder: (context, chatbot, _) {
            final conversations = chatbot.conversations;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppColors.osSurfaceContainerLowest,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.osOutlineVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.osPrimaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.clockCounterClockwise,
                                color: AppColors.osOnPrimaryContainer,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Conversation History',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.osOnSurface,
                                    ),
                                  ),
                                  Text(
                                    'Browse your past chats',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.osOnSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(IconsaxPlusLinear.close_circle, color: AppColors.osOnSurface),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.osOutlineVariant),
                      // List
                      Expanded(
                        child: conversations.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      IconsaxPlusLinear.message,
                                      size: 64,
                                      color: AppColors.osOutlineVariant.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No conversations yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.osOnSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Start chatting to see your history',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: conversations.length,
                                itemBuilder: (context, index) {
                                  final c = conversations[index];
                                  final isActive = c.id == chatbot.activeConversationId;
                                  final title = c.title.trim().isNotEmpty
                                      ? c.title
                                      : (c.lastMessagePreview?.isNotEmpty == true
                                            ? c.lastMessagePreview!
                                            : 'Cuộc trò chuyện');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        onTap: () async {
                                          await chatbot.loadConversation(c.id);
                                          if (context.mounted) Navigator.pop(context);
                                        },
                                        borderRadius: BorderRadius.circular(18),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppColors.osPrimaryContainer.withValues(alpha: 0.35)
                                                : AppColors.osSurfaceContainer.withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: isActive
                                                  ? AppColors.osPrimary.withValues(alpha: 0.3)
                                                  : AppColors.osOutlineVariant.withValues(alpha: 0.15),
                                              width: isActive ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Icon
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? AppColors.osPrimary.withValues(alpha: 0.15)
                                                      : AppColors.osPrimaryContainer,
                                                  borderRadius: BorderRadius.circular(13),
                                                ),
                                                child: Icon(
                                                  isActive
                                                      ? IconsaxPlusBold.message
                                                      : IconsaxPlusLinear.messages,
                                                  color: isActive
                                                      ? AppColors.osPrimary
                                                      : AppColors.osOnPrimaryContainer,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // Text
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            title,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 14,
                                                              color: isActive
                                                                  ? AppColors.osPrimary
                                                                  : AppColors.osOnSurface,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          _formatConversationDate(c.updatedAt),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w500,
                                                            color: isActive
                                                                ? AppColors.osPrimary.withValues(alpha: 0.7)
                                                                : AppColors.osOnSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (c.lastMessagePreview?.isNotEmpty == true) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        c.lastMessagePreview!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.8),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              // Delete button
                                              PopupMenuButton<String>(
                                                icon: Container(
                                                  padding: const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.osOutlineVariant.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    IconsaxPlusLinear.more,
                                                    color: AppColors.osOnSurfaceVariant,
                                                    size: 18,
                                                  ),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                elevation: 4,
                                                shadowColor: AppColors.osOnSurface.withValues(alpha: 0.1),
                                                color: AppColors.osSurfaceContainerLowest,
                                                onSelected: (value) async {
                                                  if (value == 'delete') {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (dialogContext) => AlertDialog(
                                                        backgroundColor: AppColors.osSurfaceContainerLowest,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(24),
                                                        ),
                                                        title: const Text('Xóa cuộc trò chuyện'),
                                                        content: const Text(
                                                          'Bạn có chắc muốn xóa đoạn chat này khỏi lịch sử?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(dialogContext, false),
                                                            child: Text(this.context.l10n.cancel),
                                                          ),
                                                          FilledButton(
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor: Colors.red,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                            onPressed: () => Navigator.pop(dialogContext, true),
                                                            child: Text(this.context.l10n.delete),
                                                          ),
                                                        ],
                                                      ),
                                                    );

                                                    if (confirm == true) {
                                                      await chatbot.deleteConversation(c.id);
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  PopupMenuItem<String>(
                                                    value: 'delete',
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.all(7),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Icon(
                                                            IconsaxPlusLinear.trash,
                                                            color: Colors.red,
                                                            size: 18,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          this.context.l10n.delete,
                                                          style: const TextStyle(
                                                            color: Colors.red,
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Message List
class _MessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();
    final showTyping =
        chatbot.isLoading &&
        (chatbot.messages.isEmpty || chatbot.messages.first.isUser);

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      itemCount: chatbot.messages.length + (showTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && showTyping) {
          return const _TypingIndicator();
        }

        final messageIndex = showTyping ? index - 1 : index;
        final message = chatbot.messages[messageIndex];

        return _MessageBubble(message: message);
      },
    );
  }
}

/// Formats a [DateTime] as a human-readable relative time string.
String _formatMessageTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return '$hh:$mm';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (time.year == yesterday.year &&
      time.month == yesterday.month &&
      time.day == yesterday.day) {
    return 'Hôm qua $hh:$mm';
  }
  final dd = time.day.toString().padLeft(2, '0');
  final mo = time.month.toString().padLeft(2, '0');
  return '$dd/$mo $hh:$mm';
}

/// Formats a conversation's [updatedAt] into a compact label for the history list.
String _formatConversationDate(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  final hh = time.hour.toString().padLeft(2, '0');
  final mm = time.minute.toString().padLeft(2, '0');
  if (time.year == now.year && time.month == now.month && time.day == now.day) {
    return '$hh:$mm';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (time.year == yesterday.year &&
      time.month == yesterday.month &&
      time.day == yesterday.day) {
    return 'Hôm qua';
  }
  final dd = time.day.toString().padLeft(2, '0');
  final mo = time.month.toString().padLeft(2, '0');
  return time.year == now.year ? '$dd/$mo' : '$dd/$mo/${time.year}';
}

/// Message Bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.osPrimaryContainer, AppColors.osSecondaryContainer],
                ),
              ),
              child: const Icon(
                PhosphorIconsRegular.robot,
                size: 18,
                color: AppColors.osOnPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
              child: Column(
              crossAxisAlignment:
                  message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppColors.osSurfaceContainerLowest
                        : AppColors.osSurfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(message.isUser ? 24 : 0),
                      bottomRight: Radius.circular(message.isUser ? 0 : 24),
                    ),
                    border: message.isUser
                        ? Border.all(
                            color: AppColors.osOutlineVariant.withValues(alpha: 0.15),
                            width: 1,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.osOnSurface.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isUser
                          ? AppColors.osOnSurface
                          : AppColors.osOnPrimaryContainer,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.only(
                    left: message.isUser ? 0 : 44,
                  ),
                  child: Text(
                    _formatMessageTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.osOnSurfaceVariant,
                    ),
                    textAlign: message.isUser ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
                ),
              ),
              child: const Center(
                child: Text(
                  'JD',
                  style: TextStyle(
                    color: AppColors.osOnPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Typing Indicator
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.osPrimaryContainer, AppColors.osSecondaryContainer],
              ),
            ),
            child: const Icon(
              PhosphorIconsRegular.robot,
              size: 18,
              color: AppColors.osOnPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.zero,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.osOnSurface.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _TypingDot(delay: index * 200),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.osPrimary.withValues(alpha: 0.3 + (_controller.value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Quick Replies
class _QuickReplies extends StatelessWidget {
  const _QuickReplies();

  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();
    final visible = chatbot.showQuickReplies;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: visible ? 1 : 0,
          child: visible
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: FutureBuilder<List<String>>(
                    future: chatbot.getQuickReplies(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: snapshot.data!.map((reply) {
                          return InkWell(
                            onTap: () => chatbot.sendMessage(reply),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.osSurfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                reply,
                                style: const TextStyle(
                                  color: AppColors.osOnSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Input Field
class _InputField extends StatelessWidget {
  const _InputField();

  @override
  Widget build(BuildContext context) {
    final chatbot = context.read<ChatbotProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.osSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.osOnSurface.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatbot.messageController,
                      focusNode: chatbot.inputFocusNode,
                      decoration: InputDecoration(
                        hintText: context.l10n.typeMessage,
                        hintStyle: TextStyle(
                          color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        color: AppColors.osOnSurface,
                        fontSize: 14,
                      ),
                      onSubmitted: (_) => chatbot.sendMessage(null),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: AppColors.osPrimary,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () => chatbot.sendMessage(null),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: const Icon(
                            IconsaxPlusBold.send_2,
                            color: AppColors.osOnPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
