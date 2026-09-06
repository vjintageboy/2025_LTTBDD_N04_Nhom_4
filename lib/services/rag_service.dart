import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ===========================================================================
// RAG (Retrieval-Augmented Generation) Context Builder for Moodiki
//
// This service builds dynamic context from real user data before calling
// the LLM API. It replaces the static chat-history-only approach with
// a rich context including user goals, mood history, and relevant meditations.
//
// Architecture:
//   1. generateEmbedding() — Uses Gemini embedding-001 to convert text
//      into a 3072-dimensional vector.
//   2. searchRelevantMeditations() — Calls Supabase RPC to find meditations
//      with cosine similarity > 0.7 to the query embedding.
//   3. buildUserContext() — Runs 3 queries in parallel (Future.wait) to
//      assemble a complete context object for the LLM prompt.
// ===========================================================================

/// Configuration for the RAG system
class RAGConfig {
  // Gemini embedding model (3072 dimensions)
  static const String embeddingModelName = 'gemini-embedding-001';

  // Embedding dimension count (must match pgvector column definition)
  static const int embeddingDimensions = 3072;

  // Cosine similarity threshold for meditation matching (0.0 to 1.0)
  // Calibrated 2026-09-07 on the 5 seeded meditations with gemini-embedding-001
  // (no task type): right matches for Vietnamese queries scored 0.68–0.78,
  // wrong titles 0.52–0.66, and an off-topic query ("báo cáo tháng này")
  // peaked at 0.63. 0.7 dropped "mình khó ngủ" → "Thiền đi vào giấc ngủ" (0.683).
  // ponytail: re-check once the library grows past a handful of titles.
  static const double similarityThreshold = 0.65;

  // Maximum number of relevant meditations to return
  static const int maxMeditationResults = 3;

  // Number of days of mood history to retrieve
  static const int moodHistoryDays = 7;

  // Timeout for embedding API calls (milliseconds)
  static const int embeddingTimeoutMs = 5000;

  // Get Gemini API key from dotenv
  static String get embeddingApiKey =>
      dotenv.get('GEMINI_API_KEY', fallback: '');

  static bool get isConfigured =>
      embeddingApiKey.isNotEmpty && embeddingApiKey != 'YOUR_API_KEY_HERE';
}

/// Result of a meditation vector search
class MeditationSearchResult {
  final String id;
  final String title;
  final String description;
  final String? category;
  final int? durationMinutes;
  final double similarity;

  MeditationSearchResult({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    this.durationMinutes,
    required this.similarity,
  });

