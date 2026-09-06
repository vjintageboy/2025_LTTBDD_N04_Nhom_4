import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/services/fallback_ai_service.dart';

void main() {
  test('extractText pulls the assistant message', () {
    const body = '{"choices":[{"message":{"role":"assistant",'
        '"content":"  Chào bạn nhé  "}}]}';
    expect(FallbackAIService.extractText(body), 'Chào bạn nhé');
  });

  test('extractText survives error bodies and garbage', () {
    expect(FallbackAIService.extractText('{"error":{"message":"rate limited"}}'), '');
    expect(FallbackAIService.extractText('<html>502</html>'), '');
  });

  test('isTruncated spots finish_reason length only', () {
    const cut = '{"choices":[{"finish_reason":"length",'
        '"message":{"content":"Bạn đã có một tuần khá"}}]}';
    const done = '{"choices":[{"finish_reason":"stop",'
        '"message":{"content":"Bạn đã có một tuần khá tốt."}}]}';
    expect(FallbackAIService.isTruncated(cut), isTrue);
    expect(FallbackAIService.isTruncated(done), isFalse);
    expect(FallbackAIService.isTruncated('<html>502</html>'), isFalse);
  });

  test('models list is parsed and trimmed; no key means disabled', () {
    dotenv.testLoad(fileInput: 'OPENROUTER_MODELS=a/b:free , c/d:free\n');
    expect(FallbackAIService.models, ['a/b:free', 'c/d:free']);
    expect(FallbackAIService.isConfigured, isFalse);

    dotenv.testLoad(fileInput: 'OPENROUTER_API_KEY=sk-x\nOPENROUTER_MODELS=a/b:free\n');
    expect(FallbackAIService.isConfigured, isTrue);
  });
}
