import 'package:google_generative_ai/google_generative_ai.dart';

import 'tool_dispatcher.dart';

/// Signature for the sendMessage function injected into [ToolLoopController].
///
/// In production: `model.startChat(history: history).sendMessage`
/// In tests: a lambda returning pre-built [GenerateContentResponse] objects.
typedef SendMessageFn = Future<GenerateContentResponse> Function(Content);

/// Manages the multi-turn Gemini tool-call loop.
///
/// The loop:
/// 1. Sends the user message (or function responses) to Gemini.
/// 2. If Gemini returns [FunctionCall] parts, dispatches each one concurrently
///    via [ToolDispatcher] and feeds all [FunctionResponse]s back.
/// 3. Repeats until Gemini returns a plain text response, or [_maxIterations]
///    is reached.
/// 4. On max-iterations: sends a single "summarize" prompt and returns its text.
///
/// All I/O is injected via [sendMessage] so the class is fully unit-testable
/// without hitting the real Gemini API.
class ToolLoopController {
  final ToolDispatcher dispatcher;

  static const int _maxIterations = 5;

  const ToolLoopController({required this.dispatcher});

  /// Thrown when Gemini stopped because it ran out of output budget.
  ///
  /// Half a sentence reads as a broken app, so the caller must treat this as a
  /// failure and try another lane — never show the partial text.
  static void _rejectIfTruncated(GenerateContentResponse response) {
    if (response.candidates.firstOrNull?.finishReason ==
        FinishReason.maxTokens) {
      throw StateError('Gemini hết token budget (MAX_TOKENS)');
    }
  }

  /// Runs the tool-call loop.
  ///
  /// [userMessage] is the initial user prompt.
  /// [sendMessage] is the function used to call Gemini (injected for testability).
  Future<String> execute({
    required String userMessage,
    required SendMessageFn sendMessage,
  }) async {
    Content currentInput = Content.text(userMessage);
    int iteration = 0;

    while (iteration < _maxIterations) {
      final response = await sendMessage(
        currentInput,
      ).timeout(const Duration(seconds: 30));

      final functionCalls = response.candidates.isNotEmpty
          ? response.candidates.first.content.parts
                .whereType<FunctionCall>()
                .toList()
          : <FunctionCall>[];

      if (functionCalls.isEmpty) {
        _rejectIfTruncated(response);
        return response.text ?? '';
      }

      // Dispatch all function calls concurrently.
      final functionResponses = await Future.wait(
        functionCalls.map((fc) async {
          final result = await dispatcher.dispatch(fc.name, fc.args);
          return FunctionResponse(fc.name, result);
        }),
      );

      currentInput = Content.functionResponses(functionResponses);
      iteration++;
    }

    // Max iterations reached — ask Gemini to summarize.
    final finalResponse = await sendMessage(
      Content.text('Vui lòng tóm tắt kết quả các actions đã thực hiện.'),
    ).timeout(const Duration(seconds: 30));

    _rejectIfTruncated(finalResponse);
    return finalResponse.text ?? 'Đã hoàn thành các tác vụ.';
  }
}
