import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import '../models/streak.dart';
import '../models/meditation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================================
  // USER PROFILE OPERATIONS
  // ============================================================================

  /// Create a new user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _db.collection('profiles').doc(profile.userId).set(profile.toMap());
      print('✅ User profile created successfully');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile by userId
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _db.collection('profiles').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('profiles').doc(userId).update(updates);
      print('✅ User profile updated successfully');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Stream user profile (real-time updates)
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _db.collection('profiles').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserProfile.fromSnapshot(doc);
      }
      return null;
    });
  }

  // ============================================================================
  // MOOD ENTRY OPERATIONS
  // ============================================================================

  /// Create a new mood entry
  Future<void> createMoodEntry(MoodEntry entry) async {
    try {
      // Generate a new document ID if entryId is empty
      final docRef = entry.entryId.isEmpty
          ? _db.collection('moodEntries').doc()
          : _db.collection('moodEntries').doc(entry.entryId);
      
      // Create a new entry with the generated ID
      final entryWithId = MoodEntry(
        entryId: docRef.id,
        userId: entry.userId,
        moodLevel: entry.moodLevel,
        note: entry.note,
        timestamp: entry.timestamp,
        emotionFactors: entry.emotionFactors,
        tags: entry.tags,
      );
      
      await docRef.set(entryWithId.toMap());
      print('✅ Mood entry created successfully with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating mood entry: $e');
      rethrow;
    }
  }

  /// Get mood entries for a user
  Future<List<MoodEntry>> getMoodEntries(String userId, {int limit = 30}) async {
    try {
      final snapshot = await _db
          .collection('moodEntries')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => MoodEntry.fromSnapshot(doc)).toList();
    } catch (e) {
      print('❌ Error getting mood entries: $e');
      return [];
    }
  }

  /// Get mood entries for specific date range
  Future<List<MoodEntry>> getMoodEntriesForPeriod({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snapshot = await _db
          .collection('moodEntries')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => MoodEntry.fromSnapshot(doc)).toList();
    } catch (e) {
      print('❌ Error getting mood entries for period: $e');
      return [];
    }
  }

  /// Update mood entry
  Future<void> updateMoodEntry(String entryId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('moodEntries').doc(entryId).update(updates);
      print('✅ Mood entry updated successfully');
    } catch (e) {
      print('❌ Error updating mood entry: $e');
      rethrow;
    }
  }

  /// Delete mood entry
  Future<void> deleteMoodEntry(String entryId) async {
    try {
      await _db.collection('moodEntries').doc(entryId).delete();
      print('✅ Mood entry deleted successfully');
    } catch (e) {
      print('❌ Error deleting mood entry: $e');
      rethrow;
    }
  }

  /// Stream mood entries (real-time updates)
  Stream<List<MoodEntry>> streamMoodEntries(String userId) {
    return _db
        .collection('moodEntries')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MoodEntry.fromSnapshot(doc)).toList());
  }

  // ============================================================================
  // STREAK OPERATIONS
  // ============================================================================

  /// Get or create user streak
  Future<Streak> getOrCreateStreak(String userId) async {
    try {
      final doc = await _db.collection('streaks').doc(userId).get();
      
      if (doc.exists) {
        return Streak.fromSnapshot(doc);
      } else {
        // Create new streak
        final newStreak = Streak(
          streakId: userId,
          userId: userId,
        );
        await _db.collection('streaks').doc(userId).set(newStreak.toMap());
        return newStreak;
      }
    } catch (e) {
      print('❌ Error getting/creating streak: $e');
      rethrow;
    }
  }

  /// Update streak
  Future<void> updateStreak(Streak streak) async {
    try {
      await _db.collection('streaks').doc(streak.userId).set(streak.toMap());
      print('✅ Streak updated successfully');
    } catch (e) {
      print('❌ Error updating streak: $e');
      rethrow;
    }
  }

  /// Stream user streak (real-time updates)
  Stream<Streak?> streamStreak(String userId) {
    return _db.collection('streaks').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return Streak.fromSnapshot(doc);
      }
      return null;
    });
  }

  // ============================================================================
  // MEDITATION OPERATIONS
  // ============================================================================

  /// Get all meditations
  Future<List<Meditation>> getAllMeditations() async {
    try {
      final snapshot = await _db
          .collection('meditations')
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map((doc) => Meditation.fromSnapshot(doc)).toList();
    } catch (e) {
      print('❌ Error getting meditations: $e');
      return [];
    }
  }

  /// Get meditations by category
  Future<List<Meditation>> getMeditationsByCategory(MeditationCategory category) async {
    try {
      final snapshot = await _db
          .collection('meditations')
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('rating', descending: true)
          .get();

      return snapshot.docs.map((doc) => Meditation.fromSnapshot(doc)).toList();
    } catch (e) {
      print('❌ Error getting meditations by category: $e');
      return [];
    }
  }

  /// Get featured meditations (top rated)
  Future<List<Meditation>> getFeaturedMeditations({int limit = 5}) async {
    try {
      final snapshot = await _db
          .collection('meditations')
          .orderBy('rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Meditation.fromSnapshot(doc)).toList();
    } catch (e) {
      print('❌ Error getting featured meditations: $e');
      return [];
    }
  }

  /// Stream meditations (real-time updates)
  Stream<List<Meditation>> streamMeditations() {
    return _db
        .collection('meditations')
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Meditation.fromSnapshot(doc)).toList());
  }

  // ============================================================================
  // UTILITY FUNCTIONS
  // ============================================================================

  /// Initialize sample data (for testing)
  Future<void> initializeSampleData() async {
    try {
      // Add sample meditations
      final sampleMeditations = [
        Meditation(
          meditationId: 'med001',
          title: 'Morning Gratitude',
          description: 'Start your day with gratitude and positive energy',
          duration: 10,
          category: MeditationCategory.stress,
          level: MeditationLevel.beginner,
          rating: 4.8,
          totalReviews: 150,
        ),
        Meditation(
          meditationId: 'med002',
          title: 'Deep Sleep',
          description: 'Guided meditation for restful sleep',
          duration: 20,
          category: MeditationCategory.sleep,
          level: MeditationLevel.intermediate,
          rating: 4.9,
          totalReviews: 200,
        ),
        Meditation(
          meditationId: 'med003',
          title: 'Focus & Productivity',
          description: 'Enhance your concentration and productivity',
          duration: 15,
          category: MeditationCategory.focus,
          level: MeditationLevel.beginner,
          rating: 4.7,
          totalReviews: 120,
        ),
      ];

      for (var meditation in sampleMeditations) {
        await _db.collection('meditations').doc(meditation.meditationId).set(meditation.toMap());
      }

      print('✅ Sample data initialized successfully');
    } catch (e) {
      print('❌ Error initializing sample data: $e');
    }
  }
}
