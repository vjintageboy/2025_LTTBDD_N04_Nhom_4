import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'scripts/populate_experts.dart';

/// Run this file to populate Firestore with sample expert data
/// Command: flutter run lib/populate_experts_main.dart
void main() async {
  print('====================================');
  print('📚 POPULATE EXPERTS DATA SCRIPT');
  print('====================================');
  print('');

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized');
  print('');

  // Add sample experts
  await PopulateExpertsData.addSampleExperts();

  print('');
  print('====================================');
  print('✨ SCRIPT COMPLETED!');
  print('====================================');
  print('');
  print('💡 Next steps:');
  print('   1. Check Firebase Console: https://console.firebase.google.com/');
  print('   2. Navigate to Firestore Database');
  print('   3. Look for "experts" collection');
  print('   4. Verify 8 expert documents are created');
  print('');
  print('🚀 You can now use these experts in your app!');
  print('');
}
