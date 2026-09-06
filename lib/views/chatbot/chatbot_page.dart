import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/chatbot_provider.dart';
import '../../core/services/localization_service.dart';
import '../../services/ai_chatbot_service.dart';
import '../../services/fallback_ai_service.dart';

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
    // Mở chatbot = mở đoạn chat trống; conversation chỉ sinh ra khi gửi tin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatbot = context.read<ChatbotProvider>();
      chatbot.startNewConversation();
    });
  }

  /// Height of the floating glass header (below the status bar).
  static const double headerHeight = 64;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      body: Stack(
        children: [
          // Messages scroll *under* the header instead of being boxed in by it
          // — the blur only reads as glass when there is something behind it.
          Column(
            children: [
              Expanded(child: _MessageList()),
              const _QuickReplies(),
              SafeArea(top: false, child: const _InputField()),
            ],
          ),
          _buildTopAppBar(),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: AppColors.osSurfaceBright.withValues(alpha: 0.72),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: headerHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    _circleButton(
                      IconsaxPlusLinear.arrow_left,
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.osPrimaryContainer,
                            AppColors.osSecondaryContainer,
                          ],
                        ),
                      ),
                      child: const Icon(
                        PhosphorIconsFill.sparkle,
                        color: AppColors.osOnPrimaryContainer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.aiAssistant,
                            style: const TextStyle(
                              color: AppColors.osOnSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _buildModelPicker(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _circleButton(IconsaxPlusLinear.more, onTap: _showChatMenu),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 40dp tonal circle — small enough to stay out of the way, still a 44dp
  /// touch target once the InkWell padding is counted.
  Widget _circleButton(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: AppColors.osPrimaryContainer.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: AppColors.osPrimary, size: 19),
        ),
      ),
    );
  }

  /// Which model is answering — a tappable pill, or plain text when no
  /// OpenRouter backup is configured.
  Widget _buildModelPicker() {
    final provider = context.watch<ChatbotProvider>();
    final options = provider.modelOptions;

    if (options.isEmpty) {
      return Text(
        provider.selectedModelLabel,
        style: const TextStyle(
          color: AppColors.osOnSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return GestureDetector(
      onTap: _showModelSheet,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.osPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              provider.selectedModelLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.osOnSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            IconsaxPlusLinear.arrow_down_1,
            size: 12,
            color: AppColors.osOnSurfaceVariant,
          ),
        ],
      ),
    );
  }

  // ─── Bottom sheets ────────────────────────────────────────────────
  // Popup menus anchored to a corner are what dated this screen; sheets keep
  // the rounded, tonal language of the rest of the app.

  Future<void> _showSheet(List<Widget> children) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.osSurfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(sheetContext).padding.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.osOutlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    bool danger = false,
    bool selected = false,
  }) {
    final color = danger ? AppColors.osError : AppColors.osOnSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: danger ? AppColors.osError : AppColors.osPrimary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                IconsaxPlusLinear.tick_circle,
                size: 18,
                color: AppColors.osPrimary,
              ),
          ],
        ),
      ),
    );
  }

  void _showChatMenu() {
    _showSheet([
      _sheetRow(
        IconsaxPlusLinear.message_add_1,
        'Chat mới',
        onTap: () {
          Navigator.pop(context);
          context.read<ChatbotProvider>().startNewConversation();
        },
      ),
      _sheetRow(
        PhosphorIconsRegular.clockCounterClockwise,
        'Lịch sử cuộc trò chuyện',
        onTap: () {
          Navigator.pop(context);
          _showConversationHistory();
        },
      ),
      _sheetRow(
        IconsaxPlusLinear.trash,
        context.l10n.clearChatHistory,
        danger: true,
        onTap: () {
          Navigator.pop(context);
          _showClearChatDialog();
        },
      ),
    ]);
  }

  void _showModelSheet() {
    final provider = context.read<ChatbotProvider>();
    _showSheet([
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Model trả lời',
            style: TextStyle(
              color: AppColors.osOnSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
      for (final option in provider.modelOptions)
        _sheetRow(
          option == null
              ? PhosphorIconsFill.sparkle
              : PhosphorIconsRegular.arrowsLeftRight,
          option == null
              ? 'Gemini 2.5 Flash'
              : FallbackAIService.label(option),
          selected: option == provider.selectedModel,
          onTap: () {
            Navigator.pop(context);
            provider.selectModel(option);
          },
        ),
    ]);
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.osSurfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: Text(
          context.l10n.clearChatHistory,
          style: const TextStyle(
            color: AppColors.osOnSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        content: Text(
          context.l10n.clearChatConfirmation,
          style: const TextStyle(
            color: AppColors.osOnSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(
                color: AppColors.osOnSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.osErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<ChatbotProvider>().clearChat();
            },
            child: Text(
              context.l10n.delete,
              style: const TextStyle(
                color: AppColors.osOnErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConversationHistory() {
    // Conversations are only created on the first message now, so the list can
    // be stale (or empty) by the time this opens.
    context.read<ChatbotProvider>().refreshConversations();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.osSurfaceContainerLowest,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Consumer<ChatbotProvider>(
            builder: (context, chatbot, _) {
              final conversations = chatbot.conversations;

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.osOutlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lịch sử trò chuyện',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.osOnSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                conversations.isEmpty
                                    ? 'Chưa có đoạn chat nào'
                                    : '${conversations.length} đoạn chat · vuốt sang trái để xoá',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.osOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _newChatPill(sheetContext),
                      ],
                    ),
                  ),
                  Expanded(
                    child: conversations.isEmpty
                        ? _historyEmptyState(scrollController)
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: conversations.length,
                            itemBuilder: (context, index) => _historyTile(
                              sheetContext,
                              chatbot,
                              conversations[index],
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _newChatPill(BuildContext sheetContext) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.pop(sheetContext);
          context.read<ChatbotProvider>().startNewConversation();
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconsaxPlusLinear.add, size: 16, color: AppColors.osOnPrimary),
              SizedBox(width: 6),
              Text(
                'Chat mới',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.osOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyEmptyState(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.osPrimaryContainer,
                AppColors.osSecondaryContainer,
              ],
            ),
          ),
          child: const Icon(
            PhosphorIconsRegular.chatsCircle,
            size: 32,
            color: AppColors.osOnPrimaryContainer,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Chưa có cuộc trò chuyện',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
            color: AppColors.osOnSurface,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nhắn một câu là đoạn chat đầu tiên của bạn xuất hiện ở đây.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
      ].map((w) => Center(child: w)).toList(),
    );
  }

  Widget _historyTile(
    BuildContext sheetContext,
    ChatbotProvider chatbot,
    AIConversation c,
  ) {
    final isActive = c.id == chatbot.activeConversationId;
    final title = c.title.trim().isNotEmpty
        ? c.title
        : (c.lastMessagePreview?.isNotEmpty == true
              ? c.lastMessagePreview!
              : 'Cuộc trò chuyện');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(c.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: AppColors.osErrorContainer,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            IconsaxPlusLinear.trash,
            color: AppColors.osOnErrorContainer,
            size: 20,
          ),
        ),
        confirmDismiss: (_) => _confirmDeleteConversation(title),
        onDismissed: (_) => chatbot.deleteConversation(c.id),
        child: Material(
          color: isActive
              ? AppColors.osPrimaryContainer
              : AppColors.osSurfaceContainer,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () async {
              await chatbot.loadConversation(c.id);
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.osOnPrimaryContainer
                                : AppColors.osOnSurface,
                          ),
                        ),
                        if (c.lastMessagePreview?.isNotEmpty == true) ...[
                          const SizedBox(height: 5),
                          Text(
                            c.lastMessagePreview!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.osOnSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatConversationDate(c.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.osOnPrimaryContainer.withValues(alpha: 0.7)
                          : AppColors.osOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteConversation(String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.osSurfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        title: const Text(
          'Xoá đoạn chat',
          style: TextStyle(
            color: AppColors.osOnSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        content: Text(
          '“$title” sẽ biến mất khỏi lịch sử.',
          style: const TextStyle(
            color: AppColors.osOnSurfaceVariant,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(
                color: AppColors.osOnSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.osErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.l10n.delete,
              style: const TextStyle(
                color: AppColors.osOnErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return ok ?? false;
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
      // Top padding clears the floating glass header the list scrolls under.
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + _ChatbotPageState.headerHeight + 20,
        20,
        8,
      ),
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

/// One turn of the conversation.
///
/// The assistant does not get a bubble: its answers are long, and a tinted box
/// around a paragraph is what made this screen read like 2015. It sits on the
/// page like body copy, with the avatar as the only chrome. The user's short
/// messages keep a bubble so the two voices stay distinguishable.
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: message.isUser ? _buildUser(context) : _buildAssistant(),
    );
  }

  Widget _buildAssistant() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssistantAvatar(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: const TextStyle(
                  color: AppColors.osOnSurface,
                  fontSize: 15,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 6),
              _timestamp(message.timestamp),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUser(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: const BoxDecoration(
              color: AppColors.osPrimaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              message.message,
              style: const TextStyle(
                color: AppColors.osOnPrimaryContainer,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _timestamp(message.timestamp),
      ],
    );
  }

  Widget _timestamp(DateTime time) => Text(
    _formatMessageTime(time),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.osOnSurfaceVariant,
    ),
  );
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.osPrimaryContainer,
            AppColors.osSecondaryContainer,
          ],
        ),
      ),
      child: const Icon(
        PhosphorIconsFill.sparkle,
        size: 15,
        color: AppColors.osOnPrimaryContainer,
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
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TypingDot(delay: index * 200),
                ),
              ),
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

/// Quick Replies — one scrolling row so they never steal a second line from
/// the conversation.
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
          child: !visible
              ? const SizedBox(width: double.infinity)
              : FutureBuilder<List<String>>(
                  future: chatbot.getQuickReplies(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    return SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final reply = snapshot.data![index];
                          return Material(
                            color: AppColors.osSurfaceContainerLowest,
                            borderRadius: BorderRadius.circular(19),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(19),
                              onTap: () => chatbot.sendMessage(reply),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    reply,
                                    style: const TextStyle(
                                      color: AppColors.osPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.osSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.osOnSurface.withValues(alpha: 0.06),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: chatbot.messageController,
                focusNode: chatbot.inputFocusNode,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: context.l10n.typeMessage,
                  hintStyle: TextStyle(
                    color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                ),
                style: const TextStyle(
                  color: AppColors.osOnSurface,
                  fontSize: 15,
                ),
                onSubmitted: (_) => chatbot.sendMessage(null),
                textInputAction: TextInputAction.send,
              ),
            ),
            // Gradient CTA per DESIGN.md — flat fills read as a stock button.
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
                  ),
                ),
                child: InkWell(
                  onTap: () => chatbot.sendMessage(null),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      IconsaxPlusBold.send_2,
                      color: AppColors.osOnPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
