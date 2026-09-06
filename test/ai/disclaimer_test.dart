import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/ai/disclaimer.dart';

void main() {
  String add(String response, [String? input]) =>
      DisclaimerInjector.maybeAdd(aiResponse: response, userInput: input);

  group('DisclaimerInjector — fires on clinical vocabulary', () {
    const reply = 'Mình hiểu, kể mình nghe thêm nhé.';
    for (final input in [
      'Em nghĩ em bị trầm cảm',
      'Em bi tram cam',
      'Em muốn uống thuốc cho hết buồn',
      'Bạn chẩn đoán cho em được không?',
      'Em nghĩ em bị rối loạn',
      'I think I have depression',
      'Should I take medication?',
    ]) {
      test('user input "$input"', () {
        expect(add(reply, input), startsWith('$reply\n\n⚕️'));
      });
    }

    test('clinical words in the reply itself', () {
      expect(add('Đó có thể là triệu chứng cần được xem xét.', 'Hello'),
          contains('⚕️'));
    });
  });

  group('DisclaimerInjector — stays silent', () {
    test('on everyday emotion words', () {
      for (final input in [
        'Em căng thẳng quá',
        'Em hay lo âu lắm',
        'Em bị mất ngủ',
        'I have a lot of stress',
        'hôm nay em khóc nhiều',
      ]) {
        expect(add('Mình ở đây nghe bạn.', input), 'Mình ở đây nghe bạn.',
            reason: input);
      }
    });

    test('under a list of meditation titles', () {
      const reply = '1. "Giảm căng thẳng sau giờ làm" (10 phút)\n'
          '2. "Thở sâu 4-7-8 giúp giảm lo âu" (5 phút)';
      expect(add(reply, 'Tìm meditation'), reply);
    });

    test('on "thuộc" — no diacritic stripping', () {
      expect(add('Bài thiền quen thuộc của bạn đây.', 'Gợi ý bài quen thuộc'),
          'Bài thiền quen thuộc của bạn đây.');
    });

    test('when the reply already refers out or names itself AI', () {
      for (final reply in [
        'Bạn nên hỏi bác sĩ về thuốc.',
        'Mình là trợ lý AI, chuyện thuốc bạn hỏi chuyên gia nhé.',
        'Please talk to a doctor about medication.',
      ]) {
        expect(add(reply, 'Em muốn uống thuốc'), reply, reason: reply);
      }
    });

    test('does not duplicate itself', () {
      final once = add('Trả lời.', 'Em bị trầm cảm');
      expect(add(once, 'Em bị trầm cảm'), once);
      expect('⚕️'.allMatches(once).length, 1);
    });

    test('leaves empty, whitespace and null-input replies alone', () {
      expect(add('', 'Em bị trầm cảm'), '');
      expect(add('   ', 'Em bị trầm cảm'), '   ');
      expect(add('Normal response', null), 'Normal response');
    });
  });

  group('DisclaimerInjector — text', () {
    test('plain text in the prompt voice, with the emergency number', () {
      final notice = add('Trả lời.', 'Em bị trầm cảm').substring('Trả lời.'.length);
      expect(notice, startsWith('\n\n⚕️ '));
      expect(notice, contains('Mình là trợ lý AI'));
      expect(notice, contains('115'));
      expect(notice, isNot(contains('_')));
      expect(notice, isNot(contains('**')));
      expect(notice, isNot(contains('Tôi')));
    });
  });
}
