import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class ConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache for config data
  static final Map<String, dynamic> _cache = {};

  /// Get default user goals from Firestore or return defaults
  Future<List<String>> getDefaultUserGoals() async {
    try {
      final doc = await _db.collection('config').doc('defaults').get();
      if (doc.exists && doc.data()?['userGoals'] != null) {
        return List<String>.from(doc.data()!['userGoals']);
      }
    } catch (e) {
      print('Error fetching default goals: $e');
    }
    
    // Fallback to local defaults
    return AppConstants.defaultUserGoals;
  }

  /// Get available mood emotion factors
  Future<List<String>> getEmotionFactors() async {
    try {
      final doc = await _db.collection('config').doc('mood').get();
      if (doc.exists && doc.data()?['emotionFactors'] != null) {
        return List<String>.from(doc.data()!['emotionFactors']);
      }
    } catch (e) {
      print('Error fetching emotion factors: $e');
    }
    
    // Fallback to local defaults
    return AppConstants.emotionFactors;
  }

  /// Get mood level configuration
  Future<List<Map<String, dynamic>>> getMoodLevels() async {
    try {
      final doc = await _db.collection('config').doc('mood').get();
      if (doc.exists && doc.data()?['moodLevels'] != null) {
        return List<Map<String, dynamic>>.from(doc.data()!['moodLevels']);
      }
    } catch (e) {
      print('Error fetching mood levels: $e');
    }
    
    // Fallback to local defaults
    return [
      {'level': 1, 'emoji': '😞', 'label': 'Very Poor'},
      {'level': 2, 'emoji': '😕', 'label': 'Poor'},
      {'level': 3, 'emoji': '😐', 'label': 'Okay'},
      {'level': 4, 'emoji': '🙂', 'label': 'Good'},
      {'level': 5, 'emoji': '😄', 'label': 'Excellent'},
    ];
  }

  /// Get app settings
  Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final doc = await _db.collection('config').doc('settings').get();
      if (doc.exists) {
        return doc.data() ?? _getDefaultSettings();
      }
    } catch (e) {
      print('Error fetching app settings: $e');
    }
    
    return _getDefaultSettings();
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'minPasswordLength': AppConstants.minPasswordLength,
      'enableSocialLogin': true,
      'enablePushNotifications': true,
      'streakReminderTime': '20:00',
      'maxMoodEntriesPerDay': 10,
    };
  }

  /// Get cached config or fetch from Firestore
  Future<T> getCachedConfig<T>(
    String key,
    Future<T> Function() fetcher,
  ) async {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    final value = await fetcher();
    _cache[key] = value;
    return value;
  }

  /// Clear cache (useful for force refresh)
  void clearCache() {
    _cache.clear();
  }

  /// Initialize default config in Firestore (for admin setup)
  Future<void> initializeDefaultConfig() async {
    try {
      // Check if config already exists
      final defaultsDoc = await _db.collection('config').doc('defaults').get();
      if (!defaultsDoc.exists) {
        await _db.collection('config').doc('defaults').set({
          'userGoals': AppConstants.defaultUserGoals,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final moodDoc = await _db.collection('config').doc('mood').get();
      if (!moodDoc.exists) {
        await _db.collection('config').doc('mood').set({
          'emotionFactors': AppConstants.emotionFactors,
          'moodLevels': [
            {'level': 1, 'emoji': '😞', 'label': 'Very Poor'},
            {'level': 2, 'emoji': '😕', 'label': 'Poor'},
            {'level': 3, 'emoji': '😐', 'label': 'Okay'},
            {'level': 4, 'emoji': '🙂', 'label': 'Good'},
            {'level': 5, 'emoji': '😄', 'label': 'Excellent'},
          ],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final settingsDoc = await _db.collection('config').doc('settings').get();
      if (!settingsDoc.exists) {
        await _db.collection('config').doc('settings').set({
          ..._getDefaultSettings(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('Default config initialized successfully');
    } catch (e) {
      print('Error initializing default config: $e');
    }
  }
}
