import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/app_user.dart';

/// ⚠️ CHẠY 1 LẦN ĐỂ TẠO ADMIN ACCOUNT
/// 
/// Cách sử dụng:
/// 1. Mở main.dart
/// 2. Import file này: import 'scripts/create_admin.dart';
/// 3. Gọi createAdminAccount() trong initState hoặc một button
/// 4. Sau khi tạo xong, XÓA hoặc COMMENT code này đi
/// 
Future<void> createAdminAccount() async {
  // ⚠️ THAY ĐỔI THÔNG TIN NÀY
  const String adminEmail = 'admin@mindfulmoments.com';
  const String adminPassword = 'Admin@123456'; // Password mạnh
  const String adminDisplayName = 'Admin';

  print('🔧 Starting admin account creation...');

  try {
    // 1. Thử tạo Firebase Auth user
    print('📧 Creating Firebase Auth user...');
    UserCredential? credential;
    
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️  Email already exists. Trying to sign in...');
        
        // Try to sign in
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        
        if (credential.user != null) {
          // Update to admin role
          final firestoreService = FirestoreService();
          await firestoreService.updateUserRole(credential.user!.uid, UserRole.admin);
          print('✅ Admin role updated for existing user');
        }
        
        return;
      } else {
        rethrow;
      }
    }

    final user = credential.user;
    if (user == null) {
      print('❌ Failed to create Firebase Auth user');
      return;
    }

    // 2. Update display name
    await user.updateDisplayName(adminDisplayName);
    print('✅ Display name updated');

    // 3. Tạo user document với role ADMIN
    print('📝 Creating Firestore user document...');
    final firestoreService = FirestoreService();
    await firestoreService.createOrUpdateUser(
      uid: user.uid,
      email: adminEmail,
      displayName: adminDisplayName,
      role: UserRole.admin, // ⭐ SET ADMIN ROLE
    );

    print('');
    print('🎉 ═══════════════════════════════════════');
    print('✅ Admin account created successfully!');
    print('═══════════════════════════════════════');
    print('📧 Email: $adminEmail');
    print('🔑 Password: $adminPassword');
    print('👤 Display Name: $adminDisplayName');
    print('🎭 Role: ADMIN');
    print('');
    print('⚠️  IMPORTANT:');
    print('1. Please change password after first login');
    print('2. Remove or comment out this script from your code');
    print('3. Never commit credentials to Git');
    print('═══════════════════════════════════════');
    
  } catch (e) {
    print('❌ Error creating admin account: $e');
    
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          print('💡 Email already in use. Try signing in with this email.');
          break;
        case 'weak-password':
          print('💡 Password is too weak. Use a stronger password.');
          break;
        case 'invalid-email':
          print('💡 Invalid email format.');
          break;
        default:
          print('💡 Error code: ${e.code}');
      }
    }
  }
}

/// Migrate existing logged-in user to Firestore
/// Sử dụng khi đã có user trong Firebase Auth nhưng chưa có trong Firestore
Future<void> migrateCurrentUser() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    print('❌ No user logged in');
    return;
  }

  print('🔧 Migrating user: ${currentUser.email}');

  try {
    final firestoreService = FirestoreService();
    
    // Check if user document already exists
    final existingUser = await firestoreService.getUser(currentUser.uid);
    
    if (existingUser != null) {
      print('✅ User document already exists');
      print('Role: ${existingUser.role.value}');
      return;
    }

    // Create user document
    await firestoreService.createOrUpdateUser(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      displayName: currentUser.displayName ?? 'User',
      photoUrl: currentUser.photoURL,
      role: UserRole.user, // Default role
    );

    print('✅ User migrated successfully: ${currentUser.email}');
  } catch (e) {
    print('❌ Migration error: $e');
  }
}
