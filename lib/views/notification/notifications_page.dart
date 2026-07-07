import 'package:n04_app/dummy_firebase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.streamNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['isRead'] ?? false;
              final timestamp =
                  notification['createdAt'] as dynamic; // DateTime or null

              DateTime? dateTime;
              if (timestamp != null) {
                // Handle Firestore DateTime
                if (timestamp.toString().contains('DateTime')) {
                  // Assuming it's a Firestore DateTime object, but since we get Map<String, dynamic>,
                  // it might be dynamic. If we imported cloud_firestore, we could cast.
                  // For safety, let's try to use it if it has toDate() or similar,
                  // but since we are in a pure Dart file without cloud_firestore import in this snippet (wait, I should import it if needed, but service handles it).
                  // Actually, the service returns Map<String, dynamic>.
                  // If it's a DateTime, we can't easily use it without importing cloud_firestore.
                  // Let's import cloud_firestore or handle it dynamically.
                  // Better to import cloud_firestore to be safe.
                }
              }

              return Dismissible(
                key: Key(notification['id']),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  // TODO: Implement delete notification
                },
                child: Card(
                  elevation: 0,
                  color: isRead ? Colors.white : const Color(0xFFE8F5E9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        notificationService.markAsRead(notification['id']);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIcon(notification['type']),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification['title'] ?? 'Notification',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIcon(String? type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'refund':
        iconData = Icons.monetization_on;
        color = Colors.orange;
        break;
      case 'refund_error':
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
      case 'cancellation':
        iconData = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    // Handle Firestore DateTime
    try {
      // Use dynamic dispatch to call toDate() if it exists (Firestore DateTime)
      final date = (timestamp as dynamic).toDate();
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }
}
