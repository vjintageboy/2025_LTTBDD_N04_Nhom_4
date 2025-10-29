import 'package:flutter/foundation.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';
import '../../services/config_service.dart';

enum MoodFilterLevel { all, veryPoor, poor, okay, good, excellent }

class MoodProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final ConfigService _configService = ConfigService();

  List<MoodEntry> _moodEntries = [];
  List<String> _emotionFactors = [];
  bool _isLoading = false;
  String? _errorMessage;
  MoodFilterLevel _filterLevel = MoodFilterLevel.all;
  DateTime _selectedMonth = DateTime.now();

  // Getters
  List<MoodEntry> get moodEntries => _moodEntries;
  List<String> get emotionFactors => _emotionFactors;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  MoodFilterLevel get filterLevel => _filterLevel;
  DateTime get selectedMonth => _selectedMonth;

  // Filtered mood entries based on current filter
  List<MoodEntry> get filteredMoodEntries {
    if (_filterLevel == MoodFilterLevel.all) {
      return _moodEntries;
    }
    
    final level = _filterLevelToInt(_filterLevel);
    return _moodEntries.where((entry) => entry.moodLevel == level).toList();
  }

  // Statistics
  double get averageMood {
    if (_moodEntries.isEmpty) return 0.0;
    final sum = _moodEntries.fold<int>(0, (sum, entry) => sum + entry.moodLevel);
    return sum / _moodEntries.length;
  }

  Map<int, int> get moodDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var entry in _moodEntries) {
      distribution[entry.moodLevel] = (distribution[entry.moodLevel] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> get topEmotionFactors {
    final frequency = <String, int>{};
    for (var entry in _moodEntries) {
      for (var factor in entry.emotionFactors) {
        frequency[factor] = (frequency[factor] ?? 0) + 1;
      }
    }
    
    final sortedEntries = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(5));
  }

  MoodEntry? get bestMood {
    if (_moodEntries.isEmpty) return null;
    return _moodEntries.reduce((a, b) => a.moodLevel > b.moodLevel ? a : b);
  }

  MoodEntry? get worstMood {
    if (_moodEntries.isEmpty) return null;
    return _moodEntries.reduce((a, b) => a.moodLevel < b.moodLevel ? a : b);
  }

  int _filterLevelToInt(MoodFilterLevel level) {
    switch (level) {
      case MoodFilterLevel.veryPoor:
        return 1;
      case MoodFilterLevel.poor:
        return 2;
      case MoodFilterLevel.okay:
        return 3;
      case MoodFilterLevel.good:
        return 4;
      case MoodFilterLevel.excellent:
        return 5;
      default:
        return 0;
    }
  }

  // Initialize emotion factors from config
  Future<void> loadEmotionFactors() async {
    try {
      _emotionFactors = await _configService.getCachedConfig(
        'emotionFactors',
        () => _configService.getEmotionFactors(),
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load emotion factors: ${e.toString()}';
      notifyListeners();
    }
  }

  // Load mood entries for a specific user
  Future<void> loadMoodEntries(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _moodEntries = await _firestoreService.getMoodEntriesForPeriod(
        userId: userId,
        start: startDate ?? DateTime(selectedMonth.year, selectedMonth.month, 1),
        end: endDate ?? DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load mood entries: ${e.toString()}';
      notifyListeners();
    }
  }

  // Stream mood entries for real-time updates
  Stream<List<MoodEntry>> streamMoodEntries(String userId) {
    return _firestoreService.streamMoodEntries(userId);
  }

  // Create a new mood entry
  Future<bool> createMoodEntry({
    required String userId,
    required int moodLevel,
    required List<String> emotionFactors,
    String? note,
    List<String>? tags,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final entry = MoodEntry(
        entryId: '', // Will be set by Firestore
        userId: userId,
        moodLevel: moodLevel,
        note: note,
        timestamp: DateTime.now(),
        emotionFactors: emotionFactors,
        tags: tags ?? [],
      );

      await _firestoreService.createMoodEntry(entry);

      // Reload entries
      await loadMoodEntries(userId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create mood entry: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update an existing mood entry
  Future<bool> updateMoodEntry(MoodEntry entry) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateMoodEntry(entry.entryId, entry.toMap());

      // Update local list
      final index = _moodEntries.indexWhere((e) => e.entryId == entry.entryId);
      if (index != -1) {
        _moodEntries[index] = entry;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update mood entry: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Delete a mood entry
  Future<bool> deleteMoodEntry(String entryId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.deleteMoodEntry(entryId);

      // Remove from local list
      _moodEntries.removeWhere((e) => e.entryId == entryId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete mood entry: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Set filter level
  void setFilterLevel(MoodFilterLevel level) {
    _filterLevel = level;
    notifyListeners();
  }

  // Change selected month
  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  // Go to next month
  void nextMonth(String userId) {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    loadMoodEntries(userId);
  }

  // Go to previous month
  void previousMonth(String userId) {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    loadMoodEntries(userId);
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get mood entries for a specific date
  List<MoodEntry> getMoodEntriesForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return _moodEntries.where((entry) {
      final entryDate = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      return entryDate == targetDate;
    }).toList();
  }

  // Check if a date has mood entries
  bool hasEntriesForDate(DateTime date) {
    return getMoodEntriesForDate(date).isNotEmpty;
  }

  // Get average mood for a specific date
  double getAverageMoodForDate(DateTime date) {
    final entries = getMoodEntriesForDate(date);
    if (entries.isEmpty) return 0.0;
    
    final sum = entries.fold<int>(0, (sum, entry) => sum + entry.moodLevel);
    return sum / entries.length;
  }

  // Get mood color for calendar
  int getMoodColorForDate(DateTime date) {
    final avg = getAverageMoodForDate(date);
    if (avg == 0) return 0;
    return avg.round();
  }

  // Reset to current month
  void resetToCurrentMonth(String userId) {
    _selectedMonth = DateTime.now();
    loadMoodEntries(userId);
  }
}
