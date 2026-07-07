import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/core/config/system_prompt.dart';

void main() {
  group('SystemPromptTemplate.build — placeholder replacement', () {
    test('replaces all placeholders when provided', () {
      final prompt = SystemPromptTemplate.build(
        userName: 'Nguyen Van A',
        userRole: 'Admin',
        currentMood: 'sad',
        chatHistory: 'User: Hello\nAssistant: Hi there',
        language: 'en',
        timeOfDay: 'morning',
      );

      expect(prompt.contains('Nguyen Van A'), isTrue,
          reason: 'userName should be injected');
      expect(prompt.contains('Admin'), isTrue,
          reason: 'userRole should be injected');
      expect(prompt.contains('sad'), isTrue,
          reason: 'currentMood should be injected');
      expect(prompt.contains('User: Hello'), isTrue,
          reason: 'chatHistory should be injected');
      expect(prompt.contains('en'), isTrue,
          reason: 'language should be injected');
      expect(prompt.contains('morning'), isTrue,
          reason: 'timeOfDay should be injected');
    });

    test('uses defaults when no parameters provided', () {
      final prompt = SystemPromptTemplate.build();

      expect(prompt.contains('bạn'), isTrue,
          reason: 'default userName should be "bạn"');
      expect(prompt.contains('Người dùng'), isTrue,
          reason: 'default userRole should be "Người dùng"');
      expect(prompt.contains('không xác định'), isTrue,
          reason: 'default mood should be "không xác định"');
    });

    test('empty chatHistory shows default message', () {
      final prompt = SystemPromptTemplate.build(chatHistory: '');
      expect(prompt.contains('Chưa có lịch sử trò chuyện'), isTrue,
          reason: 'empty history should show default message');
    });

    test('null chatHistory shows default message', () {
      final prompt = SystemPromptTemplate.build(chatHistory: null);
      expect(prompt.contains('Chưa có lịch sử trò chuyện'), isTrue);
    });

    test('omits timeOfDay when not provided', () {
      final prompt = SystemPromptTemplate.build();
      // Should not contain "[Time:" token when timeOfDay is null
      expect(prompt.contains('[Time:'), isFalse,
          reason: 'timeOfDay block should be omitted when null');
    });

    test('includes timeOfDay when provided', () {
      final prompt = SystemPromptTemplate.build(timeOfDay: 'evening');
      expect(prompt.contains('[Time: evening]'), isTrue,
          reason: 'timeOfDay block should be present');
    });
  });

  group('SystemPromptTemplate.build — content rules', () {
    test('includes base rules about no medical diagnosis', () {
      final prompt = SystemPromptTemplate.build();
      expect(prompt.contains('KHÔNG chẩn đoán y khoa'), isTrue,
          reason: 'base rules should prohibit medical diagnosis');
    });

    test('includes empathy requirement', () {
      final prompt = SystemPromptTemplate.build();
      expect(prompt.contains('đồng cảm'), isTrue,
          reason: 'prompt should require empathetic tone');
    });

    test('includes self-harm response rule', () {
      final prompt = SystemPromptTemplate.build();
      expect(prompt.contains('tự hại'), isTrue,
          reason: 'prompt should include self-harm response rule');
    });

    test('mentions Moodiki features', () {
      final prompt = SystemPromptTemplate.build();
      expect(prompt.contains('Meditation'), isTrue);
      expect(prompt.contains('Mood tracking'), isTrue);
      expect(prompt.contains('Streak'), isTrue);
    });
  });

  group('SystemPromptTemplate.buildEmergency', () {
    test('returns emergency message with hotline numbers', () {
      final emergency = SystemPromptTemplate.buildEmergency();
      expect(emergency.contains('111'), isTrue,
          reason: 'should include child protection hotline');
      expect(emergency.contains('115'), isTrue,
          reason: 'should include emergency hotline');
      expect(emergency.contains('113'), isTrue,
          reason: 'should include Mai Tâm hotline');
    });

    test('emergency message is non-empty and in Vietnamese', () {
      final emergency = SystemPromptTemplate.buildEmergency();
      expect(emergency.isNotEmpty, isTrue);
      expect(
        emergency.contains('Moodiki') || emergency.contains('bạn'),
        isTrue,
        reason: 'should be in Vietnamese',
      );
    });
  });

  group('SystemPromptTemplate.placeholderKeys', () {
    test('returns list of all placeholder keys', () {
      final keys = SystemPromptTemplate.placeholderKeys;
      expect(keys, isA<List<String>>());
      expect(keys.length, greaterThanOrEqualTo(5),
          reason: 'should have at least 5 placeholders');
    });

    test('all placeholder keys use handlebars syntax', () {
      final keys = SystemPromptTemplate.placeholderKeys;
      for (final key in keys) {
        expect(key.startsWith('{{'), isTrue,
            reason: 'placeholder should start with {{');
        expect(key.endsWith('}}'), isTrue,
            reason: 'placeholder should end with }}');
      }
    });
  });

  group('SystemPromptTemplate.build — edge cases', () {
    test('handles unicode characters in userName', () {
      final prompt = SystemPromptTemplate.build(
        userName: 'Nguyễn Văn Á©',
      );
      expect(prompt.contains('Nguyễn Văn Á©'), isTrue);
    });

    test('handles very long chatHistory', () {
      final longHistory = 'A' * 10000;
      final prompt = SystemPromptTemplate.build(chatHistory: longHistory);
      expect(prompt.contains(longHistory), isTrue);
    });

    test('handles special characters in input', () {
      final prompt = SystemPromptTemplate.build(
        userName: 'User <script>alert("xss")</script>',
      );
      // Should contain the name (we trust upstream sanitization)
      expect(prompt.contains('User'), isTrue);
    });

    test('handles empty strings for all params', () {
      final prompt = SystemPromptTemplate.build(
        userName: '',
        userRole: '',
        currentMood: '',
        chatHistory: '',
        language: '',
        timeOfDay: '',
      );
      // Should not crash and produce valid output
      expect(prompt.isNotEmpty, isTrue);
    });

    test('Vietnamese diacritics in mood preserved', () {
      final prompt = SystemPromptTemplate.build(currentMood: 'buồn bã');
      expect(prompt.contains('buồn bã'), isTrue);
    });
  });

  group('SystemPromptTemplate.build — context structure', () {
    test('contains User/Role/Mood/Lang metadata line', () {
      final prompt = SystemPromptTemplate.build(
        userName: 'Test',
        userRole: 'User',
        currentMood: 'happy',
        language: 'vi',
      );
      expect(prompt.contains('[User: Test | Role: User | Mood: happy | Lang: vi]'), isTrue);
    });

    test('contains History section header', () {
      final prompt = SystemPromptTemplate.build(chatHistory: 'User: hi');
      expect(prompt.contains('[History]'), isTrue);
      expect(prompt.contains('User: hi'), isTrue);
    });
  });
}
