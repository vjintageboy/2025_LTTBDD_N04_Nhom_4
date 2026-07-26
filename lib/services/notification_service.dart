import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/stream_utils.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;

  // Rows are created by the `notify_post_author` database trigger, not here —
  // users have no INSERT rights on `notifications`.

  // Stream notifications for a user
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return resilientStream(() => _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data)));
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
    }
  }

  // Delete a single notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
    }
  }

  // Delete every notification a user has
  Future<void> deleteAll(String userId) async {
    try {
      await _supabase.from('notifications').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('❌ Error deleting all notifications: $e');
    }
  }

  // Mark all of a user's unread notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('❌ Error marking all notifications as read: $e');
    }
  }
}
