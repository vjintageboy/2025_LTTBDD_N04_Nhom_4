import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/core/providers/chatbot_provider.dart';

void main() {
  group('ChatbotProvider.titleFromMessage', () {
    test('cắt ở dấu câu đầu tiên', () {
      expect(
        ChatbotProvider.titleFromMessage(
          'Tôi hay mất ngủ mấy hôm nay. Có cách nào không?',
        ),
        'Tôi hay mất ngủ mấy hôm nay',
      );
    });

    test('gộp xuống dòng và không cắt giữa từ', () {
      final title = ChatbotProvider.titleFromMessage(
        'Dạo này tôi thấy rất căng thẳng\nvì công việc và không biết phải làm gì để bình tĩnh lại',
      );
      expect(title.length, lessThanOrEqualTo(61));
      expect(title, endsWith('…'));
      expect(title, isNot(contains('\n')));
    });

    test('tin nhắn rỗng vẫn có tên', () {
      expect(ChatbotProvider.titleFromMessage('   '), 'Cuộc trò chuyện');
    });
  });
}
