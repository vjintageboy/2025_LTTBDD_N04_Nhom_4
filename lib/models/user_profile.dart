import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, other }

class UserProfile {
  final String profileId;
  final String userId;
  final String fullName;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? avatarUrl;
  final List<String> goals;
  final Map<String, dynamic>? preferences;

  UserProfile({
    required this.profileId,
    required this.userId,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.avatarUrl,
    this.goals = const [],
    this.preferences,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'userId': userId,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender?.toString().split('.').last,
      'avatarUrl': avatarUrl,
      'goals': goals,
      'preferences': preferences,
    };
  }

  // Create from Firestore document
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      profileId: map['profileId'] ?? '',
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null 
          ? (map['dateOfBirth'] as Timestamp).toDate() 
          : null,
      gender: map['gender'] != null 
          ? Gender.values.firstWhere(
              (e) => e.toString().split('.').last == map['gender'],
              orElse: () => Gender.other,
            )
          : null,
      avatarUrl: map['avatarUrl'],
      goals: List<String>.from(map['goals'] ?? []),
      preferences: map['preferences'],
    );
  }

  // Create from Firestore DocumentSnapshot
  factory UserProfile.fromSnapshot(DocumentSnapshot doc) {
    return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Copy with method for updates
  UserProfile copyWith({
    String? profileId,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    Gender? gender,
    String? avatarUrl,
    List<String>? goals,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      goals: goals ?? this.goals,
      preferences: preferences ?? this.preferences,
    );
  }
}
