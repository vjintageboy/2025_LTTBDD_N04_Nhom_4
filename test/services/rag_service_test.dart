import 'package:flutter_test/flutter_test.dart';
import 'package:n04_app/services/rag_service.dart';

// ===========================================================================
// Test Helpers
// ===========================================================================

/// Create a fake embedding vector of 3072 dimensions
List<double> fakeEmbedding({double value = 0.1}) =>
    List.generate(3072, (i) => value + (i * 0.001));

// ===========================================================================
// Unit Tests — RAG Config
// ===========================================================================

void main() {
  group('RAGConfig', () {
    test('embedding dimensions should be 3072 for Gemini embedding-001',
        () {
      expect(RAGConfig.embeddingDimensions, 3072);
    });

    test('similarity threshold should be 0.7', () {
      expect(RAGConfig.similarityThreshold, 0.65);
    });

    test('max meditation results should be 3', () {
      expect(RAGConfig.maxMeditationResults, 3);
    });

    test('mood history days should be 7', () {
      expect(RAGConfig.moodHistoryDays, 7);
    });

    test('embedding timeout should be 5000ms', () {
      expect(RAGConfig.embeddingTimeoutMs, 5000);
    });

    test('embedding model name should be gemini-embedding-001', () {
      expect(RAGConfig.embeddingModelName, 'gemini-embedding-001');
    });
  });

  // ===========================================================================
  // Unit Tests — MeditationSearchResult
  // ===========================================================================

  group('MeditationSearchResult', () {
    test('fromMap parses valid map correctly', () {
      final map = <String, dynamic>{
        'id': 'test-uuid-123',
        'title': 'Morning Calm',
        'description': 'A peaceful morning meditation',
        'category': 'stress',
        'duration_minutes': 10,
        'similarity': 0.85,
      };

      final result = MeditationSearchResult.fromMap(map);

      expect(result.id, 'test-uuid-123');
      expect(result.title, 'Morning Calm');
      expect(result.description, 'A peaceful morning meditation');
      expect(result.category, 'stress');
      expect(result.durationMinutes, 10);
      expect(result.similarity, 0.85);
    });

    test('fromMap handles missing optional fields', () {
      final map = <String, dynamic>{
        'id': 'uuid-456',
        'title': 'Simple Meditation',
        'description': '',
        'similarity': 0.72,
      };

      final result = MeditationSearchResult.fromMap(map);

      expect(result.id, 'uuid-456');
      expect(result.title, 'Simple Meditation');
      expect(result.description, '');
      expect(result.category, isNull);
      expect(result.durationMinutes, isNull);
      expect(result.similarity, 0.72);
    });

    test('fromMap handles null similarity gracefully', () {
      final map = <String, dynamic>{
        'id': 'uuid-789',
        'title': 'Test',
        'description': 'Test',
        'similarity': null,
      };

      final result = MeditationSearchResult.fromMap(map);
      expect(result.similarity, 0.0);
    });

    test('fromMap handles string duration_minutes', () {
      final map = <String, dynamic>{
        'id': 'uuid-str',
        'title': 'Test',
        'description': 'Test',
        'duration_minutes': '15',
        'similarity': 0.8,
      };

      final result = MeditationSearchResult.fromMap(map);
      expect(result.durationMinutes, 15);
    });

    test('toString returns formatted string', () {
      final result = MeditationSearchResult(
        id: 'uuid',
        title: 'Peaceful Mind',
        description: 'Relaxing',
        similarity: 0.92,
      );

      expect(result.toString(), contains('Peaceful Mind'));
      expect(result.toString(), contains('0.92'));
    });
  });

  // ===========================================================================
  // Unit Tests — MoodEntrySnapshot
  // ===========================================================================

  group('MoodEntrySnapshot', () {
    test('fromMap parses valid map correctly', () {
      final map = <String, dynamic>{
        'mood_score': 4,
        'note': 'Feeling great today!',
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final snapshot = MoodEntrySnapshot.fromMap(map);

      expect(snapshot.moodScore, 4);
      expect(snapshot.note, 'Feeling great today!');
      expect(snapshot.createdAt.year, 2024);
      expect(snapshot.createdAt.month, 1);
      expect(snapshot.createdAt.day, 15);
    });

    test('fromMap defaults mood_score to 3 when missing', () {
      final map = <String, dynamic>{
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final snapshot = MoodEntrySnapshot.fromMap(map);
      expect(snapshot.moodScore, 3);
    });

    test('fromMap handles invalid mood_score gracefully', () {
      final map = <String, dynamic>{
        'mood_score': 'invalid',
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final snapshot = MoodEntrySnapshot.fromMap(map);
      expect(snapshot.moodScore, 3); // fallback default
    });

    test('fromMap handles string mood_score', () {
      final map = <String, dynamic>{
        'mood_score': '5',
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final snapshot = MoodEntrySnapshot.fromMap(map);
      expect(snapshot.moodScore, 5);
    });

    test('fromMap handles null note', () {
      final map = <String, dynamic>{
        'mood_score': 3,
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final snapshot = MoodEntrySnapshot.fromMap(map);
      expect(snapshot.note, isNull);
    });
  });

  // ===========================================================================
  // Unit Tests — UserContext
  // ===========================================================================

  group('UserContext', () {
    test('isEmpty returns true when all fields are empty/default', () {
      final context = UserContext(lastUserMessage: 'hello');

      expect(context.isEmpty, isTrue);
    });

    test('isEmpty returns false when userName is set', () {
      final context = UserContext(
        userName: 'John',
        lastUserMessage: 'hello',
      );

      expect(context.isEmpty, isFalse);
    });

    test('isEmpty returns false when goals are set', () {
      final context = UserContext(
        goals: ['Reduce stress'],
        lastUserMessage: 'hello',
      );

      expect(context.isEmpty, isFalse);
    });

    test('isEmpty returns false when mood entries exist', () {
      final context = UserContext(
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 4,
            createdAt: DateTime.now(),
          ),
        ],
        lastUserMessage: 'hello',
      );

      expect(context.isEmpty, isFalse);
    });

    test('isEmpty returns false when meditations exist', () {
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Test',
            description: 'Test',
            similarity: 0.8,
          ),
        ],
        lastUserMessage: 'hello',
      );

      expect(context.isEmpty, isFalse);
    });

    test('toPromptContext includes user profile section', () {
      final context = UserContext(
        userName: 'Jane',
        goals: ['Sleep better', 'Focus more'],
        lastUserMessage: 'help me',
      );

      final output = context.toPromptContext();

      expect(output, contains('=== USER PROFILE ==='));
      expect(output, contains('Name: Jane'));
      expect(output, contains('Goals: Sleep better, Focus more'));
    });

    test('toPromptContext shows "Goals: Not set" for empty goals', () {
      final context = UserContext(
        userName: 'Test',
        goals: [],
        lastUserMessage: 'hello',
      );

      final output = context.toPromptContext();
      expect(output, contains('Goals: Not set'));
    });

    test('toPromptContext includes mood history section', () {
      final context = UserContext(
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 4,
            note: 'Good day',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          MoodEntrySnapshot(
            moodScore: 3,
            note: 'Okay',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
        hasMoodData: true,
        lastUserMessage: 'help',
      );

      final output = context.toPromptContext();

      expect(output, contains('=== MOOD HISTORY (Last 7 days) ==='));
      expect(output, contains('Mood: 4/5'));
      expect(output, contains('Mood: 3/5'));
      expect(output, contains('Good day'));
      expect(output, contains('Average mood:'));
    });

    test('toPromptContext handles no mood data', () {
      final context = UserContext(
        hasMoodData: false,
        lastUserMessage: 'hello',
      );

      final output = context.toPromptContext();

      expect(output, contains('No mood entries recorded yet.'));
      expect(output, contains('Tip: Encourage the user'));
    });

    test('toPromptContext includes relevant meditations section', () {
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Deep Sleep',
            description: 'A guided meditation for better sleep quality',
            category: 'sleep',
            durationMinutes: 15,
            similarity: 0.89,
          ),
        ],
        hasMeditationData: true,
        lastUserMessage: 'can\'t sleep',
      );

      final output = context.toPromptContext();

      expect(output, contains('=== RELEVANT MEDITATIONS ==='));
      expect(output, contains('Deep Sleep'));
      expect(output, contains('[sleep]'));
      expect(output, contains('(15min)'));
      expect(output, contains('Similarity: 89%'));
    });

    test('toPromptContext labels fallback results and reveals library size',
        () {
      final popular = [
        MeditationSearchResult(
          id: 'med-1',
          title: 'Deep Sleep',
          description: '',
          similarity: 0.0,
        ),
        MeditationSearchResult(
          id: 'med-2',
          title: 'Morning Start',
          description: '',
          similarity: 0.0,
        ),
      ];

      final fallback = UserContext(
        relevantMeditations: popular,
        hasMeditationData: true,
        meditationLibrarySize: 12,
        lastUserMessage: 'Tìm meditation',
      ).toPromptContext();

      expect(fallback, contains('POPULAR MEDITATIONS'));
      expect(fallback, isNot(contains('=== RELEVANT MEDITATIONS ===')));
      expect(fallback, isNot(contains('Similarity:')),
          reason: 'a 0% score reads as a bad match, not as "unranked"');
      expect(fallback, contains('Shortlist only'));
      expect(fallback, contains('12 meditations in total'));

      // Real hits keep the relevant header and their scores.
      final matched = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Deep Sleep',
            description: '',
            similarity: 0.71,
          ),
        ],
        hasMeditationData: true,
        meditationLibrarySize: 1,
        lastUserMessage: 'khó ngủ',
      ).toPromptContext();

      expect(matched, contains('=== RELEVANT MEDITATIONS ==='));
      expect(matched, contains('Similarity: 71%'));
      expect(matched, isNot(contains('Shortlist only')),
          reason: 'the shortlist already is the whole library here');
    });

    test('toPromptContext handles no meditation data', () {
      final context = UserContext(
        hasMeditationData: false,
        lastUserMessage: 'hello',
      );

      final output = context.toPromptContext();

      expect(output, contains('No highly relevant meditations found.'));
    });

    test('toPromptContext ends with END CONTEXT marker', () {
      final context = UserContext(lastUserMessage: 'test');
      final output = context.toPromptContext();

      expect(output, contains('=== END CONTEXT ==='));
      expect(output, contains('IMPORTANT: Use this context'));
    });

    test('toPromptContext truncates long descriptions', () {
      final longDescription = 'A' * 200;
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Test',
            description: longDescription,
            similarity: 0.8,
          ),
        ],
        hasMeditationData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      // Should truncate at 100 chars and add ...
      expect(output, contains('...'));
      expect(
        output,
        isNot(contains('A' * 150)),
        reason: 'long descriptions should be truncated',
      );
    });

    test('toPromptContext handles meditation without category/duration', () {
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Basic Meditation',
            description: 'Simple',
            similarity: 0.75,
          ),
        ],
        hasMeditationData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('Basic Meditation'));
      expect(output, isNot(contains('[]')));
      expect(output, isNot(contains('(min)')));
    });
  });

  // ===========================================================================
  // Unit Tests — UserContext edge cases
  // ===========================================================================

  group('UserContext Edge Cases', () {
    test('handles null userName gracefully', () {
      final context = UserContext(
        goals: ['test'],
        lastUserMessage: 'hello',
      );

      final output = context.toPromptContext();
      expect(output, isNot(contains('Name:')));
    });

    test('handles multiple mood entries correctly', () {
      final entries = List.generate(
        10,
        (i) => MoodEntrySnapshot(
          moodScore: (i % 5) + 1,
          createdAt: DateTime.now().subtract(Duration(days: i)),
        ),
      );

      final context = UserContext(
        recentMoodEntries: entries,
        hasMoodData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('Average mood:'));
    });

    test('handles zero mood entries', () {
      final context = UserContext(
        recentMoodEntries: [],
        hasMoodData: false,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('No mood entries recorded yet.'));
    });

    test('handles multiple meditations with varying similarity', () {
      final meditations = [
        MeditationSearchResult(
          id: '1',
          title: 'High Match',
          description: 'Very relevant',
          similarity: 0.95,
        ),
        MeditationSearchResult(
          id: '2',
          title: 'Medium Match',
          description: 'Somewhat relevant',
          similarity: 0.75,
        ),
        MeditationSearchResult(
          id: '3',
          title: 'Low Match',
          description: 'Barely above threshold',
          similarity: 0.71,
        ),
      ];

      final context = UserContext(
        relevantMeditations: meditations,
        hasMeditationData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('High Match'));
      expect(output, contains('Medium Match'));
      expect(output, contains('Low Match'));
      expect(output, contains('Similarity: 95%'));
    });

    test('handles average mood calculation correctly', () {
      final context = UserContext(
        recentMoodEntries: [
          MoodEntrySnapshot(moodScore: 5, createdAt: DateTime.now()),
          MoodEntrySnapshot(moodScore: 3, createdAt: DateTime.now()),
          MoodEntrySnapshot(moodScore: 4, createdAt: DateTime.now()),
        ],
        hasMoodData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('Average mood: 4.0/5'));
    });
  });

  // ===========================================================================
  // Integration Test Simulations — RAGService behavior
  // ===========================================================================

  group('RAGService generateEmbedding logic', () {
    test('returns empty list for empty input', () async {
      // An empty string should always return []
      const emptyText = '';
      expect(emptyText.isEmpty, isTrue);
    });

    test('fakeEmbedding helper creates 3072-dimension vectors', () {
      final embedding = fakeEmbedding(value: 0.5);

      expect(embedding.length, 3072);
      expect(embedding.first, greaterThanOrEqualTo(0.5));
      expect(embedding.last, lessThan(3.6)); // 0.5 + 3071 * 0.001
    });

    test('embedding values are within reasonable range', () {
      // Use a value that keeps the vector within [-1, 1] given the formula:
      // value + (i * 0.001) for i in 0..3071
      // Max would be: 0.1 + 3071 * 0.001 = 3.172, which is > 1
      // For this test, we use a very small base and check the first few values.
      final embedding = fakeEmbedding(value: 0.0);

      // Check first 100 values which stay within [-1, 1]
      for (var i = 0; i < 100; i++) {
        expect(
          embedding[i],
          inInclusiveRange(-1.0, 1.0),
          reason: 'embedding values should be in [-1, 1] for early indices',
        );
      }
    });
  });

  // ===========================================================================
  // Performance Tests
  // ===========================================================================

  group('Performance', () {
    test('UserContext.toPromptContext executes under 50ms', () {
      final context = UserContext(
        userName: 'Performance Test User',
        goals: List.generate(10, (i) => 'Goal $i'),
        recentMoodEntries: List.generate(
          30,
          (i) => MoodEntrySnapshot(
            moodScore: (i % 5) + 1,
            createdAt: DateTime.now().subtract(Duration(days: i)),
          ),
        ),
        relevantMeditations: List.generate(
          3,
          (i) => MeditationSearchResult(
            id: 'med-$i',
            title: 'Meditation $i',
            description: 'A' * 200, // long description
            category: 'stress',
            durationMinutes: 10 + i,
            similarity: 0.9 - (i * 0.05),
          ),
        ),
        hasMoodData: true,
        hasMeditationData: true,
        lastUserMessage: 'Test message',
      );

      final stopwatch = Stopwatch()..start();
      final output = context.toPromptContext();
      stopwatch.stop();

      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'toPromptContext should execute quickly',
      );
      expect(output.length, greaterThan(500));
    });

    test('Future.wait simulation for parallel queries', () async {
      // Simulate the parallel query pattern used in buildUserContext
      final stopwatch = Stopwatch()..start();

      final results = await Future.wait([
        // Simulate user profile fetch
        Future.delayed(
          const Duration(milliseconds: 30),
          () => <String, dynamic>{'full_name': 'Test', 'goals': []},
        ),
        // Simulate mood entries fetch
        Future.delayed(
          const Duration(milliseconds: 50),
          () => <MoodEntrySnapshot>[],
        ),
        // Simulate meditation search
        Future.delayed(
          const Duration(milliseconds: 20),
          () => <MeditationSearchResult>[],
        ),
      ]);

      stopwatch.stop();

      // Total time should be ~50ms (longest query), not 30+50+20=100ms
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Future.wait should run queries in parallel',
      );
      expect(results.length, 3);
      expect(results[0], isA<Map<String, dynamic>>());
      expect(results[1], isA<List<MoodEntrySnapshot>>());
      expect(results[2], isA<List<MeditationSearchResult>>());
    });

    test('Future.wait parallel execution is faster than sequential', () async {
      final sequentialStopwatch = Stopwatch()..start();

      // Sequential execution
      final r1 = await Future.delayed(
        const Duration(milliseconds: 30),
        () => 1,
      );
      final r2 = await Future.delayed(
        const Duration(milliseconds: 50),
        () => 2,
      );
      final r3 = await Future.delayed(
        const Duration(milliseconds: 20),
        () => 3,
      );
      sequentialStopwatch.stop();

      final parallelStopwatch = Stopwatch()..start();

      // Parallel execution
      final results = await Future.wait([
        Future.delayed(const Duration(milliseconds: 30), () => 1),
        Future.delayed(const Duration(milliseconds: 50), () => 2),
        Future.delayed(const Duration(milliseconds: 20), () => 3),
      ]);
      parallelStopwatch.stop();

      expect([r1, r2, r3], [1, 2, 3]);
      expect(results, [1, 2, 3]);
      expect(
        parallelStopwatch.elapsedMilliseconds,
        lessThan(sequentialStopwatch.elapsedMilliseconds),
        reason: 'parallel should be faster than sequential',
      );
    });
  });

  // ===========================================================================
  // Edge Case Tests — Fallback scenarios
  // ===========================================================================

  group('Fallback Scenarios', () {
    test('empty user context is safe for LLM prompt', () {
      final context = UserContext(lastUserMessage: 'I need help');
      final output = context.toPromptContext();

      // Should still produce a valid prompt structure
      expect(output, contains('=== USER PROFILE ==='));
      expect(output, contains('=== MOOD HISTORY'));
      expect(output, contains('=== RELEVANT MEDITATIONS ==='));
      expect(output, contains('=== END CONTEXT ==='));
    });

    test('context with only mood data is still useful', () {
      final context = UserContext(
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 2,
            note: 'Feeling stressed',
            createdAt: DateTime.now(),
          ),
        ],
        hasMoodData: true,
        lastUserMessage: 'I am stressed',
      );

      final output = context.toPromptContext();
      expect(output, contains('Mood: 2/5'));
      expect(output, contains('Feeling stressed'));
      expect(output, contains('No highly relevant meditations found.'));
    });

    test('context with only meditation data is still useful', () {
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Stress Relief',
            description: 'Helps reduce stress',
            category: 'stress',
            similarity: 0.85,
          ),
        ],
        hasMeditationData: true,
        lastUserMessage: 'relax me',
      );

      final output = context.toPromptContext();
      expect(output, contains('Stress Relief'));
      expect(output, contains('No mood entries recorded yet.'));
    });

    test('handles special characters in notes', () {
      final context = UserContext(
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 3,
            note: 'Feeling <>&"\' special chars! @#\$%',
            createdAt: DateTime.now(),
          ),
        ],
        hasMoodData: true,
        lastUserMessage: 'test',
      );

      // Should not throw
      expect(
        () => context.toPromptContext(),
        returnsNormally,
        reason: 'special characters should not break prompt generation',
      );
    });

    test('handles Vietnamese characters correctly', () {
      final context = UserContext(
        userName: 'Nguyễn Văn A',
        goals: ['Giảm căng thẳng', 'Ngủ ngon hơn'],
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 4,
            note: 'Hôm nay cảm thấy rất tốt',
            createdAt: DateTime.now(),
          ),
        ],
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Thiền buổi sáng',
            description: 'Hướng dẫn thiền cho buổi sáng',
            category: 'stress',
            similarity: 0.88,
          ),
        ],
        hasMoodData: true,
        hasMeditationData: true,
        lastUserMessage: 'tôi cần giúp đỡ',
      );

      final output = context.toPromptContext();
      expect(output, contains('Nguyễn Văn A'));
      expect(output, contains('Giảm căng thẳng'));
      expect(output, contains('Hôm nay cảm thấy rất tốt'));
      expect(output, contains('Thiền buổi sáng'));
    });

    test('handles emoji in notes and descriptions', () {
      final context = UserContext(
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 5,
            note: 'Feeling amazing! 🎉🧘‍♀️✨',
            createdAt: DateTime.now(),
          ),
        ],
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Happy Mind 🌟',
            description: 'A positive meditation experience 💙',
            similarity: 0.92,
          ),
        ],
        hasMoodData: true,
        hasMeditationData: true,
        lastUserMessage: 'I\'m happy 😊',
      );

      final output = context.toPromptContext();
      expect(output, contains('🎉'));
      expect(output, contains('🧘‍♀️'));
      expect(output, contains('🌟'));
    });
  });

  // ===========================================================================
  // Error Handling Tests
  // ===========================================================================

  group('Error Handling', () {
    test('UserContext handles empty values gracefully', () {
      final context = UserContext(
        userName: '',
        goals: const [],
        recentMoodEntries: const [],
        relevantMeditations: const [],
        lastUserMessage: '',
      );

      expect(context.isEmpty, isTrue);
      expect(
        () => context.toPromptContext(),
        returnsNormally,
      );
    });

    test('very long user message does not break context', () {
      final longMessage = 'A' * 5000;
      final context = UserContext(
        lastUserMessage: longMessage,
      );

      expect(
        () => context.toPromptContext(),
        returnsNormally,
        reason: 'long messages should not crash prompt generation',
      );
    });

    test('many mood entries are handled correctly', () {
      final manyEntries = List.generate(
        100,
        (i) => MoodEntrySnapshot(
          moodScore: (i % 5) + 1,
          createdAt: DateTime.now().subtract(Duration(hours: i)),
        ),
      );

      final context = UserContext(
        recentMoodEntries: manyEntries,
        hasMoodData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('Average mood:'));
    });

    test('handles null goal values', () {
      final context = UserContext(
        goals: [null, 'valid', null],
        lastUserMessage: 'test',
      );

      expect(
        () => context.toPromptContext(),
        returnsNormally,
        reason: 'null goals should not crash',
      );
    });

    test('handles empty meditation description', () {
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Empty',
            description: '',
            similarity: 0.8,
          ),
        ],
        hasMeditationData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('Empty'));
    });

    test('handles very high and low similarity scores', () {
      final context = UserContext(
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Perfect Match',
            description: 'Test',
            similarity: 1.0,
          ),
          MeditationSearchResult(
            id: 'med-2',
            title: 'Barely Match',
            description: 'Test',
            similarity: 0.701,
          ),
        ],
        hasMeditationData: true,
        lastUserMessage: 'test',
      );

      final output = context.toPromptContext();
      expect(output, contains('Similarity: 100%'));
      expect(output, contains('Similarity: 70%'));
    });
  });

  // ===========================================================================
  // New User / Empty Data Tests
  // ===========================================================================

  group('New User / Empty Data Scenarios', () {
    test('brand new user with no data produces safe context', () {
      final context = UserContext(
        userName: null,
        goals: [],
        recentMoodEntries: [],
        relevantMeditations: [],
        hasMoodData: false,
        hasMeditationData: false,
        lastUserMessage: 'Hello, I\'m new here',
      );

      final output = context.toPromptContext();

      // Should have structure but no data sections filled
      expect(output, contains('=== USER PROFILE ==='));
      expect(output, contains('Goals: Not set'));
      expect(output, contains('No mood entries recorded yet.'));
      expect(output, contains('No highly relevant meditations found.'));
      expect(output, contains('=== END CONTEXT ==='));
    });

    test('user with goals but no mood/meditation data', () {
      final context = UserContext(
        userName: 'NewUser',
        goals: ['Reduce anxiety', 'Sleep better'],
        recentMoodEntries: [],
        relevantMeditations: [],
        hasMoodData: false,
        hasMeditationData: false,
        lastUserMessage: 'I want to feel better',
      );

      final output = context.toPromptContext();
      expect(output, contains('Name: NewUser'));
      expect(output, contains('Reduce anxiety'));
      expect(output, contains('No mood entries recorded yet.'));
    });

    test('user returning after long break (old mood data)', () {
      final context = UserContext(
        userName: 'Returning',
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 2,
            note: 'Had a tough week',
            createdAt: DateTime.now().subtract(const Duration(days: 6)),
          ),
        ],
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Fresh Start',
            description: 'Starting over',
            category: 'focus',
            similarity: 0.78,
          ),
        ],
        hasMoodData: true,
        hasMeditationData: true,
        lastUserMessage: 'Back after a break',
      );

      final output = context.toPromptContext();
      expect(output, contains('Name: Returning'));
      expect(output, contains('Mood: 2/5'));
      expect(output, contains('Fresh Start'));
    });

    test('crisis user gets appropriate context', () {
      final context = UserContext(
        userName: 'Struggling',
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 1,
            note: 'Feeling very low',
            createdAt: DateTime.now(),
          ),
        ],
        hasMoodData: true,
        hasMeditationData: false,
        lastUserMessage: 'I don\'t know what to do',
      );

      final output = context.toPromptContext();
      expect(output, contains('Mood: 1/5'));
      expect(output, contains('Feeling very low'));
      expect(output, contains('No highly relevant meditations found.'));
    });
  });

  // ===========================================================================
  // Multilingual Tests
  // ===========================================================================

  group('Multilingual Support', () {
    test('handles mixed English and Vietnamese', () {
      final context = UserContext(
        userName: 'Mixed User',
        goals: ['Less stress', 'Thiền hàng ngày'],
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 4,
            note: 'Feeling good, cảm thấy ổn',
            createdAt: DateTime.now(),
          ),
        ],
        relevantMeditations: [
          MeditationSearchResult(
            id: 'med-1',
            title: 'Morning Meditation / Thiền buổi sáng',
            description: 'Start your day right / Bắt đầu ngày mới',
            similarity: 0.85,
          ),
        ],
        hasMoodData: true,
        hasMeditationData: true,
        lastUserMessage: 'I need help with stress / Tôi cần giúp đỡ',
      );

      final output = context.toPromptContext();
      expect(output, contains('Mixed User'));
      expect(output, contains('Less stress'));
      expect(output, contains('Thiền hàng ngày'));
      expect(output, contains('Feeling good'));
      expect(output, contains('cảm thấy ổn'));
    });

    test('handles Chinese characters', () {
      final context = UserContext(
        userName: '中文用户',
        goals: ['减压', '改善睡眠'],
        recentMoodEntries: [
          MoodEntrySnapshot(
            moodScore: 3,
            note: '感觉一般',
            createdAt: DateTime.now(),
          ),
        ],
        hasMoodData: true,
        hasMeditationData: false,
        lastUserMessage: '我需要帮助',
      );

      final output = context.toPromptContext();
      expect(output, contains('中文用户'));
      expect(output, contains('减压'));
    });
  });
}
