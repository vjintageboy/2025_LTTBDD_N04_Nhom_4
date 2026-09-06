import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'system_prompt.dart';

/// Gemini AI Configuration
///
/// API key được load từ file .env
/// Để setup:
/// 1. Lấy API key: https://aistudio.google.com/app/apikey
/// 2. Tạo file .env (copy từ .env.example)
/// 3. Thêm: GEMINI_API_KEY=your_key_here
class GeminiConfig {
  // Load API key từ .env file
  static String get apiKey =>
      dotenv.get('GEMINI_API_KEY', fallback: 'YOUR_API_KEY_HERE');

  // Model configuration
  static const String modelName = 'gemini-2.5-flash'; // Free tier model

  // Generation config
  static const double temperature = 0.5;

  // gemini-2.5-flash thinks before it answers and those thought tokens are
  // billed against this same budget — a typical Vietnamese wellness question
  // spends ~450-550 on thinking and only ~150 on the reply. At 512 the reply
  // came back cut mid-sentence (finishReason MAX_TOKENS), or empty, which sent
  // the service down to the keyword-matching fallback. 2048 still truncated
  // occasionally: thinking scales with the RAG context and tool results in the
  // prompt, not with the answer, so a heavy turn blows past it.
  //
  // This is a ceiling, not a reservation — an unused budget costs nothing, and
  // the system prompt caps the reply at 6-8 sentences, so the headroom only
  // ever feeds thinking.
  //
  // ponytail: the SDK (google_generative_ai 0.4.7 — the latest published) still
  // cannot send thinkingConfig, so thinking cannot be turned off, only given
  // room. Truncation is rare here, not impossible. Drop this back down if you
  // ever move to raw HTTP and set thinkingBudget: 0.
  static const int maxOutputTokens = 8192;

  // ─── Safety Settings (STRICT) ───────────────────────────────────
  // Use `low` threshold = block when medium or high probability of unsafe.
  // This is the strictest available threshold in google_generative_ai 0.4.x.
  static final List<SafetySetting> safetySettings = [
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.low),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.low),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.low),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.low),
  ];

  // System prompt — delegates to dynamic template
  static String get systemPrompt =>
      SystemPromptTemplate.build();

  // Check if API key is configured
  static bool get isConfigured =>
      apiKey != 'YOUR_API_KEY_HERE' && apiKey.isNotEmpty;
}
