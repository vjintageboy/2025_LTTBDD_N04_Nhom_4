import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai/tools/tool_definitions.dart';
import '../ai/tools/tool_dispatcher.dart';
import '../ai/tools/tool_loop_controller.dart';
import '../core/config/gemini_config.dart';
import '../core/config/system_prompt.dart';
import '../ai/safety_filter.dart';
import '../ai/disclaimer.dart';
import '../services/fallback_ai_service.dart';
import '../services/rag_service.dart';

/// AI Chatbot Service - Xử lý logic chatbot và AI responses
class AIChatbotService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Gemini AI Model
  GenerativeModel? _model;

  // Model with function calling tools enabled
  GenerativeModel? _modelWithTools;

  // Tool loop controller (initialized when user is authenticated)
  ToolLoopController? _toolController;

  // RAG service for dynamic context building
  final RAGService _ragService = RAGService();

  // Initialize Gemini model
  void _initializeGemini() {
    if (!GeminiConfig.isConfigured) return;

    _model = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
      generationConfig: GenerationConfig(
        temperature: GeminiConfig.temperature,
        maxOutputTokens: GeminiConfig.maxOutputTokens,
      ),
      systemInstruction: Content.text(GeminiConfig.systemPrompt),
      safetySettings: GeminiConfig.safetySettings,
    );
  }

  void _initializeTools(String userId) {
    if (!GeminiConfig.isConfigured || userId.isEmpty) return;

    _modelWithTools = GenerativeModel(
      model: GeminiConfig.modelName,
      apiKey: GeminiConfig.apiKey,
      generationConfig: GenerationConfig(
        temperature: GeminiConfig.temperature,
        maxOutputTokens: GeminiConfig.maxOutputTokens,
      ),
      systemInstruction: Content.text(GeminiConfig.systemPrompt),
      safetySettings: GeminiConfig.safetySettings,
      tools: [ToolDefinitions.allTools],
    );

    final dispatcher = ToolDispatcher(
      userId: userId,
      generateTimeSlots: _generateTimeSlots,
      getMoodEntries: (String uid, DateTime start, DateTime end) async {
        final response = await Supabase.instance.client
            .from('mood_entries')
            .select()
            .eq('user_id', uid)
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
        return List<Map<String, dynamic>>.from(response);
      },
    );

    _toolController = ToolLoopController(dispatcher: dispatcher);
  }

  User? get _currentUser => _supabase.auth.currentUser;

  // ===========================================================================
  // CONVERSATION + MESSAGE STORAGE (Supabase)
  // ===========================================================================

  Future<String?> createConversation({String? title}) async {
    final user = _currentUser;
    if (user == null) return null;

    try {
      final created = await _supabase
          .from('ai_conversations')
          .insert({
            'user_id': user.id,
            'title': title ?? 'New conversation',
            'is_archived': false,
          })
          .select('id')
          .single();

      return created['id']?.toString();
    } catch (e) {
      debugPrint('Error createConversation: $e');
      return null;
    }
  }

  Future<List<AIConversation>> getConversationList() async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('ai_conversations')
          .select()
          .eq('user_id', user.id)
          .eq('is_archived', false)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(data)
          .map(AIConversation.fromMap)
          .toList();
    } catch (e) {
      debugPrint('Error getConversationList: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    int limit = 100,
  }) async {
    if (conversationId.isEmpty) return [];

    try {
      final data = await _supabase
          .from('ai_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data)
          .map(ChatMessage.fromSupabaseMap)
          .toList();
    } catch (e) {
      debugPrint('Error getConversationMessages: $e');
      return [];
    }
  }

  Future<void> saveMessage({
    required String conversationId,
    required String content,
    required bool isUser,
    String? modelName,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _currentUser;
    if (user == null || conversationId.isEmpty || content.trim().isEmpty) {
      return;
    }

    try {
      await _supabase.from('ai_messages').insert({
        'conversation_id': conversationId,
        'user_id': user.id,
        'role': isUser ? 'user' : 'assistant',
        'content': content,
        'model_name': modelName,
        'metadata': metadata,
      });

      await _supabase.from('ai_conversations').update({
        'updated_at': DateTime.now().toIso8601String(),
        'last_message_preview': content.length > 120
            ? '${content.substring(0, 120)}...'
            : content,
      }).eq('id', conversationId);
    } catch (e) {
      debugPrint('Error saveMessage: $e');
    }
  }

  Future<void> archiveConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    try {
      await _supabase
          .from('ai_conversations')
          .update({'is_archived': true})
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('Error archiveConversation: $e');
    }
  }

  /// Emit [text] in small character slices to mimic token streaming for paths
  /// that only produce a full string (e.g. the non-streaming tool-call loop).
  /// Concatenating the slices reproduces [text] exactly.
  ///
  /// A slice never ends inside a surrogate pair: Dart strings are UTF-16, so a
  /// cut between the two halves of an emoji leaves a lone high surrogate on
  /// screen and Text() throws "string is not well-formed UTF-16".
  @visibleForTesting
  static Stream<String> sliceStream(String text) async* {
    const sliceLen = 12;
    var i = 0;
    while (i < text.length) {
      var end = (i + sliceLen < text.length) ? i + sliceLen : text.length;
      if (end < text.length && (text.codeUnitAt(end - 1) & 0xFC00) == 0xD800) {
        end++;
      }
      yield text.substring(i, end);
      i = end;
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }

  /// Get AI response with streaming (real-time typing effect)
  /// [modelOverride] pins an OpenRouter model the user picked in the UI; the
  /// Gemini paths (tools + streaming) are skipped entirely in that case.
  Stream<String> getAIResponseStream(
    String userMessage, {
    String? conversationId,
    String? modelOverride,
  }) async* {
    try {
      // ── Safety pre-check ──────────────────────────────────────
      final safetyResult = SafetyFilter.check(userMessage);

      // Critical: bypass AI, return emergency payload
      if (safetyResult.shouldBypassAI) {
        yield safetyResult.emergencyMessage ??
            SystemPromptTemplate.buildEmergency();
        return;
      }

      // Initialize Gemini if not already done
      if (_model == null && GeminiConfig.isConfigured) {
        _initializeGemini();
      }

      // Get user context
      final user = _currentUser;
      final isAdmin = await _checkIfAdmin(user?.id);
      final userName =
          user?.userMetadata?['full_name']?.toString() ?? user?.email ?? 'bạn';

      final history = conversationId == null
          ? <ChatMessage>[]
          : await getConversationMessages(conversationId, limit: 12);

      // The provider has already saved the current message, so it comes back
      // as the newest row here; drop it or the model sees it as two user turns.
      if (history.isNotEmpty &&
          history.first.isUser &&
          history.first.message == userMessage) {
        history.removeAt(0);
      }

      // Handed to Gemini as real conversation turns, so it is deliberately kept
      // out of the context blob below: sending both made the model read its own
      // past replies as part of what the user had just typed.
      final geminiHistory = _buildGeminiHistory(history.reversed.toList());

      final contextMessage = await _buildContextMessageAsync(
        userMessage,
        userName,
        isAdmin,
        user?.id ?? '',
      );

      // Initialize tool calling if user is authenticated
      if (user != null && _toolController == null) {
        debugPrint('[AIChatbot] Initializing function calling for user: ${user.id}');
        _initializeTools(user.id);
      }

      // Try function calling path first (non-streaming tool loop, then yield result)
      if (modelOverride == null &&
          _toolController != null &&
          _modelWithTools != null) {
        try {
          debugPrint('[AIChatbot] Stream: trying function calling path');
          final chat = _modelWithTools!.startChat(history: geminiHistory);
          final enhancedMessage = contextMessage.isNotEmpty ? contextMessage : userMessage;
          final aiText = await _toolController!.execute(
            userMessage: enhancedMessage,
            sendMessage: chat.sendMessage,
          );
          if (aiText.isNotEmpty) {
            debugPrint('[AIChatbot] Stream: function calling returned ${aiText.length} chars');
            final finalResponse = DisclaimerInjector.maybeAdd(
              aiResponse: aiText,
              userInput: userMessage,
            );
            // Slice the tool-path result so the UI still types it out
            // progressively (the tool loop itself is non-streaming).
            yield* sliceStream(finalResponse);
            return;
          }
        } catch (toolError) {
          debugPrint('[AIChatbot] Stream: tool calling error: $toolError');
          // Fall through to streaming path
        }
      }

      // Try Gemini streaming (no tools / fallback)
      if (modelOverride == null && _model != null) {
        try {
          final responseStream = _model!
              .startChat(history: geminiHistory)
              .sendMessageStream(Content.text(contextMessage));

          // Buffered on purpose, not streamed straight through: a chunk that
          // is already on screen cannot be taken back, so yielding live makes
          // a MAX_TOKENS cut permanently visible. Costs almost no perceived
          // latency — gemini-2.5-flash finishes thinking before it emits its
          // first token either way — and _sliceStream types it out anyway,
          // exactly like the other two lanes.
          String fullResponse = '';
          bool truncated = false;
          await for (final chunk in responseStream) {
            final text = chunk.text;
            if (text != null && text.isNotEmpty) fullResponse += text;
            if (chunk.candidates.firstOrNull?.finishReason ==
                FinishReason.maxTokens) {
              truncated = true;
            }
          }

          if (truncated) {
            debugPrint('[AIChatbot] Stream: hit MAX_TOKENS, dropping to fallback');
          } else if (fullResponse.isNotEmpty) {
            yield* sliceStream(DisclaimerInjector.maybeAdd(
              aiResponse: fullResponse,
              userInput: userMessage,
            ));
            return;
          }
        } catch (geminiError) {
          debugPrint('Gemini streaming error: $geminiError');
        }
      }

      // Either the user pinned an OpenRouter model, or every Gemini path
      // failed (quota, network, safety block, empty answer).
      final fallbackText = await FallbackAIService.complete(
        model: modelOverride,
        systemPrompt: GeminiConfig.systemPrompt,
        userMessage: contextMessage.isNotEmpty ? contextMessage : userMessage,
        history: history.reversed
            .where((m) => m.message.trim().isNotEmpty)
            .map((m) => (isUser: m.isUser, text: m.message))
            .toList(),
      );
      if (fallbackText.isNotEmpty) {
        yield* sliceStream(DisclaimerInjector.maybeAdd(
          aiResponse: fallbackText,
          userInput: userMessage,
        ));
        return;
      }

      // Nothing worked: Gemini and every backup model are unreachable or
      // unconfigured. Yielding nothing
      // lets ChatbotProvider surface its "không thể trả lời lúc này" message,
      // which beats a keyword-matched canned answer pretending to have
      // understood a question the assistant never saw.
    } catch (e) {
      debugPrint('Error in streaming response: $e');
      yield 'Xin lỗi, tôi gặp sự cố. Vui lòng thử lại sau. 🙏';
    }
  }

  /// Reset ephemeral model state (DB conversation history stays intact)
  void resetChatSession() {
    // Clear tool controller so it's re-initialized with the correct userId on next use.
    // Prevents stale userId from a previous user's session leaking into tool calls.
    _toolController = null;
    _modelWithTools = null;
    _ragService.resetModel();
  }

  /// Build context message with user info and RAG context.
  ///
  /// Chat history is deliberately absent: the caller hands it to Gemini as real
  /// conversation turns, and repeating it here made the model read its own past
  /// replies as part of what the user had just typed.
  Future<String> _buildContextMessageAsync(
    String userMessage,
    String userName,
    bool isAdmin,
    String userId,
  ) async {
    final role = isAdmin ? 'Admin' : 'Người dùng';

    // Built fresh every turn (~1s): the meditation search is keyed on this
    // very message, so the old 5-minute cache answered "khó ngủ" with whatever
    // matched the message before it.
    UserContext? ragContext;
    try {
      ragContext = await _ragService.buildUserContext(
        userId: userId,
        lastMessage: userMessage,
      );
    } catch (e) {
      debugPrint('[AIChatbot] Failed to build RAG context: $e');
    }
    final now = DateTime.now();

    // Build the full context string
    String ragContextStr = '';
    if (ragContext != null && !ragContext.isEmpty) {
      ragContextStr = '\n${ragContext.toPromptContext()}\n';
    }

    // Shape mirrors the "Ngữ cảnh mỗi lượt" section of the system prompt.
    // Today's date is what lets "báo cáo tháng này" resolve to month/year
    // for the report tool — the model has no clock of its own.
    return '''
<context>
Hôm nay: ${now.day}/${now.month}/${now.year}
Người dùng: $userName (vai trò: $role)
$ragContextStr</context>

Dựa vào ngữ cảnh trên, trả lời tin nhắn này của người dùng:
$userMessage
''';
  }

  /// Convert stored ChatMessage list to Gemini Content history format.
  List<Content> _buildGeminiHistory(List<ChatMessage> messages) {
    return messages
        .where((msg) => msg.message.trim().isNotEmpty)
        .map((msg) {
          if (msg.isUser) {
            return Content.text(msg.message);
          } else {
            return Content.model([TextPart(msg.message)]);
          }
        })
        .toList();
  }

  /// Generate candidate time slots between start and end at the given interval.
  static List<String> _generateTimeSlots({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) {
    final slots = <String>[];
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    var current = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes =
        int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    while (current + intervalMinutes <= endMinutes) {
      final h = current ~/ 60;
      final m = current % 60;
      slots.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      current += intervalMinutes;
    }
    return slots;
  }

  /// Check if user is admin
  Future<bool> _checkIfAdmin(String? uid) async {
    if (uid == null) return false;
    try {
      final data = await _supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      return data?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Get quick reply suggestions based on context
  List<String> getQuickReplies({bool isAdmin = false}) {
    if (isAdmin) {
      return [
        'Xem thống kê',
        'Quản lý người dùng',
        'Danh sách meditations',
        'Giúp đỡ',
      ];
    }
    return [
      'Tìm meditation',
      'Ghi nhận tâm trạng',
      'Báo cáo tâm lý tháng',
      'Tips hôm nay',
    ];
  }

}

class AIConversation {
  final String id;
  final String userId;
  final String title;
  final String? lastMessagePreview;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIConversation({
    required this.id,
    required this.userId,
    required this.title,
    this.lastMessagePreview,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIConversation.fromMap(Map<String, dynamic> map) {
    return AIConversation(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Conversation',
      lastMessagePreview: map['last_message_preview']?.toString(),
      isArchived: map['is_archived'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : DateTime.now(),
    );
  }
}

/// Chat Message Model
class ChatMessage {
  final String? id;
  final String? conversationId;
  final String role;
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    this.conversationId,
    String? role,
    required this.message,
    required this.isUser,
    required this.timestamp,
  }) : role = role ?? (isUser ? 'user' : 'assistant');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      message: map['message'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  factory ChatMessage.fromSupabaseMap(Map<String, dynamic> map) {
    final role = map['role']?.toString() ?? 'assistant';
    return ChatMessage(
      id: map['id']?.toString(),
      conversationId: map['conversation_id']?.toString(),
      role: role,
      message: map['content']?.toString() ?? '',
      isUser: role == 'user',
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }
}
