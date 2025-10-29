import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1A1A1A);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color accent = Color(0xFF8BC34A);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Background colors
  static const Color background = Colors.white;
  static const Color backgroundGrey = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFF5F5F5);

  // Border colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);

  // Status colors
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Mood colors
  static const Color moodVeryPoor = Color(0xFFEF5350); // Red
  static const Color moodPoor = Color(0xFFFF9800); // Orange
  static const Color moodOkay = Color(0xFFFFEB3B); // Yellow
  static const Color moodGood = Color(0xFF8BC34A); // Light Green
  static const Color moodExcellent = Color(0xFF4CAF50); // Green

  // Category colors
  static const Color categoryStress = Color(0xFFE8F5E9);
  static const Color categoryAnxiety = Color(0xFFE3F2FD);
  static const Color categorySleep = Color(0xFFD1F2EB);
  static const Color categoryFocus = Color(0xFFFFF3E0);

  // Helper methods
  static Color getMoodColor(int moodLevel) {
    switch (moodLevel) {
      case 1:
        return moodVeryPoor;
      case 2:
        return moodPoor;
      case 3:
        return moodOkay;
      case 4:
        return moodGood;
      case 5:
        return moodExcellent;
      default:
        return textSecondary;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'stress':
        return categoryStress;
      case 'anxiety':
        return categoryAnxiety;
      case 'sleep':
        return categorySleep;
      case 'focus':
        return categoryFocus;
      default:
        return backgroundLight;
    }
  }
}
