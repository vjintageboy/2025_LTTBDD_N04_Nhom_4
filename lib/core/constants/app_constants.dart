class AppConstants {
  // Default user goals
  static const List<String> defaultUserGoals = [
    'Giảm stress',
    'Ngủ ngon hơn',
    'Tăng tập trung',
    'Tăng sự tự tin',
    'Cải thiện tâm trạng',
  ];

  // Emotion factors for mood tracking
  static const List<String> emotionFactors = [
    'Work',
    'Family',
    'Health',
    'Relationships',
    'Sleep',
    'Exercise',
    'Social',
    'Money',
    'Weather',
    'Food',
  ];

  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;

  // UI
  static const double defaultPadding = 24.0;
  static const double defaultBorderRadius = 14.0;
  static const double largeBorderRadius = 16.0;
  static const double buttonHeight = 52.0;

  // Animation durations
  static const Duration fadeAnimationDuration = Duration(milliseconds: 1500);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
}
