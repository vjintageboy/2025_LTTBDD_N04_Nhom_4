import '../services/supabase_service.dart';

class MoodEntry {
  final String entryId;
  final String userId;
  final int moodLevel; // 1-5 scale
  final String? note;
  final DateTime timestamp;
  final List<String> emotionFactors;
  final List<String> tags;
  final String? imageUrl; // base64 string or remote URL

  MoodEntry({
    required this.entryId,
    required this.userId,
    required this.moodLevel,
    this.note,
    required this.timestamp,
    this.emotionFactors = const [],
    this.tags = const [],
    this.imageUrl,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': entryId,
      'user_id': userId,
      'mood_score': moodLevel,
      'note': note,
      'emotion_factors': emotionFactors,
      'tags': tags,
      'image_url': imageUrl,
      // created_at is handled by DB
    };
  }

  // Create from Supabase map
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      entryId: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      moodLevel: int.tryParse(map['mood_score']?.toString() ?? '3') ?? 3,
      note: map['note']?.toString(),
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      emotionFactors: _parseList(map['emotion_factors']),
      tags: _parseList(map['tags']),
      imageUrl: map['image_url']?.toString(),
    );
  }

  static List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }

  // Get mood entries for a specific period
  static Future<List<MoodEntry>> getMoodEntriesForPeriod({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    return await SupabaseService.instance.getMoodEntriesForPeriod(
      userId: userId,
      start: start,
      end: end,
    );
  }

  // Calculate average mood for period
  static double getAverageMood(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold<int>(0, (sum, entry) => sum + entry.moodLevel);
    return sum / entries.length;
  }
}
