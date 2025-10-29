import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expert.dart';

/// Script to populate Firestore with sample expert data
/// Run this once to initialize the experts collection
class PopulateExpertsData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> addSampleExperts() async {
    print('🚀 Starting to populate experts data...');

    final sampleExperts = [
      Expert(
        expertId: 'expert_001',
        fullName: 'Sarah Johnson',
        title: 'Dr.',
        specialization: 'Anxiety',
        bio: 'Specialized in anxiety disorders with over 12 years of experience. Cognitive Behavioral Therapy (CBT) expert helping clients overcome anxiety, panic attacks, and phobias.',
        avatarUrl: 'https://i.pravatar.cc/300?img=1',
        rating: 4.9,
        totalReviews: 156,
        yearsOfExperience: 12,
        pricePerSession: 80,
        availability: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        timeSlots: [
          '09:00-10:00',
          '10:00-11:00',
          '14:00-15:00',
          '15:00-16:00',
          '16:00-17:00'
        ],
        isAvailable: true,
        licenseNumber: 'PSY-2013-001',
      ),
      Expert(
        expertId: 'expert_002',
        fullName: 'Michael Chen',
        title: 'Dr.',
        specialization: 'Depression',
        bio: 'Clinical psychologist specializing in depression treatment. Using evidence-based approaches including CBT, mindfulness, and solution-focused therapy to help clients regain joy in life.',
        avatarUrl: 'https://i.pravatar.cc/300?img=12',
        rating: 4.8,
        totalReviews: 203,
        yearsOfExperience: 15,
        pricePerSession: 90,
        availability: ['Monday', 'Wednesday', 'Friday'],
        timeSlots: [
          '09:00-10:00',
          '11:00-12:00',
          '14:00-15:00',
          '15:00-16:00'
        ],
        isAvailable: true,
        licenseNumber: 'PSY-2010-045',
      ),
      Expert(
        expertId: 'expert_003',
        fullName: 'Emma Rodriguez',
        title: 'Ms.',
        specialization: 'Stress',
        bio: 'Licensed therapist focusing on stress management and work-life balance. Helping professionals navigate burnout, workplace stress, and develop healthy coping strategies.',
        avatarUrl: 'https://i.pravatar.cc/300?img=5',
        rating: 4.7,
        totalReviews: 89,
        yearsOfExperience: 8,
        pricePerSession: 70,
        availability: ['Tuesday', 'Thursday', 'Saturday'],
        timeSlots: [
          '10:00-11:00',
          '11:00-12:00',
          '13:00-14:00',
          '14:00-15:00',
          '15:00-16:00'
        ],
        isAvailable: true,
        licenseNumber: 'LMFT-2017-089',
      ),
      Expert(
        expertId: 'expert_004',
        fullName: 'David Williams',
        title: 'Dr.',
        specialization: 'Sleep',
        bio: 'Sleep specialist and behavioral psychologist. Expert in treating insomnia, sleep disorders, and developing healthy sleep habits through cognitive behavioral therapy for insomnia (CBT-I).',
        avatarUrl: 'https://i.pravatar.cc/300?img=15',
        rating: 4.9,
        totalReviews: 124,
        yearsOfExperience: 10,
        pricePerSession: 85,
        availability: ['Monday', 'Tuesday', 'Thursday', 'Friday'],
        timeSlots: [
          '08:00-09:00',
          '09:00-10:00',
          '10:00-11:00',
          '16:00-17:00',
          '17:00-18:00'
        ],
        isAvailable: true,
        licenseNumber: 'PSY-2015-234',
      ),
      Expert(
        expertId: 'expert_005',
        fullName: 'Lisa Anderson',
        title: 'Dr.',
        specialization: 'Relationships',
        bio: 'Marriage and family therapist with expertise in couples counseling, communication skills, and relationship conflict resolution. Creating safe spaces for healing and growth.',
        avatarUrl: 'https://i.pravatar.cc/300?img=9',
        rating: 4.8,
        totalReviews: 178,
        yearsOfExperience: 14,
        pricePerSession: 95,
        availability: ['Wednesday', 'Thursday', 'Friday', 'Saturday'],
        timeSlots: [
          '09:00-10:00',
          '10:00-11:00',
          '11:00-12:00',
          '14:00-15:00',
          '15:00-16:00',
          '16:00-17:00'
        ],
        isAvailable: true,
        licenseNumber: 'LMFT-2011-156',
      ),
      Expert(
        expertId: 'expert_006',
        fullName: 'James Taylor',
        title: 'Mr.',
        specialization: 'Anxiety',
        bio: 'Counseling psychologist specializing in social anxiety and generalized anxiety disorder. Compassionate approach combining exposure therapy and relaxation techniques.',
        avatarUrl: 'https://i.pravatar.cc/300?img=13',
        rating: 4.6,
        totalReviews: 67,
        yearsOfExperience: 6,
        pricePerSession: 65,
        availability: ['Monday', 'Tuesday', 'Wednesday', 'Friday'],
        timeSlots: [
          '13:00-14:00',
          '14:00-15:00',
          '15:00-16:00',
          '16:00-17:00'
        ],
        isAvailable: true,
        licenseNumber: 'LPC-2019-078',
      ),
      Expert(
        expertId: 'expert_007',
        fullName: 'Maria Garcia',
        title: 'Dr.',
        specialization: 'Depression',
        bio: 'Clinical psychologist with expertise in treating major depressive disorder and mood disorders. Integrating psychodynamic therapy with modern mindfulness-based approaches.',
        avatarUrl: 'https://i.pravatar.cc/300?img=20',
        rating: 4.9,
        totalReviews: 145,
        yearsOfExperience: 11,
        pricePerSession: 85,
        availability: ['Tuesday', 'Thursday', 'Friday', 'Saturday'],
        timeSlots: [
          '09:00-10:00',
          '10:00-11:00',
          '13:00-14:00',
          '14:00-15:00',
          '15:00-16:00'
        ],
        isAvailable: true,
        licenseNumber: 'PSY-2014-167',
      ),
      Expert(
        expertId: 'expert_008',
        fullName: 'Robert Lee',
        title: 'Dr.',
        specialization: 'Stress',
        bio: 'Stress management expert and organizational psychologist. Helping individuals and teams develop resilience, time management skills, and healthy work-life integration.',
        avatarUrl: 'https://i.pravatar.cc/300?img=11',
        rating: 4.7,
        totalReviews: 92,
        yearsOfExperience: 9,
        pricePerSession: 75,
        availability: ['Monday', 'Wednesday', 'Thursday', 'Friday'],
        timeSlots: [
          '08:00-09:00',
          '09:00-10:00',
          '14:00-15:00',
          '15:00-16:00',
          '17:00-18:00'
        ],
        isAvailable: true,
        licenseNumber: 'PSY-2016-203',
      ),
    ];