  factory MeditationSearchResult.fromMap(Map<String, dynamic> map) {
    return MeditationSearchResult(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: map['category']?.toString(),
      durationMinutes: map['duration_minutes'] != null
          ? int.tryParse(map['duration_minutes'].toString())
          : null,
      similarity: (map['similarity'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() =>
      'MeditationSearchResult(title: $title, similarity: ${similarity.toStringAsFixed(2)})';
}

/// Complete user context built from multiple data sources
class UserContext {
  final String? userName;
  final List<dynamic> goals;
  final List<MoodEntrySnapshot> recentMoodEntries;
  final List<MeditationSearchResult> relevantMeditations;
  final String lastUserMessage;
  final bool hasMoodData;
  final bool hasMeditationData;

  /// Size of the whole meditation library, not just the shortlist above.
  /// Without it the model reads the 3 rows as everything that exists and
  /// keeps re-offering the same titles when the user asks for more.
  final int meditationLibrarySize;

  UserContext({
    this.userName,
    this.goals = const [],
    this.recentMoodEntries = const [],
    this.relevantMeditations = const [],
    this.lastUserMessage = '',
    this.hasMoodData = false,
    this.hasMeditationData = false,
    this.meditationLibrarySize = 0,
  });

  /// Format the context into a string suitable for the LLM system prompt
  String toPromptContext() {
    final buffer = StringBuffer();

    // User profile section
    buffer.writeln('=== USER PROFILE ===');
    if (userName != null && userName!.isNotEmpty) {
      buffer.writeln('Name: $userName');
    }
    if (goals.isNotEmpty) {
      buffer.writeln('Goals: ${goals.join(', ')}');
    } else {
      buffer.writeln('Goals: Not set');
    }
    buffer.writeln('');

    // Mood history section
    buffer.writeln('=== MOOD HISTORY (Last 7 days) ===');
    if (hasMoodData && recentMoodEntries.isNotEmpty) {
      for (final entry in recentMoodEntries) {
        final dateStr = entry.createdAt
            .toLocal()
            .toString()
            .substring(0, 10);
        buffer.writeln('- [$dateStr] Mood: ${entry.moodScore}/5'
            '${entry.note != null && entry.note!.isNotEmpty ? ' | Note: ${entry.note}' : ''}');
      }
      // Calculate average mood
      final avgMood = recentMoodEntries
              .map((e) => e.moodScore)
              .reduce((a, b) => a + b) /
          recentMoodEntries.length;
      buffer.writeln('Average mood: ${avgMood.toStringAsFixed(1)}/5');
    } else {
      buffer.writeln('No mood entries recorded yet.');
      buffer.writeln('Tip: Encourage the user to start tracking their mood.');
    }
    buffer.writeln('');

    // Relevant meditations section. Fallback results carry similarity 0: they
    // are the top-rated titles, not matches, so say so instead of "RELEVANT 0%"
    // or the model presents them as tailored to what the user just said.
    final isFallback = relevantMeditations.isNotEmpty &&
        relevantMeditations.every((m) => m.similarity == 0);
    buffer.writeln(isFallback
        ? '=== POPULAR MEDITATIONS (not matched to the message) ==='
        : '=== RELEVANT MEDITATIONS ===');
    if (hasMeditationData && relevantMeditations.isNotEmpty) {
      for (int i = 0; i < relevantMeditations.length; i++) {
        final m = relevantMeditations[i];
        buffer.writeln('${i + 1}. "${m.title}"'
            '${m.category != null ? ' [${m.category}]' : ''}'
            '${m.durationMinutes != null ? ' (${m.durationMinutes}min)' : ''}'
            '${isFallback ? '' : ' — Similarity: ${(m.similarity * 100).toStringAsFixed(0)}%'}');
        if (m.description.isNotEmpty) {
          buffer.writeln('   ${m.description.substring(0, m.description.length.clamp(0, 100))}'
              '${m.description.length > 100 ? '...' : ''}');
        }
      }
    } else {
      buffer.writeln('No highly relevant meditations found.');
      buffer.writeln(
          'Tip: Suggest general meditation or mindfulness exercises.');
    }
    if (meditationLibrarySize > relevantMeditations.length) {
      buffer.writeln('Shortlist only — the Thiền tab has '
          '$meditationLibrarySize meditations in total.');
    }
    buffer.writeln('');

    buffer.writeln('=== END CONTEXT ===');
    buffer.writeln(
        'IMPORTANT: Use this context to personalize your response. Be empathetic and relevant.');

    return buffer.toString();
  }

  /// Check if context is mostly empty (new user or fallback mode)
  bool get isEmpty =>
      (userName == null || userName!.isEmpty) &&
      goals.isEmpty &&
      recentMoodEntries.isEmpty &&
      relevantMeditations.isEmpty;
}

/// Simplified mood entry snapshot for context building
class MoodEntrySnapshot {
  final int moodScore;
  final String? note;
  final DateTime createdAt;

  MoodEntrySnapshot({
    required this.moodScore,
    this.note,
    required this.createdAt,
  });

  factory MoodEntrySnapshot.fromMap(Map<String, dynamic> map) {
    return MoodEntrySnapshot(
      moodScore: int.tryParse(map['mood_score']?.toString() ?? '3') ?? 3,
      note: map['note']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }
}

// ===========================================================================
// RAG Service — Main service class
// ===========================================================================

class RAGService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cached embedding model instance (lazy initialization)
  GenerativeModel? _embeddingModel;

  /// Initialize the Gemini embedding model
  GenerativeModel _getEmbeddingModel() {
    if (_embeddingModel == null && RAGConfig.isConfigured) {
      _embeddingModel = GenerativeModel(
        model: RAGConfig.embeddingModelName,
        apiKey: RAGConfig.embeddingApiKey,
      );
    }
    return _embeddingModel!;
  }

  // ===========================================================================
  // 1. Generate Embedding
  // ===========================================================================

  /// Generate a 3072-dimensional embedding for the given text using Gemini.
  ///
  /// Returns an empty list if the API is unavailable or an error occurs.
  /// This is a safe fallback — callers should handle empty embeddings gracefully.
  Future<List<double>> generateEmbedding(String text) async {
    if (text.isEmpty) {
      debugPrint('[RAG] Empty text for embedding');
      return [];
    }

    if (!RAGConfig.isConfigured) {
      debugPrint('[RAG] Gemini API not configured, skipping embedding');
      return [];
    }

    try {
      final model = _getEmbeddingModel();
      final contentResult = await model.embedContent(
        Content.text(text),
      );

      // Extract the embedding values: EmbedContentResponse -> ContentEmbedding -> values
      final embedding = contentResult.embedding.values;
      if (embedding.isEmpty) {
        debugPrint('[RAG] Empty embedding result from Gemini');
        return [];
      }

      // Ensure we have exactly 3072 dimensions
      if (embedding.length != RAGConfig.embeddingDimensions) {
        debugPrint(
            '[RAG] Warning: Expected ${RAGConfig.embeddingDimensions} dimensions, got ${embedding.length}');
      }

      return embedding.map((e) => e.toDouble()).toList();
    } catch (e) {
      debugPrint('[RAG] Error generating embedding: $e');
      return []; // Safe fallback
    }
  }

  // ===========================================================================
  // 2. Vector Search — Find relevant meditations
  // ===========================================================================

  /// Search for meditations similar to the query embedding using cosine similarity.
  ///
  /// Calls the Supabase RPC function `search_meditations_by_embedding` which
  /// uses the HNSW index for fast approximate nearest neighbor search.
  /// Returns results with similarity > threshold (default 0.7).
  Future<List<MeditationSearchResult>> searchRelevantMeditations(
    List<double> queryEmbedding, {
    double threshold = RAGConfig.similarityThreshold,
    int limit = RAGConfig.maxMeditationResults,
  }) async {
    if (queryEmbedding.isEmpty) {
      debugPrint('[RAG] Empty query embedding, returning featured meditations');
      return _getFallbackMeditations(limit: limit);
    }

    try {
      // Convert to the format Supabase expects (JSON array of floats)
      final embeddingJson = queryEmbedding.map((e) => e.toString()).join(',');
      final vectorString = '[$embeddingJson]';

      final response = await _supabase.rpc(
        'search_meditations_by_embedding',
        params: {
          'query_embedding': vectorString,
          'match_threshold': threshold,
          'match_count': limit,
        },
      );

      if (response.isEmpty) {
        debugPrint(
            '[RAG] No meditations found above threshold $threshold, falling back');
        return _getFallbackMeditations(limit: limit);
      }

      // rpc() returns dynamic; without the cast the chain below builds a
      // List<dynamic> at runtime and the return-type check throws, which sent
      // every real hit into the "popular" fallback.
      final results = (response as List)
          .cast<Map<String, dynamic>>()
          .map(MeditationSearchResult.fromMap)
          .toList();

      debugPrint(
          '[RAG] Found ${results.length} relevant meditation(s) (threshold: $threshold)');
      return results;
    } catch (e) {
      debugPrint('[RAG] Error searching meditations: $e');
      // Fallback to featured meditations if vector search fails
      return _getFallbackMeditations(limit: limit);
    }
  }

  /// Get a list of meditation titles without embedding-based ranking.
  ///
  /// This is used as a fallback when:
  /// - The embedding API fails
  /// - No meditations have embeddings yet
  /// - The vector search RPC fails
  Future<List<MeditationSearchResult>> _getFallbackMeditations({
    int limit = RAGConfig.maxMeditationResults,
  }) async {
    try {
      final response = await _supabase
          .from('meditations')
          .select('id, title, description, category, duration_minutes')
          .order('rating', ascending: false)
          .limit(limit);

      if (response.isEmpty) {
        return [];
      }

      return response
          .cast<Map<String, dynamic>>()
          .map((item) => MeditationSearchResult(
                id: item['id']?.toString() ?? '',
                title: item['title']?.toString() ?? '',
                description: item['description']?.toString() ?? '',
                category: item['category']?.toString(),
                durationMinutes: item['duration_minutes'] != null
                    ? int.tryParse(item['duration_minutes'].toString())
                    : null,
                // No similarity score for fallback results
                similarity: 0.0,
              ))
          .toList();
    } catch (e) {
      debugPrint('[RAG] Error getting fallback meditations: $e');
      return [];
    }
  }

  /// Total meditations in the library. 0 on failure, which just omits the
  /// line from the context.
  Future<int> _countMeditations() async {
    try {
      return await _supabase.from('meditations').count();
    } catch (e) {
      debugPrint('[RAG] Error counting meditations: $e');
      return 0;
    }
  }

  // ===========================================================================
  // 3. Context Builder — Parallel data fetching
  // ===========================================================================

  /// Build complete user context from multiple data sources in parallel.
  ///
  /// This method runs 3 independent queries concurrently using Future.wait
  /// to minimize total latency (target: < 200ms):
  ///   1. User profile (goals, name) from `users` table
  ///   2. Mood history (last 7 days) from `mood_entries` table
  ///   3. Relevant meditations via vector search
  ///
  /// The `lastMessage` is used to generate an embedding for meditation search.
  /// If embedding generation fails, we fall back to featured meditations.
  Future<UserContext> buildUserContext({
    required String userId,
    required String lastMessage,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // ── Step 1: Generate embedding for the user's message (needed for meditation search)
      final embedding = await generateEmbedding(lastMessage);

      // ── Step 2: Run independent queries in parallel
      final results = await Future.wait([
        // Query 1: User profile
        _fetchUserProfile(userId),

        // Query 2: Recent mood entries (last 7 days)
        _fetchRecentMoodEntries(userId),

        // Query 3: Relevant meditations (vector search)
        embedding.isNotEmpty
            ? searchRelevantMeditations(embedding)
            : _getFallbackMeditations(),

        // Query 4: How many meditations exist at all (head request, no rows)
        _countMeditations(),
      ]);

      // ── Step 3: Assemble context
      final userProfile = results[0] as Map<String, dynamic>;
      final moodEntries = results[1] as List<MoodEntrySnapshot>;
      final meditations = results[2] as List<MeditationSearchResult>;

      final context = UserContext(
        userName: userProfile['full_name'] as String?,
        goals: (userProfile['goals'] as List<dynamic>?) ?? [],
        recentMoodEntries: moodEntries,
        relevantMeditations: meditations,
        lastUserMessage: lastMessage,
        hasMoodData: moodEntries.isNotEmpty,
        hasMeditationData: meditations.isNotEmpty,
        meditationLibrarySize: results[3] as int,
      );

      stopwatch.stop();
      debugPrint(
          '[RAG] Context built in ${stopwatch.elapsedMilliseconds}ms '
          '(mood: ${moodEntries.length}, meditations: ${meditations.length})');

      return context;
    } catch (e) {
      stopwatch.stop();
      debugPrint('[RAG] Error building context: $e (${stopwatch.elapsedMilliseconds}ms)');
      // Return empty context as safe fallback
      return UserContext(
        lastUserMessage: lastMessage,
      );
    }
  }

  /// Fetch user profile (goals, name) from the users table.
  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('full_name, goals')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[RAG] User profile not found for $userId');
        return {};
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('[RAG] Error fetching user profile: $e');
      return {};
    }
  }

  /// Fetch mood entries from the last N days.
  Future<List<MoodEntrySnapshot>> _fetchRecentMoodEntries(
      String userId) async {
    try {
      final since = DateTime.now()
          .subtract(Duration(days: RAGConfig.moodHistoryDays));

      final response = await _supabase
          .from('mood_entries')
          .select('mood_score, note, created_at')
          .eq('user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false)
          .limit(30); // Cap at 30 entries even within 7 days

      if (response.isEmpty) {
        return [];
      }

      return response
          .cast<Map<String, dynamic>>()
          .map(MoodEntrySnapshot.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[RAG] Error fetching mood entries: $e');
      return [];
    }
  }

  // ===========================================================================
  // 4. Seed Embeddings (Utility for populating meditation embeddings)
  // ===========================================================================

  /// Generate and save embeddings for all meditations that don't have one yet.
  ///
  /// This should be called once (e.g., during app initialization or via a
  /// admin script) to populate the embedding column for existing meditations.
  ///
  /// Returns the number of meditations successfully updated.
  Future<int> seedMeditationEmbeddings() async {
    int successCount = 0;

    try {
      // Fetch meditations without embeddings
      final response = await _supabase
          .from('meditations')
          .select('id, title, description, category')
          .isFilter('embedding', null);

      if (response.isEmpty) {
        debugPrint('[RAG] No meditations need embedding seeding');
        return 0;
      }

      debugPrint('[RAG] Seeding embeddings for ${response.length} meditation(s)');

      // Process sequentially to avoid rate limiting
      for (final item in response) {
        try {
          // Create a text representation for embedding (title + description + category)
          final textToEmbed = [
            item['title'] ?? '',
            item['description'] ?? '',
            item['category'] ?? '',
          ].where((s) => s.toString().isNotEmpty).join('. ');

          if (textToEmbed.isEmpty) continue;

          final embedding = await generateEmbedding(textToEmbed);
          if (embedding.isEmpty) continue;

          // Save embedding to the database
          await _supabase
              .from('meditations')
              .update({'embedding': embedding})
              .eq('id', item['id']);

          successCount++;
          debugPrint('[RAG] ✅ Saved embedding for: ${item['title']}');
        } catch (e) {
          debugPrint('[RAG] ❌ Failed to embed meditation ${item['id']}: $e');
        }
      }

      debugPrint('[RAG] Seeding complete: $successCount/${response.length} succeeded');
    } catch (e) {
      debugPrint('[RAG] Error seeding embeddings: $e');
    }

    return successCount;
  }

  /// Update a single meditation embedding by ID.
  ///
  /// Useful for keeping embeddings fresh when meditation content changes.
  Future<bool> updateMeditationEmbedding(
    String meditationId,
    String title,
    String description, {
    String? category,
  }) async {
    try {
      final textToEmbed = [
        title,
        description,
        category ?? '',
      ].where((s) => s.isNotEmpty).join('. ');

      final embedding = await generateEmbedding(textToEmbed);
      if (embedding.isEmpty) return false;

      await _supabase
          .from('meditations')
          .update({'embedding': embedding})
          .eq('id', meditationId);

      debugPrint('[RAG] ✅ Updated embedding for meditation $meditationId');
      return true;
    } catch (e) {
      debugPrint('[RAG] Error updating meditation embedding: $e');
      return false;
    }
  }

  /// Reset the embedding model cache (e.g., when API key changes)
  void resetModel() {
    _embeddingModel = null;
  }
}
