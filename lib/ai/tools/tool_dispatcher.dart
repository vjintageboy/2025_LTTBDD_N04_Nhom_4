import 'dart:developer' as developer;

/// Routes Gemini FunctionCall names to actual service calls.
///
/// All service operations are injected as function callbacks so the dispatcher
/// remains fully testable without a live Supabase connection.
class ToolDispatcher {
  /// Generates all candidate time slots between start/end at the given interval.
  final List<String> Function({
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) generateTimeSlots;

  /// Returns mood entries for a user within a date range.
  final Future<List<Map<String, dynamic>>> Function(
    String userId,
    DateTime start,
    DateTime end,
  ) getMoodEntries;

  /// The authenticated user's ID.
  final String userId;

  static const int _maxRetries = 2;

  const ToolDispatcher({
    required this.generateTimeSlots,
    required this.getMoodEntries,
    required this.userId,
  });

  // ---------------------------------------------------------------------------
  // Public entry point
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> dispatch(
    String toolName,
    Map<String, Object?> args,
  ) async {
    final stopwatch = Stopwatch()..start();
    Map<String, Object?> result;
    int attempt = 0;

    while (true) {
      try {
        result = await _executeWithTimeout(toolName, args);
        break;
      } catch (e) {
        attempt++;
        if (attempt > _maxRetries) {
          result = {'error': e.toString(), 'retries_exhausted': true};
          break;
        }
        await Future.delayed(Duration(seconds: attempt)); // 1s, 2s
      }
    }

    stopwatch.stop();
    _log(toolName, args, result, stopwatch.elapsedMilliseconds);
    return result;
  }

  // ---------------------------------------------------------------------------
  // Timeout wrapper + routing
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _executeWithTimeout(
    String toolName,
    Map<String, Object?> args,
  ) {
    final Future<Map<String, Object?>> future = switch (toolName) {
      'generate_monthly_report' => _generateReport(args),
      _ => throw ArgumentError('Unknown tool: $toolName'),
    };
    return future.timeout(const Duration(seconds: 10));
  }

  // ---------------------------------------------------------------------------
  // Handler: generate_monthly_report
  // ---------------------------------------------------------------------------

  Future<Map<String, Object?>> _generateReport(
    Map<String, Object?> args,
  ) async {
    final monthRaw = args['month'] as num?;
    if (monthRaw == null) {
      return {'error': 'MISSING_ARG', 'arg': 'month'};
    }
    final month = monthRaw.toInt();
    final yearRaw = args['year'] as num?;
    if (yearRaw == null) {
      return {'error': 'MISSING_ARG', 'arg': 'year'};
    }
    final year = yearRaw.toInt();

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    // Query mood entries
    final entries = await getMoodEntries(userId, start, end);

    // Compute mood stats
    double averageMoodScore = 0.0;
    String trend = 'stable';

    if (entries.isNotEmpty) {
      final scores = entries
          .map((e) => (e['mood_score'] as num?)?.toDouble() ?? 0.0)
          .toList();

      final sum = scores.fold(0.0, (a, b) => a + b);
      averageMoodScore =
          double.parse((sum / scores.length).toStringAsFixed(1));

      // Trend: compare first half vs second half
      final mid = scores.length ~/ 2;
      final firstHalf = scores.sublist(0, mid);
      final secondHalf = scores.sublist(mid);

      if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
        final firstAvg =
            firstHalf.fold(0.0, (a, b) => a + b) / firstHalf.length;
        final secondAvg =
            secondHalf.fold(0.0, (a, b) => a + b) / secondHalf.length;

        if (secondAvg > firstAvg + 0.2) {
          trend = 'improving';
        } else if (firstAvg > secondAvg + 0.2) {
          trend = 'declining';
        }
      }
    }

    // Most common factors (top 3)
    final factorCounts = <String, int>{};
    for (final entry in entries) {
      final rawFactors = entry['emotion_factors'];
      if (rawFactors is List) {
        for (final factor in rawFactors) {
          final key = factor.toString();
          factorCounts[key] = (factorCounts[key] ?? 0) + 1;
        }
      }
    }
    final sortedFactors = factorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostCommonFactors =
        sortedFactors.take(3).map((e) => e.key).toList();

    return {
      'period': '$year-${month.toString().padLeft(2, '0')}',
      'entries_count': entries.length,
      'average_mood_score': averageMoodScore,
      'trend': trend,
      'most_common_factors': mostCommonFactors,
    };
  }

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  void _log(
    String toolName,
    Map<String, Object?> args,
    Map<String, Object?> result,
    int latencyMs,
  ) {
    final payload = {
      'tool': toolName,
      'user_id': userId,
      'args': args,
      'result': result,
      'latency_ms': latencyMs,
    }.toString();

    developer.log(
      payload,
      name: 'ToolDispatcher',
      error: result.containsKey('error') ? result['error'] : null,
    );
  }
}
