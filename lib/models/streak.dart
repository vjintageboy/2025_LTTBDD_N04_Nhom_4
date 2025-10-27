import 'package:cloud_firestore/cloud_firestore.dart';

class Streak {
  final String streakId;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int totalActivities;

  Streak({
    required this.streakId,
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.totalActivities = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'streakId': streakId,
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': lastActivityDate != null 
          ? Timestamp.fromDate(lastActivityDate!) 
          : null,
      'totalActivities': totalActivities,
    };
  }

  // Create from Firestore document
  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      streakId: map['streakId'] ?? '',
      userId: map['userId'] ?? '',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastActivityDate: map['lastActivityDate'] != null 
          ? (map['lastActivityDate'] as Timestamp).toDate() 
          : null,
      totalActivities: map['totalActivities'] ?? 0,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory Streak.fromSnapshot(DocumentSnapshot doc) {
    return Streak.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Update streak when user completes an activity
  Streak updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastActivityDate == null) {
      // First activity
      return copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastActivityDate: today,
        totalActivities: totalActivities + 1,
      );
    }

    final lastDate = DateTime(
      lastActivityDate!.year,
      lastActivityDate!.month,
      lastActivityDate!.day,
    );
    
    final daysDifference = today.difference(lastDate).inDays;

    if (daysDifference == 0) {
      // Same day, don't update streak count
      return copyWith(totalActivities: totalActivities + 1);
    } else if (daysDifference == 1) {
      // Consecutive day
      final newStreak = currentStreak + 1;
      return copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
        lastActivityDate: today,
        totalActivities: totalActivities + 1,
      );
    } else {
      // Streak broken
      return copyWith(
        currentStreak: 1,
        lastActivityDate: today,
        totalActivities: totalActivities + 1,
      );
    }
  }

  // Reset streak
  Streak resetStreak() {
    return copyWith(currentStreak: 0, lastActivityDate: null);
  }

  // Copy with method
  Streak copyWith({
    String? streakId,
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivityDate,
    int? totalActivities,
  }) {
    return Streak(
      streakId: streakId ?? this.streakId,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      totalActivities: totalActivities ?? this.totalActivities,
    );
  }
}
