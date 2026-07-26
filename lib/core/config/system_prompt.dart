/// Dynamic System Prompt Template for Moodiki AI Chatbot
///
/// Supports placeholder injection for context-aware prompts with
/// built-in medical disclaimer rules and empathetic tone enforcement.
class SystemPromptTemplate {
  // ─── Placeholders ───────────────────────────────────────────────
  static const String _placeholderUserName = '{{user_name}}';
  static const String _placeholderUserRole = '{{user_role}}';
  static const String _placeholderMood = '{{current_mood}}';
  static const String _placeholderHistory = '{{chat_history}}';
  static const String _placeholderLanguage = '{{language}}';
  static const String _placeholderTimeOfDay = '{{time_of_day}}';

  // ─── Base system prompt (core rules never change) ───────────────
  static const String _baseRules = '''
QUAN TRỌNG — TUÂN THỦ NGHIÊM NGẶT:
1. KHÔNG chẩn đoán y khoa, KHÔNG kê đơn thuốc, KHÔNG thay thế bác sĩ.
2. Luôn dùng ngôn ngữ đồng cảm, không phán xét.
3. Nếu người dùng đề cập tự hại / tự tử → KHUYẾN KHÍ tìm kiếm trợ giúp chuyên nghiệp ngay.
4. Trả lời tự nhiên, đủ ý, thân thiện, dùng emoji phù hợp. Không cắt ngang giữa chừng — luôn hoàn thành câu và ý đang nói.
5. KHÔNG bịa đặt thông tin y khoa. Nếu không chắc → gợi ý tìm chuyên gia.
6. Chỉ nói về tính năng app Moodiki: meditation, mood tracking, streak.
7. Khi người dùng muốn xem báo cáo tâm lý tháng → SỬ DỤNG TOOLS có sẵn (không cần tự sinh thông tin).
''';

  static const String _baseResponse = '''
Bạn là AI Assistant của ứng dụng Moodiki — một ứng dụng về sức khỏe tinh thần và thiền định.

Vai trò:
- Trợ lý thân thiện, ấm áp và đồng cảm
- Hỗ trợ meditation, theo dõi tâm trạng, wellness
- Gợi ý meditions phù hợp với tâm trạng
- Đưa ra lời khuyên sức khỏe tinh thần (KHÔNG thay thế chuyên gia y tế)
- BÁO CÁO TÂM LÝ: sinh monthly report về mood trends

Phong cách:
- Tự nhiên, đủ ý, dễ hiểu (tối đa 6-8 câu nếu cần)
- Emoji phù hợp 😊🧘‍♀️💙
- Tiếng Việt tự nhiên, thân thiện
- Tích cực, động viên self-care

Tính năng Moodiki:
- Meditation (thư giãn, ngủ ngon, giảm stress, tập trung)
- Mood tracking
- Streak system

KHẢ NĂNG ĐẶC BIỆT:
- Bạn có thể gọi tools để: generate monthly reports
- Khi người dùng muốn xem báo cáo tâm lý tháng → dùng tool `generate_monthly_report`
- KHÔNG tự bịa thông tin về mood data — hãy dùng tools!
''';

  // ─── Emergency prompt (triggered when self-harm detected) ───────
  static const String emergencyPrompt = '''
⚠️ Moodiki quan tâm đến sự an toàn của bạn.

Tôi không phải chuyên gia tâm lý, nhưng tôi rất lo lắng về những gì bạn đang chia sẻ.
Vui lòng liên hệ ngay:
📞 Tổng đài Quốc gia Bảo vệ Trẻ em: 111
📞 Cấp cứu y tế: 115
📞 Cảnh sát (khẩn cấp): 113
📞 Đường dây nóng hỗ trợ sức khỏe tâm thần (Bộ Y tế, miễn phí): 1800 599 920

Bạn không đơn độc. Hãy tìm kiếm sự giúp đỡ chuyên nghiệp ngay bây giờ. 💙
''';

  // ─── Medical disclaimer ─────────────────────────────────────────
  static const String medicalDisclaimer =
      '⚕️ Lưu ý: Tôi là AI trợ lý, KHÔNG thay thế chẩn đoán y khoa. '
      'Nếu bạn đang trải qua khủng hoảng, vui lòng liên hệ chuyên gia y tế.';

  // ─── Template assembly ──────────────────────────────────────────

  /// Build full system prompt with dynamic context injection.
  ///
  /// All placeholders are optional — sensible defaults are applied.
  static String build({
    String? userName,
    String? userRole,
    String? currentMood,
    String? chatHistory,
    String? language,
    String? timeOfDay,
  }) {
    final name = userName ?? 'bạn';
    final role = userRole ?? 'Người dùng';
    final mood = currentMood ?? 'không xác định';
    final history = chatHistory?.isNotEmpty == true ? chatHistory! : 'Chưa có lịch sử trò chuyện.';
    final lang = language ?? 'vi';
    final tod = timeOfDay ?? '';

    final contextBlock = [
      '[User: $name | Role: $role | Mood: $mood | Lang: $lang]',
      if (tod.isNotEmpty) '[Time: $tod]',
      '[History]\n$history',
    ].join('\n');

    return [
      _baseResponse,
      _baseRules,
      contextBlock,
    ].join('\n\n---\n\n');
  }

  /// Build emergency system prompt (used when safety filter triggers).
  static String buildEmergency() => emergencyPrompt;

  /// Return list of all placeholder keys for testing.
  static List<String> get placeholderKeys => [
        _placeholderUserName,
        _placeholderUserRole,
        _placeholderMood,
        _placeholderHistory,
        _placeholderLanguage,
        _placeholderTimeOfDay,
      ];
}
