import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Auto-migrate existing user to Firestore collection 'users'
/// Gọi khi user login hoặc mở app
Future<void> migrateCurrentUser() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    return; // Not logged in, skip
  }

  try {
    // Check if user document already exists
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      // User already migrated, just update last login
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ User already exists: ${currentUser.email}');
      return;
    }

    // Create user document for the first time
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set({
      'email': currentUser.email ?? '',
      'displayName': currentUser.displayName ?? 'User',
      'photoUrl': currentUser.photoURL,
      'role': 'user', // Default role
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    print('✅ User migrated to Firestore: ${currentUser.email}');
    
  } catch (e) {
    print('❌ Migration error: $e');
    // Don't throw - app should continue working even if migration fails
  }
}
