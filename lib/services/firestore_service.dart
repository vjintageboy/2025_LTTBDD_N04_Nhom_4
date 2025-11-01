import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/mood_entry.dart';
import '../models/streak.dart';
import '../models/meditation.dart';
import '../models/app_user.dart';

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

  /// Update streak when user completes an activity (mood log or meditation)
  Future<void> updateStreakForActivity(String userId) async {
    try {
      // Get current streak
      final currentStreak = await getOrCreateStreak(userId);
      
      // Update streak using the model's logic
      final updatedStreak = currentStreak.updateStreak();
      
      // Save to Firestore
      await _db.collection('streaks').doc(userId).set(updatedStreak.toMap());
      
      print('✅ Streak updated: ${updatedStreak.currentStreak} days (longest: ${updatedStreak.longestStreak})');
    } catch (e) {
      print('❌ Error updating streak: $e');
      rethrow;
    }
  }

  /// Reset user's streak to zero
  Future<void> resetStreak(String userId) async {
    try {
      await _db.collection('streaks').doc(userId).set({
        'streakId': userId,
        'userId': userId,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActivityDate': null,
        'totalActivities': 0,
      });
      print('✅ Streak reset successfully');
    } catch (e) {
      print('❌ Error resetting streak: $e');
      rethrow;
    }
  }

  /// Recalculate streak based on all activity dates
  Future<void> recalculateStreak(String userId) async {
    try {
      // Get all activity dates
      final activityDates = await getUserActivityDates(userId);
      
      if (activityDates.isEmpty) {
        await resetStreak(userId);
        return;
      }
      
      // Sort dates in ascending order
      activityDates.sort((a, b) => a.compareTo(b));
      
      int currentStreak = 0;
      int longestStreak = 0;
      DateTime? lastDate;
      
      for (var date in activityDates) {
        if (lastDate == null) {
          // First date
          currentStreak = 1;
          longestStreak = 1;
        } else {
          final daysDiff = date.difference(lastDate).inDays;
          
          if (daysDiff == 1) {
            // Consecutive day
            currentStreak++;
            if (currentStreak > longestStreak) {
              longestStreak = currentStreak;
            }
          } else if (daysDiff > 1) {
            // Streak broken
            currentStreak = 1;
          }
          // If daysDiff == 0, same day, don't change streak
        }
        lastDate = date;
      }
      
      // Check if streak is still active (last activity was today or yesterday)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (lastDate != null) {
        final lastActivityDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        
        if (!lastActivityDay.isAtSameMomentAs(today) && 
            !lastActivityDay.isAtSameMomentAs(yesterday)) {
          // Streak is broken (last activity was more than 1 day ago)
          currentStreak = 0;
        }
      }
      
      // Save to database
      await _db.collection('streaks').doc(userId).set({
        'streakId': userId,
        'userId': userId,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastActivityDate': lastDate != null ? Timestamp.fromDate(lastDate) : null,
        'totalActivities': activityDates.length,
      });
      
      print('✅ Streak recalculated: current=$currentStreak, longest=$longestStreak, total=${activityDates.length}');
    } catch (e) {
      print('❌ Error recalculating streak: $e');
      rethrow;
    }
  }

  /// Get all dates where user had activity (meditation or mood log)
  Future<List<DateTime>> getUserActivityDates(String userId) async {
    try {
      final Set<DateTime> activityDates = {};
      
      // Get mood log dates
      final moodSnapshot = await _db
          .collection('moodEntries')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      for (var doc in moodSnapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        activityDates.add(date);
      }
      
      // Get meditation completion dates (if you have this collection)
      // You can add this later when meditation completion is implemented
      
      return activityDates.toList()..sort((a, b) => b.compareTo(a));
    } catch (e) {
      print('❌ Error getting activity dates: $e');
      return [];
    }
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
          description: 'Start your day with gratitude and positive energy. This guided meditation helps you cultivate appreciation for the present moment and sets a positive tone for your day ahead.',
          duration: 10,
          category: MeditationCategory.stress,
          level: MeditationLevel.beginner,
          rating: 4.8,
          totalReviews: 150,
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
          thumbnailUrl: 'https://picsum.photos/400/300?random=1',
        ),
        Meditation(
          meditationId: 'med002',
          title: 'Deep Sleep',
          description: 'Guided meditation for restful sleep. Let go of the day\'s stress and tension as you drift into a peaceful, rejuvenating sleep with this calming meditation.',
          duration: 20,
          category: MeditationCategory.sleep,
          level: MeditationLevel.intermediate,
          rating: 4.9,
          totalReviews: 200,
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
          thumbnailUrl: 'https://picsum.photos/400/300?random=2',
        ),
        Meditation(
          meditationId: 'med003',
          title: 'Focus & Productivity',
          description: 'Enhance your concentration and productivity. This meditation session will help you clear mental clutter and sharpen your focus for optimal performance.',
          duration: 15,
          category: MeditationCategory.focus,
          level: MeditationLevel.beginner,
          rating: 4.7,
          totalReviews: 120,
          audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
          thumbnailUrl: 'https://picsum.photos/400/300?random=3',
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

  // ============================================================================
  // APP USER OPERATIONS (Admin System)
  // ============================================================================

  /// Create or update user document in Firestore
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
    UserRole? role,
  }) async {
    try {
      final userDoc = _db.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Update existing user
        await userDoc.update({
          'displayName': displayName,
          'photoUrl': photoUrl,
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        print('✅ User updated: $email');
      } else {
        // Create new user
        final user = AppUser(
          id: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
          role: role ?? UserRole.user,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await userDoc.set(user.toFirestore());
        print('✅ User created: $email (${role?.value ?? 'user'})');
      }
    } catch (e) {
      print('❌ Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print('❌ User not found: $uid');
        return null;
      }

      return AppUser.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  /// Stream user data (real-time updates)
  Stream<AppUser?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, doc.id);
    });
  }

  /// Check if user is admin
  Future<bool> isAdmin(String uid) async {
    final user = await getUser(uid);
    return user?.isAdmin ?? false;
  }

  /// Update user role (admin only operation)
  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role': role.value,
      });
      print('✅ User role updated: $uid → ${role.value}');
    } catch (e) {
      print('❌ Error updating user role: $e');
      rethrow;
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating last login: $e');
    }
  }

  /// Get all users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('users').get();
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }
}
