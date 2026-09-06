import 'package:flutter/material.dart';
import '../../services/ai_chatbot_service.dart';
import '../../services/fallback_ai_service.dart';
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

  /// null = Gemini (mặc định: có RAG + function calling + streaming thật).
  /// Anything else is an OpenRouter slug from [FallbackAIService.models].
  String? _selectedModel;

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
  String? get selectedModel => _selectedModel;
  String get selectedModelLabel => _selectedModel == null
      ? 'Gemini 2.5 Flash'
      : FallbackAIService.label(_selectedModel!);

  /// Model options: Gemini first, then the OpenRouter backups (empty when no
  /// OPENROUTER_API_KEY — the picker hides itself).
  List<String?> get modelOptions =>
      FallbackAIService.isConfigured ? [null, ...FallbackAIService.models] : [];

  void selectModel(String? model) {
    if (_selectedModel == model) return;
    _selectedModel = model;
    notifyListeners();
  }

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

  /// Mở một đoạn chat trống. Không đụng tới DB: conversation chỉ được tạo khi
  /// người dùng thực sự gửi tin nhắn đầu tiên (xem [sendMessage]), nên việc mở
  /// chatbot nhiều lần không đẻ ra hàng loạt đoạn chat rỗng.
  Future<void> startNewConversation() async {
    _activeConversationId = null;
    _messages.clear();
    _addWelcomeMessage();
    _quickRepliesDismissed = false;
    notifyListeners();
  }

  /// Tên đoạn chat = tóm tắt câu hỏi đầu tiên: bỏ xuống dòng, cắt ở dấu câu
  /// đầu tiên, tối đa 60 ký tự và không cắt giữa từ.
  // ponytail: tóm tắt bằng cách cắt chuỗi; gọi LLM đặt tên nếu thấy chưa đủ gọn.
  @visibleForTesting
  static String titleFromMessage(String message) {
    final oneLine = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    final stop = oneLine.indexOf(RegExp(r'[.!?;]'));
    var title = (stop > 15 ? oneLine.substring(0, stop) : oneLine).trim();
    if (title.length > 60) {
      final space = title.lastIndexOf(' ', 60);
      title = '${title.substring(0, space > 20 ? space : 60).trim()}…';
    }
    return title.isEmpty ? 'Cuộc trò chuyện' : title;
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

    // Tin nhắn đầu tiên mới sinh ra một đoạn chat, và nó lấy tên từ chính câu hỏi.
    _activeConversationId ??= await _chatbotService.createConversation(
      title: titleFromMessage(text),
    );

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
        modelOverride: _selectedModel,
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
