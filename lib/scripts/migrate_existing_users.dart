import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// Migrate current authenticated user metadata into `users` table.
/// Safe to call many times (uses upsert under the hood).
Future<void> migrateCurrentUser() async {
  final service = SupabaseService.instance;
  final user = service.currentUser;

  if (user == null) {
    debugPrint('migrateCurrentUser: no authenticated user');
    return;
  }

  final metadata = user.userMetadata;
  final fullName =
      (metadata?['full_name']?.toString().trim().isNotEmpty ?? false)
      ? metadata!['full_name'].toString().trim()
      : user.email?.split('@').first ?? 'User';

  try {
    await service.createUserProfile(
      id: user.id,
      email: user.email ?? '',
      fullName: fullName,
    );
    debugPrint('migrateCurrentUser: profile upserted');
  } catch (e) {
    debugPrint('migrateCurrentUser error: $e');
  }
}
