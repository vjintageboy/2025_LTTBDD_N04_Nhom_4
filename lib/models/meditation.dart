import 'package:cloud_firestore/cloud_firestore.dart';

enum MeditationCategory { stress, anxiety, sleep, focus }
enum MeditationLevel { beginner, intermediate, advanced }

class Meditation {
  final String meditationId;
  final String title;
  final String description;
  final int duration; // in minutes
  final MeditationCategory category;
  final MeditationLevel level;
  final String? audioUrl;
  final String? thumbnailUrl;
  final double rating;
  final int totalReviews;

  Meditation({
    required this.meditationId,
    required this.title,
    required this.description,
    required this.duration,
    required this.category,
    required this.level,
    this.audioUrl,
    this.thumbnailUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'meditationId': meditationId,
      'title': title,
      'description': description,
      'duration': duration,
      'category': category.toString().split('.').last,
      'level': level.toString().split('.').last,
      'audioUrl': audioUrl,
      'thumbnailUrl': thumbnailUrl,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }

  // Create from Firestore document
  factory Meditation.fromMap(Map<String, dynamic> map) {
    return Meditation(
      meditationId: map['meditationId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      duration: map['duration'] ?? 0,
      category: MeditationCategory.values.firstWhere(
        (e) => e.toString().split('.').last == map['category'],
        orElse: () => MeditationCategory.stress,
      ),
      level: MeditationLevel.values.firstWhere(
        (e) => e.toString().split('.').last == map['level'],
        orElse: () => MeditationLevel.beginner,
      ),
      audioUrl: map['audioUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory Meditation.fromSnapshot(DocumentSnapshot doc) {
    return Meditation.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Get meditations by category
  static Future<List<Meditation>> getMeditationsByCategory(
    MeditationCategory category,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('meditations')
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('rating', descending: true)
        .get();

    return snapshot.docs.map((doc) => Meditation.fromSnapshot(doc)).toList();
  }

  // Update rating
  Meditation updateRating(double newRating) {
    final totalRating = rating * totalReviews + newRating;
    final newTotalReviews = totalReviews + 1;
    final newAverageRating = totalRating / newTotalReviews;

    return copyWith(
      rating: newAverageRating,
      totalReviews: newTotalReviews,
    );
  }

  // Copy with method
  Meditation copyWith({
    String? meditationId,
    String? title,
    String? description,
    int? duration,
    MeditationCategory? category,
    MeditationLevel? level,
    String? audioUrl,
    String? thumbnailUrl,
    double? rating,
    int? totalReviews,
  }) {
    return Meditation(
      meditationId: meditationId ?? this.meditationId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      level: level ?? this.level,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
