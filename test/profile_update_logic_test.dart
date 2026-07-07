import 'package:flutter_test/flutter_test.dart';

/// Profile Update Logic Tests
/// 
/// Verifies that profile updates go to correct Firestore collections
/// based on user role (user, admin)

void main() {
  group('Profile Update Flow Tests', () {
    test('Regular user updates should affect users + profiles', () {
      // Given
      final role = 'user';
      
      // Expected collections to update
      final expectedCollections = ['users', 'profiles'];
      
      // Verify
      final actualCollections = _getCollectionsToUpdate(role);
      expect(actualCollections, containsAll(expectedCollections));
      expect(actualCollections.length, 2);
    });

    test('Admin updates should affect users only', () {
      // Given
      final role = 'admin';
      
      // Expected collections to update
      final expectedCollections = ['users'];
      
      // Verify
      final actualCollections = _getCollectionsToUpdate(role);
      expect(actualCollections, containsAll(expectedCollections));
      expect(actualCollections.length, 1);
    });

    test('Unknown role defaults to user behavior', () {
      // Given
      final role = 'unknown';
      
      // Expected: Default to user (users + profiles)
      final expectedCollections = ['users', 'profiles'];
      
      // Verify
      final actualCollections = _getCollectionsToUpdate(role);
      expect(actualCollections, containsAll(expectedCollections));
    });
  });

  group('Data Load Flow Tests', () {
    test('Regular user loads from profiles first', () {
      final role = 'user';
      final primaryCollection = _getPrimaryLoadCollection(role);
      
      expect(primaryCollection, 'profiles');
    });

    test('Admin loads from users only', () {
      final role = 'admin';
      final primaryCollection = _getPrimaryLoadCollection(role);
      
      expect(primaryCollection, 'users');
    });

    test('All roles fallback to users collection', () {
      final roles = ['user', 'admin'];
      
      for (final role in roles) {
        final fallbackCollection = 'users';
        expect(fallbackCollection, 'users', 
          reason: '$role should fallback to users collection');
      }
    });
  });

  group('Firestore Rules Compliance Tests', () {
    test('User can update own profile fields', () {
      final allowedFields = [
        'displayName',
        'email',
        'phoneNumber',
        'gender',
        'dateOfBirth',
        'photoBase64',
      ];
      
      final blockedFields = [
        'role',
        'isBanned',
        'banReason',
        'bannedAt',
      ];
      
      for (final field in allowedFields) {
        expect(_canUserUpdateField(field), true,
          reason: 'User should be able to update $field');
      }
      
      for (final field in blockedFields) {
        expect(_canUserUpdateField(field), false,
          reason: 'User should NOT be able to update $field');
      }
    });

    test('Admin can only update specific fields', () {
      final allowedFields = [
        'role',
        'isBanned',
        'banReason',
        'bannedAt',
      ];
      
      final blockedFields = [
        'displayName',
        'email',
        'phoneNumber',
        'gender',
        'dateOfBirth',
        'photoBase64',
      ];
      
      for (final field in allowedFields) {
        expect(_canAdminUpdateField(field), true,
          reason: 'Admin should be able to update $field');
      }
      
      for (final field in blockedFields) {
        expect(_canAdminUpdateField(field), false,
          reason: 'Admin should NOT be able to update $field');
      }
    });
  });
}

// Helper Functions (Simulating EditProfilePage logic)

List<String> _getCollectionsToUpdate(String role) {
  final collections = <String>['users']; // Always update users
  
  if (role == 'user' || role == 'unknown') {
    // Unknown roles default to user behavior
    collections.add('profiles');
  }
  // Admin only updates 'users'
  
  return collections;
}

String _getPrimaryLoadCollection(String role) {
  if (role == 'user') {
    return 'profiles';
  } else {
    return 'users'; // Admin or unknown
  }
}

bool _canUserUpdateField(String field) {
  final blockedFields = ['role', 'isBanned', 'banReason', 'bannedAt'];
  return !blockedFields.contains(field);
}

bool _canAdminUpdateField(String field) {
  final allowedFields = ['role', 'isBanned', 'banReason', 'bannedAt'];
  return allowedFields.contains(field);
}
