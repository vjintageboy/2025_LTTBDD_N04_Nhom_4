import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/ai/tools/tool_dispatcher.dart';

const _userId = 'user-123';

ToolDispatcher _dispatcher({
  List<String> Function({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  })? generateTimeSlots,
  Future<List<Map<String, dynamic>>> Function(
    String userId,
    DateTime start,
    DateTime end,
  )? getMoodEntries,
  String? userId,
}) {
  return ToolDispatcher(
    generateTimeSlots: generateTimeSlots ??
        ({
          required String startTime,
          required String endTime,
          required int intervalMinutes,
        }) =>
            ['09:00', '10:00', '11:00'],
    getMoodEntries: getMoodEntries ?? (_, __, ___) async => [],
    userId: userId ?? _userId,
  );
}

void main() {
  // ── 1. generate_monthly_report with mood entries ───────────────────────────
  test('1. generate_monthly_report returns correct structure with mood entries',
      () async {
    final entries = [
      {'mood_score': 7, 'emotion_factors': ['work', 'sleep']},
      {'mood_score': 6, 'emotion_factors': ['work', 'family']},
      {'mood_score': 8, 'emotion_factors': ['sleep', 'exercise']},
      {'mood_score': 9, 'emotion_factors': ['exercise', 'work']},
    ];

    final dispatcher = _dispatcher(
      getMoodEntries: (_, __, ___) async => entries,
    );

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 4,
      'year': 2024,
    });

    expect(result['period'], '2024-04');
    expect(result['entries_count'], 4);
    expect(result['average_mood_score'], isA<double>());
    expect(result['trend'], isA<String>());
    expect(result['most_common_factors'], isA<List>());
    final factors = result['most_common_factors'] as List;
    expect(factors.length, lessThanOrEqualTo(3));
    expect(factors, contains('work')); // work appears 3 times (most common)
  });

  // ── 2. generate_monthly_report no entries ────────────────────────────────
  test('2. generate_monthly_report with no entries: 0.0 score, stable trend',
      () async {
    final dispatcher = _dispatcher(
      getMoodEntries: (_, __, ___) async => [],
    );

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 4,
      'year': 2024,
    });

    expect(result['entries_count'], 0);
    expect(result['average_mood_score'], 0.0);
    expect(result['trend'], 'stable');
    expect(result['most_common_factors'], isEmpty);
  });

  // ── 3. generate_monthly_report leap year Feb 2024 ────────────────────────
  test('3. generate_monthly_report Feb 2024 date range includes Feb 29',
      () async {
    DateTime? capturedStart;
    DateTime? capturedEnd;

    final dispatcher = _dispatcher(
      getMoodEntries: (_, start, end) async {
        capturedStart = start;
        capturedEnd = end;
        return [];
      },
    );

    await dispatcher.dispatch('generate_monthly_report', {
      'month': 2,
      'year': 2024,
    });

    expect(capturedStart, isNotNull);
    expect(capturedEnd, isNotNull);
    expect(capturedStart!.year, 2024);
    expect(capturedStart!.month, 2);
    expect(capturedStart!.day, 1);
    expect(capturedEnd!.month, 2);
    expect(capturedEnd!.day, 29); // Leap year — Feb has 29 days
  });

  // ── 4. Unknown tool name → error map, does NOT throw ─────────────────────
  test('4. unknown tool name returns error map and does not throw', () async {
    final dispatcher = _dispatcher();

    final result = await dispatcher.dispatch('nonexistent_tool', {});

    expect(result['error'], isNotNull);
    expect(result.containsKey('retries_exhausted'), isTrue);
  });

  // ── 5. dispatch always returns (log is called) ───────────────────────────
  test('5. dispatch completes and returns a map for every call', () async {
    final dispatcher = _dispatcher();

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 1,
      'year': 2024,
    });

    expect(result, isA<Map<String, Object?>>());
  });

  // ── 6. Retry: first call throws, second succeeds ─────────────────────────
  test('6. retry: first call throws, second succeeds returns success result',
      () async {
    int attempts = 0;
    final dispatcher = _dispatcher(
      getMoodEntries: (_, __, ___) async {
        attempts++;
        if (attempts == 1) throw Exception('transient error');
        return [
          {'mood_score': 5, 'emotion_factors': []},
        ];
      },
    );

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 1,
      'year': 2024,
    });

    expect(result['entries_count'], 1);
    expect(result.containsKey('retries_exhausted'), isFalse);
    expect(attempts, 2);
  });

  // ── 7. Retry exhausted: throws 3 times → retries_exhausted: true ─────────
  test('7. retry exhausted: throws 3 times returns retries_exhausted',
      () async {
    int attempts = 0;
    final dispatcher = _dispatcher(
      getMoodEntries: (_, __, ___) async {
        attempts++;
        throw Exception('persistent error');
      },
    );

    final result = await dispatcher.dispatch('generate_monthly_report', {
      'month': 1,
      'year': 2024,
    });

    expect(result['retries_exhausted'], isTrue);
    expect(result['error'], isNotNull);
    expect(attempts, 3); // 1 initial + 2 retries
  });
}
