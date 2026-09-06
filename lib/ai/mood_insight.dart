import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/config/gemini_config.dart';
import '../services/fallback_ai_service.dart';
import '../models/mood_entry.dart';
import 'disclaimer.dart';

/// One-shot AI reading of a period's mood entries.
///
/// Stateless on purpose: the stats are recomputed from [entries] on every call
/// and the result is never persisted, so this needs no schema change.
class MoodInsight {
  static const String _instruction = '''
Bạn là trợ lý sức khoẻ tinh thần của app Moodiki. Người dùng đưa bạn thống kê
tâm trạng của họ trong một khoảng thời gian. Hãy viết một bản đọc ngắn bằng
tiếng Việt, giọng ấm áp, xưng "bạn":

1. **Tổng quan** — 1-2 câu về xu hướng chung.
2. **Điều đáng chú ý** — 2-3 gạch đầu dòng nối yếu tố ảnh hưởng với điểm số.
3. **Gợi ý** — 2 hành động nhỏ, cụ thể, làm được trong tuần tới.

Tối đa 200 từ. Viết văn bản thuần, không dùng markdown — gạch đầu dòng bằng "–",
không dùng "*" hay "#". Chỉ nói những gì dữ liệu cho thấy — không chẩn đoán,
không suy đoán về bệnh lý. Nếu dữ liệu quá ít để kết luận, hãy nói thẳng vậy.''';

  /// Returns the analysis text, or throws if no model could answer.
  static Future<String> analyze({
    required List<MoodEntry> entries,
    required String periodLabel,
  }) async {
    final stats = _buildStats(entries, periodLabel);

    if (GeminiConfig.isConfigured) {
      try {
        final model = GenerativeModel(
          model: GeminiConfig.modelName,
          apiKey: GeminiConfig.apiKey,
          generationConfig: GenerationConfig(
            temperature: GeminiConfig.temperature,
            maxOutputTokens: GeminiConfig.maxOutputTokens,
          ),
          systemInstruction: Content.text(_instruction),
          safetySettings: GeminiConfig.safetySettings,
        );

        final response = await model.generateContent([Content.text(stats)]);

        // A truncated answer reads like a bug to the user — treat it as a
        // failure and let a backup model try instead.
        if (response.candidates.firstOrNull?.finishReason ==
            FinishReason.maxTokens) {
          throw StateError('Câu trả lời bị cắt giữa chừng (hết token budget)');
        }

        final text = response.text?.trim() ?? '';
        if (text.isEmpty) throw StateError('Gemini trả về nội dung rỗng');

        return DisclaimerInjector.maybeAdd(aiResponse: text);
      } catch (e) {
        debugPrint('[MoodInsight] Gemini failed, trying fallback: $e');
      }
    }

    final fallback = await FallbackAIService.complete(
      systemPrompt: _instruction,
      userMessage: stats,
    );
    if (fallback.isEmpty) {
      throw StateError('Không tạo được phân tích lúc này, thử lại sau nhé');
    }
    return DisclaimerInjector.maybeAdd(aiResponse: fallback);
  }

  static String _buildStats(List<MoodEntry> entries, String periodLabel) {
    final sorted = [...entries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final average =
        sorted.fold<int>(0, (s, e) => s + e.moodLevel) / sorted.length;

    final factorCount = <String, int>{};
    for (final e in sorted) {
      for (final f in e.emotionFactors) {
        factorCount[f] = (factorCount[f] ?? 0) + 1;
      }
    }
    final factors = factorCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final buffer = StringBuffer()
      ..writeln('Khoảng thời gian: $periodLabel')
      ..writeln('Số lần ghi: ${sorted.length}')
      ..writeln('Điểm trung bình: ${average.toStringAsFixed(2)}/5')
      ..writeln('Yếu tố ảnh hưởng (số lần xuất hiện): '
          '${factors.take(8).map((e) => '${e.key}=${e.value}').join(', ')}')
      ..writeln('Nhật ký theo ngày (ngày | điểm | ghi chú):');

    // Cap the log so a "year" period can't blow past the token budget.
    for (final e in sorted.length > 40 ? sorted.sublist(sorted.length - 40) : sorted) {
      final d = e.timestamp;
      final note = (e.note ?? '').trim();
      buffer.writeln('${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')} | ${e.moodLevel} | '
          '${note.isEmpty ? '(không ghi chú)' : note}');
    }

    return buffer.toString();
  }
}
