import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Backup chat completion via OpenRouter, used only when every Gemini path
/// has already failed (quota, network, safety block, empty answer).
///
/// The model list lives in `.env` (`OPENROUTER_MODELS`, comma-separated, tried
/// in order) so a slug can be swapped without a rebuild — OpenRouter renames
/// and retires free models often.
///
/// ponytail: no tool calling and no real streaming on this lane — Gemini is
/// down, plain text beats nothing. Wire tools in only if this stops being the
/// exception path.
class FallbackAIService {
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';

  // Picked by measurement, not by spec sheet: the Gemma free endpoints answer
  // every call with 429 (shared Google AI Studio pool), so they are not here.
  static const String _defaultModels =
      'minimax/minimax-m3:free,minimax/minimax-m2.7:free,'
      'nvidia/nemotron-3-super-120b-a12b:free';

  static String get _apiKey => dotenv.get('OPENROUTER_API_KEY', fallback: '');

  static List<String> get models => dotenv
      .get('OPENROUTER_MODELS', fallback: _defaultModels)
      .split(',')
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toList();

  static bool get isConfigured => _apiKey.isNotEmpty && models.isNotEmpty;

  /// Human-readable name for a slug: `google/gemma-4-31b-it:free` → `Gemma 4 31b it`.
  static String label(String slug) {
    final name = slug.split('/').last.split(':').first.replaceAll('-', ' ');
    return name.isEmpty ? slug : name[0].toUpperCase() + name.substring(1);
  }

  /// Returns the reply text, or '' when every model failed.
  ///
  /// [model] puts the user's pick at the front of the queue; the rest of
  /// [models] still backs it up if that one is down.
  static Future<String> complete({
    required String systemPrompt,
    required String userMessage,
    List<({bool isUser, String text})> history = const [],
    String? model,
  }) async {
    if (!isConfigured) return '';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      for (final m in history)
        {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
      {'role': 'user', 'content': userMessage},
    ];

    // A pinned model is tried first, not exclusively — the free tier gets
    // rate-limited upstream and a dead end reads as "chatbot broken".
    final queue = model == null
        ? models
        : [model, ...models.where((m) => m != model)];

    for (final candidate in queue) {
      try {
        final res = await http
            .post(
              Uri.parse(_endpoint),
              headers: {
                'Authorization': 'Bearer $_apiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': candidate,
                'messages': messages,
                'temperature': 0.5,
                // minimax-m3 and nemotron-3-super are reasoning models, and
                // OpenRouter counts their reasoning tokens against max_tokens
                // — the same trap gemini-2.5-flash sets. 2048 left answers cut
                // mid-sentence; the ceiling is free when unused.
                'max_tokens': 8192,
              }),
            )
            .timeout(const Duration(seconds: 45));

        if (res.statusCode != 200) {
          debugPrint('[Fallback] $candidate → HTTP ${res.statusCode}: ${res.body}');
          continue;
        }

        // bodyBytes, not body: http defaults to latin1 when the server omits
        // the charset, which mangles Vietnamese.
        final body = utf8.decode(res.bodyBytes);

        // Even at 8192 a rambling model can run out. Half an answer is worse
        // than no answer — hand the turn to the next model instead.
        if (isTruncated(body)) {
          debugPrint('[Fallback] $candidate hit max_tokens, trying next');
          continue;
        }

        final text = extractText(body);
        if (text.isNotEmpty) {
          debugPrint('[Fallback] answered by $candidate');
          return text;
        }
        debugPrint('[Fallback] $candidate returned empty content');
      } catch (e) {
        debugPrint('[Fallback] $candidate failed: $e');
      }
    }
    return '';
  }

  /// True when the model stopped because it ran out of output budget.
  ///
  /// OpenRouter reports this as `finish_reason: "length"` on the choice.
  @visibleForTesting
  static bool isTruncated(String body) {
    try {
      final choices = jsonDecode(body)['choices'];
      if (choices is! List || choices.isEmpty) return false;
      return choices.first['finish_reason'] == 'length';
    } catch (_) {
      return false;
    }
  }

  /// Pull the assistant message out of an OpenRouter response body.
  @visibleForTesting
  static String extractText(String body) {
    try {
      final choices = jsonDecode(body)['choices'];
      if (choices is! List || choices.isEmpty) return '';
      return choices.first['message']?['content']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }
}
