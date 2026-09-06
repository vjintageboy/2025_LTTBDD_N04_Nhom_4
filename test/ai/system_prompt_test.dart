import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/core/config/system_prompt.dart';

void main() {
  group('SystemPromptTemplate.build', () {
    final prompt = SystemPromptTemplate.build();

    test('describes the report tool with its real return fields', () {
      expect(prompt, contains('generate_monthly_report'));
      for (final field in [
        'period',
        'entries_count',
        'average_mood_score',
        'trend',
        'most_common_factors',
      ]) {
        expect(prompt, contains(field), reason: 'tool field $field');
      }
      expect(prompt, contains('không có dữ liệu streak'),
          reason: 'must not promise streak data the tool never returns');
    });

    test('asks for plain text because the chat bubble renders bare Text()', () {
      expect(prompt, contains('không hiển thị markdown'));
    });

    test('states an explicit length rule', () {
      expect(prompt, contains('2 đến 4 câu'));
    });

    test('explains the meditation shortlist so 3 titles are not the library',
        () {
      expect(prompt, contains('POPULAR'));
      expect(prompt, contains('Shortlist only'));
      expect(prompt, contains('danh sách rút gọn'));
      expect(prompt, contains('không mở hay phát được bài thiền'));
    });

    test('keeps the AI honest about being an AI and not a clinician', () {
      expect(prompt, contains('trợ lý AI'));
      expect(prompt, contains('không thay thế chuyên gia'));
    });

    test('has a crisis section that stays in the conversation', () {
      expect(prompt, contains('tự tử'));
      expect(prompt, contains('Ở lại trò chuyện'));
    });

    test('explains the per-turn <context> block', () {
      expect(prompt, contains('<context>'));
      expect(prompt, contains('Hôm nay'));
    });
  });

  group('SystemPromptTemplate.buildEmergency', () {
    final emergency = SystemPromptTemplate.buildEmergency();

    test('lists verified Vietnamese hotlines', () {
      expect(emergency, contains('115'));
      expect(emergency, contains('111'));
      expect(emergency, contains('113'));
      expect(emergency, contains('096 306 1414'),
          reason: 'Đường dây nóng Ngày Mai');
    });

    test('does not carry the VieON customer-care number', () {
      expect(emergency, isNot(contains('1800 599 920')));
      expect(SystemPromptTemplate.build(), isNot(contains('1800 599 920')));
    });

    test('is in Vietnamese and stays present', () {
      expect(emergency, contains('bạn'));
      expect(emergency, contains('Mình vẫn ở đây'));
    });
  });
}
