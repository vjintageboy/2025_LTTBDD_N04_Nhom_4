import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String entryId;
  final String userId;
  final int moodLevel; // 1-5 scale
  final String? note;
  final DateTime timestamp;
  final List<String> emotionFactors;
  final List<String> tags;

  MoodEntry({
    required this.entryId,
    required this.userId,
    required this.moodLevel,
    this.note,
    required this.timestamp,
    this.emotionFactors = const [],
    this.tags = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'userId': userId,
      'moodLevel': moodLevel,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
      'emotionFactors': emotionFactors,
      'tags': tags,
    };
  }

  // Create from Firestore document
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      entryId: map['entryId'] ?? '',
      userId: map['userId'] ?? '',
      moodLevel: map['moodLevel'] ?? 3,
      note: map['note'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      emotionFactors: List<String>.from(map['emotionFactors'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory MoodEntry.fromSnapshot(DocumentSnapshot doc) {
    return MoodEntry.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Get mood entries for a specific period
  static Future<List<MoodEntry>> getMoodEntriesForPeriod({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('moodEntries')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => MoodEntry.fromSnapshot(doc)).toList();
  }

  // Calculate average mood for period
  static double getAverageMood(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold<int>(0, (sum, entry) => sum + entry.moodLevel);
    return sum / entries.length;
  }
}
