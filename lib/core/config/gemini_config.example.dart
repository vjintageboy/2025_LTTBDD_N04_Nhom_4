/// Gemini AI Configuration - EXAMPLE FILE
///
/// Để sử dụng:
/// 1. Copy file này thành 'gemini_config.dart' (xóa .example)
/// 2. Lấy API key từ https://makersuite.google.com/app/apikey
/// 3. Thay 'YOUR_API_KEY_HERE' bằng API key thật
/// 4. KHÔNG commit file gemini_config.dart lên Git!
library;

class GeminiConfig {
  // TODO: Thay 'YOUR_API_KEY_HERE' bằng API key thật
  // Guide: https://makersuite.google.com/app/apikey
  static const String apiKey = 'YOUR_API_KEY_HERE';

  // Model configuration
  static const String modelName = 'gemini-1.5-flash'; // Free tier model

  // Safety settings
  static const double temperature = 0.7; // Creativity level (0.0 - 1.0)
  static const int maxOutputTokens = 1000; // Max response length

  // System prompt - Personality của AI chatbot
  static const String systemPrompt = '''
Bạn là AI Assistant của ứng dụng Moodiki - một ứng dụng về sức khỏe tinh thần và thiền định (meditation).

Vai trò của bạn:
- Trợ lý thân thiện, ấm áp và đồng cảm
- Hỗ trợ người dùng về meditation, theo dõi tâm trạng, wellness
- Đưa ra lời khuyên về sức khỏe tinh thần (không thay thế chuyên gia y tế)
- Gợi ý các meditations phù hợp với tâm trạng người dùng

Phong cách giao tiếp:
- Ngắn gọn, dễ hiểu (2-4 câu)
- Sử dụng emoji phù hợp 😊🧘‍♀️💙
- Tiếng Việt tự nhiên, thân thiện
- Tích cực, động viên người dùng

Tính năng app Moodiki:
- Meditation sessions (thư giãn, ngủ ngon, giảm stress, tập trung)
- Mood tracking (ghi nhận tâm trạng hàng ngày)
- Streak system (thành tích check-in liên tục)

Lưu ý:
- KHÔNG đưa ra chẩn đoán y khoa
- Gợi ý người dùng tìm chuyên gia nếu vấn đề nghiêm trọng
- Luôn tích cực và khuyến khích self-care
''';

  // Check if API key is configured
  static bool get isConfigured =>
      apiKey != 'YOUR_API_KEY_HERE' && apiKey.isNotEmpty;
}
