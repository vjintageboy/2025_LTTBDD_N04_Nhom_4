import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/chatbot_provider.dart';
import '../../services/ai_chatbot_service.dart';

/// Global AI Chatbot Widget - Có thể sử dụng trên toàn bộ app
class AIChatbotWidget extends StatelessWidget {
  const AIChatbotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatbotProvider>(
      builder: (context, chatbot, _) {
        return Stack(
          children: [
            // Chat Panel
            if (chatbot.isOpen) _ChatPanel(),

            // Floating Action Button
            _ChatbotFAB(),
          ],
        );
      },
    );
  }
}

/// Floating Action Button cho Chatbot
class _ChatbotFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();

    return Positioned(
      right: 16,
      bottom: 16,
      child: AnimatedScale(
        scale: chatbot.isOpen && !chatbot.isMinimized ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: () => chatbot.openChatbot(),
          backgroundColor: const Color(0xFF7B2BB0),
          elevation: 8,
          child: Stack(
            children: [
              const Icon(
                IconsaxPlusLinear.message,
                color: Colors.white,
                size: 28,
              ),
              // Notification badge (optional)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 12,
                    minHeight: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat Panel - Giao diện chat
class _ChatPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();
    final size = MediaQuery.of(context).size;

    return Positioned(
      right: 16,
      bottom: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: size.width > 600 ? 400 : size.width - 32,
          height: chatbot.isMinimized ? 60 : size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              _ChatHeader(),

              // Messages (only show when not minimized)
              if (!chatbot.isMinimized) ...[
                Expanded(child: _MessageList()),
                _QuickReplies(),
                _InputField(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat Header
class _ChatHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatbot = context.watch<ChatbotProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF7B2BB0), const Color(0xFF9B4FD8)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.robot, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.clockCounterClockwise, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return Consumer<ChatbotProvider>(
                    builder: (context, chatbot, _) {
                      final conversations = chatbot.conversations;

                      if (conversations.isEmpty) {
                        return const SizedBox(
                          height: 220,
                          child: Center(
                            child: Text('No conversation history yet'),
                          ),
                        );
                      }

                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: ListView.separated(
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final c = conversations[index];
                            final title = c.title.trim().isNotEmpty
                                ? c.title
                                : (c.lastMessagePreview?.isNotEmpty == true
                                      ? c.lastMessagePreview!
                                      : 'Conversation');

                            return ListTile(
                              selected: c.id == chatbot.activeConversationId,
                              leading: const Icon(IconsaxPlusLinear.messages),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                c.lastMessagePreview ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  IconsaxPlusLinear.trash,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('Xóa đoạn chat'),
                                      content: const Text(
                                        'Bạn có chắc muốn xóa đoạn chat này khỏi lịch sử?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await chatbot.deleteConversation(c.id);
                                  }
                                },
                              ),
                              onTap: () async {
                                await chatbot.loadConversation(c.id);
                                if (context.mounted) Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(IconsaxPlusLinear.message_add_1, color: Colors.white),
            onPressed: () => chatbot.startNewConversation(),
          ),
          IconButton(
            icon: Icon(
              chatbot.isMinimized ? IconsaxPlusLinear.maximize : IconsaxPlusLinear.maximize,
              color: Colors.white,
            ),
            onPressed: () => chatbot.toggleMinimize(),
          ),
          IconButton(
            icon: const Icon(IconsaxPlusLinear.close_circle, color: Colors.white),
            onPressed: () => chatbot.closeChatbot(),
          ),
        ],
      ),
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

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: chatbot.messages.length + (showTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0 && showTyping) {
            return _TypingIndicator();
          }

          final messageIndex = showTyping ? index - 1 : index;
          final message = chatbot.messages[messageIndex];

          return _MessageBubble(message: message);
        },
      ),
    );
  }
}

/// Message Bubble
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2BB0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.robot,
                size: 20,
                color: Color(0xFF7B2BB0),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF7B2BB0) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7B2BB0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconsaxPlusBold.user,
                size: 20,
                color: Color(0xFF7B2BB0),
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2BB0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.robot,
              size: 20,
              color: Color(0xFF7B2BB0),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
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
            color: const Color(0xFF7B2BB0).withValues(alpha: _controller.value),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B2BB0).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF7B2BB0).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                reply,
                                style: const TextStyle(
                                  color: Color(0xFF7B2BB0),
                                  fontSize: 12,
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

    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
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
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => chatbot.sendMessage(null),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF7B2BB0),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => chatbot.sendMessage(null),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(IconsaxPlusBold.send_2, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
