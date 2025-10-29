import 'package:cloud_firestore/cloud_firestore.dart';

class Expert {
  final String expertId;
  final String fullName;
  final String title; // Dr., Ms., Mr., etc.
  final String specialization; // Anxiety, Depression, Stress, etc.
  final String bio;
  final String? avatarUrl;
  final double rating;
  final int totalReviews;
  final int yearsOfExperience;
  final double pricePerSession; // Price per session
  final List<String> availability; // ["Monday", "Tuesday", "Wednesday", etc.]
  final List<String> timeSlots; // ["09:00-10:00", "10:00-11:00", etc.]
  final bool isAvailable;
  final String? licenseNumber;
  final DateTime createdAt;

  Expert({
    required this.expertId,
    required this.fullName,
    required this.title,
    required this.specialization,
    required this.bio,
    this.avatarUrl,
    this.rating = 0.0,
    this.totalReviews = 0,
    required this.yearsOfExperience,
    required this.pricePerSession,
    required this.availability,
    required this.timeSlots,
    this.isAvailable = true,
    this.licenseNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayName => '$title $fullName';

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'expertId': expertId,
      'fullName': fullName,
      'title': title,
      'specialization': specialization,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'totalReviews': totalReviews,
      'yearsOfExperience': yearsOfExperience,
      'pricePerSession': pricePerSession,
      'availability': availability,
      'timeSlots': timeSlots,
      'isAvailable': isAvailable,
      'licenseNumber': licenseNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory Expert.fromMap(Map<String, dynamic> map) {
    return Expert(
      expertId: map['expertId'] ?? '',
      fullName: map['fullName'] ?? '',
      title: map['title'] ?? '',
      specialization: map['specialization'] ?? '',
      bio: map['bio'] ?? '',
      avatarUrl: map['avatarUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      pricePerSession: (map['pricePerSession'] ?? 0.0).toDouble(),
      availability: List<String>.from(map['availability'] ?? []),
      timeSlots: List<String>.from(map['timeSlots'] ?? []),
      isAvailable: map['isAvailable'] ?? true,
      licenseNumber: map['licenseNumber'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory Expert.fromSnapshot(DocumentSnapshot doc) {
    return Expert.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Get all experts
  static Future<List<Expert>> getAllExperts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('experts')
        .get();

    // Filter and sort in memory to avoid needing Firestore index
    final experts = snapshot.docs
        .map((doc) => Expert.fromSnapshot(doc))
        .where((expert) => expert.isAvailable)
        .toList();
    
    experts.sort((a, b) => b.rating.compareTo(a.rating));
    return experts;
  }

  // Get experts by specialization
  static Future<List<Expert>> getExpertsBySpecialization(String specialization) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('experts')
        .where('specialization', isEqualTo: specialization)
        .get();

    // Filter and sort in memory
    final experts = snapshot.docs
        .map((doc) => Expert.fromSnapshot(doc))
        .where((expert) => expert.isAvailable)
        .toList();
    
    experts.sort((a, b) => b.rating.compareTo(a.rating));
    return experts;
  }

  // Get expert by ID
  static Future<Expert?> getExpertById(String expertId) async {
    final doc = await FirebaseFirestore.instance
        .collection('experts')
        .doc(expertId)
        .get();

    if (doc.exists) {
      return Expert.fromSnapshot(doc);
    }
    return null;
  }

  // Search experts by name
  static Future<List<Expert>> searchExperts(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('experts')
        .where('isAvailable', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => Expert.fromSnapshot(doc))
        .where((expert) =>
            expert.fullName.toLowerCase().contains(query.toLowerCase()) ||
            expert.specialization.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
