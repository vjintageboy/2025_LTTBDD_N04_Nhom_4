import 'package:flutter/material.dart';
import '../../services/ai_chatbot_service.dart';
import '../config/gemini_config.dart';

/// Chatbot Provider - Quản lý state của chatbot toàn app
class ChatbotProvider extends ChangeNotifier {
  final AIChatbotService _chatbotService = AIChatbotService();
  final FocusNode _inputFocusNode = FocusNode();

  // State
  bool _isLoading = false;
  String? _activeConversationId;
  List<AIConversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isInputFocused = false;
  bool _quickRepliesDismissed = false;

  ChatbotProvider() {
    _inputFocusNode.addListener(() {
      final focused = _inputFocusNode.hasFocus;
      if (focused && !_quickRepliesDismissed) {
        _quickRepliesDismissed = true;
      }
      if (_isInputFocused != focused) {
        _isInputFocused = focused;
        notifyListeners();
      }
    });
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get activeConversationId => _activeConversationId;
  List<AIConversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  TextEditingController get messageController => _messageController;
  FocusNode get inputFocusNode => _inputFocusNode;
  bool get showQuickReplies => !_quickRepliesDismissed && !_hasUserMessages;

  bool get _hasUserMessages => _messages.any((m) => m.isUser);

  /// Add welcome message
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      message:
          '👋 Xin chào! Tôi là AI Assistant của Moodiki. Tôi có thể giúp gì cho bạn?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, welcomeMessage);
  }

  Future<void> refreshConversations() async {
    _conversations = await _chatbotService.getConversationList();
    notifyListeners();
  }

  Future<void> startNewConversation() async {
    _activeConversationId = await _chatbotService.createConversation(
      title: 'New conversation',
    );
    _messages.clear();
    _addWelcomeMessage();
    _quickRepliesDismissed = false;
    await refreshConversations();
    notifyListeners();
  }

  Future<void> loadConversation(String conversationId) async {
    if (conversationId.isEmpty) return;

    _activeConversationId = conversationId;
    final loaded = await _chatbotService.getConversationMessages(
      conversationId,
      limit: 100,
    );

    _messages
      ..clear()
      ..addAll(loaded);

    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }

    _quickRepliesDismissed = _hasUserMessages;

    notifyListeners();
  }

  /// Send message with streaming support
  Future<void> sendMessage(String? message) async {
    final text = message ?? _messageController.text.trim();
    if (text.isEmpty) return;

    _quickRepliesDismissed = true;

    _activeConversationId ??= await _chatbotService.getOrCreateLatestConversation();

    // Clear input
    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      message: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.insert(0, userMessage);
    notifyListeners();

    if (_activeConversationId != null) {
      await _chatbotService.saveMessage(
        conversationId: _activeConversationId!,
        content: text,
        isUser: true,
      );
    }

    // Show loading
    _isLoading = true;
    notifyListeners();

    try {
      // Stream AI response (real-time typing effect)
      final responseStream = _chatbotService.getAIResponseStream(
        text,
        conversationId: _activeConversationId,
      );
      String fullResponse = '';
      bool hasInsertedAiMessage = false;
      final aiTimestamp = DateTime.now();

      await for (final chunk in responseStream) {
        fullResponse += chunk;

        // Insert/update AI message with accumulated text
        if (!hasInsertedAiMessage) {
          _messages.insert(
            0,
            ChatMessage(
              message: fullResponse,
              isUser: false,
              timestamp: aiTimestamp,
            ),
          );
          hasInsertedAiMessage = true;
        } else {
          _messages[0] = ChatMessage(
            message: fullResponse,
            isUser: false,
            timestamp: aiTimestamp,
          );
        }
        notifyListeners();
      }

      // If no response received, use fallback
      if (fullResponse.isEmpty) {
        fullResponse = 'Xin lỗi, tôi không thể trả lời lúc này. Vui lòng thử lại! 🙏';
        _messages.insert(
          0,
          ChatMessage(
          message:
              fullResponse,
          isUser: false,
          timestamp: DateTime.now(),
          ),
        );
      }

      if (_activeConversationId != null) {
        await _chatbotService.saveMessage(
          conversationId: _activeConversationId!,
          content: fullResponse,
          isUser: false,
          modelName: GeminiConfig.modelName,
        );
      }

      await refreshConversations();
    } catch (e) {
      debugPrint('Error sending message: $e');
      final errorMessage = ChatMessage(
        message: 'Đã có lỗi xảy ra. Vui lòng thử lại. 😔',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.insert(0, errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get quick replies
  Future<List<String>> getQuickReplies() async {
    // TODO: Check if user is admin
    return _chatbotService.getQuickReplies(isAdmin: false);
  }

  Future<void> deleteConversation(String conversationId) async {
    if (conversationId.isEmpty) return;

    final wasActive = conversationId == _activeConversationId;
    await _chatbotService.archiveConversation(conversationId);
    await refreshConversations();

    if (!wasActive) {
      return;
    }

    if (_conversations.isNotEmpty) {
      await loadConversation(_conversations.first.id);
      return;
    }

    await startNewConversation();
  }

  /// Clear current chat history (archive current conversation and start fresh)
  Future<void> clearChat() async {
    _chatbotService.resetChatSession();

    final currentId = _activeConversationId;
    if (currentId != null) {
      await _chatbotService.archiveConversation(currentId);
    }

    await startNewConversation();
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
