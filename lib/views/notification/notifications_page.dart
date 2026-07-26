import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/localization_service.dart';
import '../../services/news_service.dart';
import '../../services/notification_service.dart';
import '../news/post_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  late final String _userId =
      Supabase.instance.client.auth.currentUser?.id ?? '';

  /// Subscribed to once. Building the stream inside `build` would tear down and
  /// re-create the realtime subscription on every rebuild, so live inserts and
  /// read-state changes would only ever show up after a manual reload.
  late final Stream<List<Map<String, dynamic>>> _notifications =
      _service.streamNotifications(_userId);

  /// Swiped-away rows, hidden until the stream catches up. Without this the list
  /// would rebuild the row a dismissed [Dismissible] just removed, which trips
  /// "A dismissed Dismissible widget is still part of the tree".
  final _dismissed = <String>{};

  @override
  Widget build(BuildContext context) {
    // Wraps the whole scaffold so the header can show the unread count from the
    // same stream the list uses.
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _notifications,
      builder: (context, snapshot) {
        final notifications = (snapshot.data ?? [])
            .where((n) => !_dismissed.contains(n['id']))
            .toList();
        final unreadCount =
            notifications.where((n) => n['is_read'] != true).length;

        return Scaffold(
          backgroundColor: AppColors.osSurface,
          extendBodyBehindAppBar: true,
          appBar: _buildGlassAppBar(
            context,
            unreadCount: unreadCount,
            hasAny: notifications.isNotEmpty,
          ),
          body: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 72,
            ),
            child: _buildBody(context, snapshot, notifications),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildGlassAppBar(
    BuildContext context, {
    required int unreadCount,
    required bool hasAny,
  }) {
    final l10n = context.l10n;
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.osSurface.withValues(alpha: 0.80),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.osSurfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            IconsaxPlusLinear.arrow_left,
                            size: 20,
                            color: AppColors.osOnSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.notifications,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.osOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.osPrimary,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.osOnPrimary,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (unreadCount > 0)
                        _headerAction(
                          icon: IconsaxPlusLinear.tick_circle,
                          tooltip: l10n.markAllAsRead,
                          color: AppColors.osPrimary,
                          onTap: () => _service.markAllAsRead(_userId),
                        ),
                      if (hasAny) ...[
                        const SizedBox(width: 8),
                        _headerAction(
                          icon: IconsaxPlusLinear.trash,
                          tooltip: l10n.deleteAllNotifications,
                          color: AppColors.osError,
                          onTap: _confirmDeleteAll,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.osSurfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  /// Deleting every notification is irreversible — users cannot insert rows back
  /// into `notifications`, so there is no undo to offer.
  Future<void> _confirmDeleteAll() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.osSurfaceContainerLowest,
        title: Text(
          l10n.deleteAllNotifications,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          l10n.deleteAllNotificationsConfirm,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.manrope(
                color: AppColors.osOnSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.osError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.delete,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) await _service.deleteAll(_userId);
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    List<Map<String, dynamic>> notifications,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.osPrimary),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                IconsaxPlusLinear.danger,
                size: 56,
                color: AppColors.osError,
              ),
              const SizedBox(height: 16),
              Text(
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.osSurfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIconsRegular.bellSlash,
                  size: 40,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.noNotificationsYet,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.osOnSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.notificationsEmptyHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: notifications.length,
      itemBuilder: (context, index) =>
          _buildNotificationCard(context, notifications[index]),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final id = notification['id'] as String;
    final isRead = notification['is_read'] == true;
    // Written by the `notify_post_author` trigger; older rows have no metadata,
    // and realtime does not guarantee the generic type of a decoded jsonb map.
    final metadata = notification['metadata'];
    final postId = metadata is Map ? metadata['post_id'] as String? : null;

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        setState(() => _dismissed.add(id));
        _service.deleteNotification(id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.osError,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          IconsaxPlusLinear.trash,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: _notificationBody(context, notification, id, isRead, postId),
    );
  }

  Widget _notificationBody(
    BuildContext context,
    Map<String, dynamic> notification,
    String id,
    bool isRead,
    String? postId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.osSurfaceContainerLowest
            : AppColors.osSecondaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.osOnSurface.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isRead && postId == null
              ? null
              : () {
                  if (!isRead) _service.markAsRead(id);
                  if (postId != null) _openPost(context, postId);
                },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeIcon(notification['type'] as String?, isRead),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? context.l10n.notifications,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                          color: AppColors.osOnSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.osOnSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(context, notification['created_at']),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.osOutline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    margin: const EdgeInsets.only(top: 6, left: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.osPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the post the notification is about. The stream only carries the id,
  /// so the post is fetched on tap rather than joined into every row.
  Future<void> _openPost(BuildContext context, String postId) async {
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = context.l10n.postUnavailable;

    final post = await NewsService().getPost(postId);
    if (!context.mounted) return;

    if (post == null) {
      messenger.showSnackBar(SnackBar(content: Text(unavailable)));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
    );
  }

  /// Types come from the `notify_post_author` trigger: a like or a comment.
  Widget _buildTypeIcon(String? type, bool isRead) {
    late final IconData iconData;
    late final Color foreground;

    switch (type) {
      case 'like':
        iconData = IconsaxPlusBold.heart;
        foreground = AppColors.osError;
        break;
      case 'comment':
        iconData = IconsaxPlusBold.message_text;
        foreground = AppColors.osTertiary;
        break;
      default:
        iconData = IconsaxPlusBold.notification;
        foreground = AppColors.osPrimary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.osSurfaceContainerHigh
            : AppColors.osSurfaceContainerLowest,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: foreground, size: 22),
    );
  }

  String _formatTime(BuildContext context, dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp is DateTime
        ? timestamp
        : DateTime.tryParse(timestamp.toString());
    if (date == null) return '';

    final l10n = context.l10n;
    final difference = DateTime.now().difference(date);

    if (difference.inSeconds < 60) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
