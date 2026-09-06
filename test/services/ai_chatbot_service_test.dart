import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/services/ai_chatbot_service.dart';

void main() {
  test('sliceStream never cuts an emoji in half and reproduces the text', () async {
    // Emoji sit exactly on the 12-code-unit slice boundaries.
    const text = 'Nghe có vẻ 💙 hôm nay 🌱 là một ngày 😊 nặng với bạn 🧘‍♀️ nhé.';
    final slices = await AIChatbotService.sliceStream(text).toList();

    expect(slices.join(), text);
    var shown = '';
    for (final s in slices) {
      shown += s;
      // What the provider renders after each chunk must be valid UTF-16.
      expect((shown.codeUnitAt(shown.length - 1) & 0xFC00) == 0xD800, isFalse,
          reason: 'lone high surrogate after "$shown"');
    }
  });
}