    try {
      int count = 0;
      for (var expert in sampleExperts) {
        await _db.collection('experts').doc(expert.expertId).set(expert.toMap());
        count++;
        print('✅ Added: ${expert.displayName} - ${expert.specialization} [$count/${sampleExperts.length}]');
      }

      print('');
      print('🎉 Successfully added ${sampleExperts.length} experts to Firestore!');
      print('');
      print('📊 Summary:');
      print('  - Total Experts: ${sampleExperts.length}');
      print('  - Anxiety Specialists: ${sampleExperts.where((e) => e.specialization == 'Anxiety').length}');
      print('  - Depression Specialists: ${sampleExperts.where((e) => e.specialization == 'Depression').length}');
      print('  - Stress Specialists: ${sampleExperts.where((e) => e.specialization == 'Stress').length}');
      print('  - Sleep Specialists: ${sampleExperts.where((e) => e.specialization == 'Sleep').length}');
      print('  - Relationship Specialists: ${sampleExperts.where((e) => e.specialization == 'Relationships').length}');
      print('');
    } catch (e) {
      print('❌ Error adding experts: $e');
    }
  }

  /// Delete all experts (use with caution!)
  static Future<void> clearAllExperts() async {
    print('🗑️  Deleting all experts...');
    try {
      final snapshot = await _db.collection('experts').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ All experts deleted');
    } catch (e) {
      print('❌ Error deleting experts: $e');
    }
  }
}
