import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/localization_service.dart';
import '../../models/streak.dart';
import '../../models/meditation.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../scripts/migrate_existing_users.dart';
import '../mood/mood_log_page.dart';
import '../meditation/meditation_detail_page.dart';
import '../streak/streak_history_page.dart';
import '../notification/notifications_page.dart';
import '../meditation/meditation_library_page.dart';
import '../../core/utils/image_source.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;

  Streak? _streak;
  List<Meditation> _meditations = [];
  String? _avatarUrl;
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _migrateUser();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _migrateUser() async {
    try {
      await migrateCurrentUser();
    } catch (e) {
      debugPrint('⚠️ _migrateUser skipped: $e');
    }
  }

  Future<void> _loadData() async {
    final user = _supabaseService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _supabaseService.recalculateStreak(user.id);
      final streak = await _supabaseService.getStreak(user.id);
      final meditationsData = await _supabaseService.getMeditations();
      final meditations = meditationsData.take(1).map((m) => Meditation.fromMap(m)).toList();
      final profile = await _supabaseService.getUserProfile(user.id);
      if (mounted) {
        setState(() {
          _streak = streak;
          _meditations = meditations;
          _avatarUrl = profile?['avatar_url'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading home data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = context.l10n.unableToLoadData;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.goodMorning;
    if (hour < 18) return context.l10n.goodAfternoon;
    return context.l10n.goodEvening;
  }

  String _getUserName() {
    final user = _supabaseService.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return user?.email?.split('@').first ?? 'User';
  }

  String _getUserInitial() {
    final name = _getUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  void _handleMoodSelection(int mood) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MoodLogPage(initialMoodLevel: mood)),
    ).then((saved) {
      if (saved == true && mounted) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.osSurface,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.osPrimary, strokeWidth: 3),
        ),
      );
    }
    if (_errorMessage != null) return _buildErrorState();

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.osSurface,
      child: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.osPrimary,
            backgroundColor: AppColors.osSurfaceContainerLowest,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: EdgeInsets.only(
                  top: topPadding + 64,
                  left: 20,
                  right: 20,
                  bottom: 124,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Welcome
                  const SizedBox(height: 24),
                  _buildWelcome(),
                  const SizedBox(height: 20),
                  // Mood check-in
                  _buildMoodCard(),
                  const SizedBox(height: 16),
                  // Streak
                  _buildStreakCard(),
                  // Featured meditation
                  if (_meditations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildFeaturedMeditation(_meditations.first),
                  ],
                  // Daily quote
                  const SizedBox(height: 24),
                  _buildDailyQuote(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // ── Glassmorphism top app bar ────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(topPadding),
          ),
        ],
      ),
    );
  }

  // ── TOP APP BAR ──────────────────────────────────────────────────────────

  Widget _buildTopBar(double topPadding) {
    final avatar = imageProviderFromSource(_avatarUrl);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: topPadding + 64,
          decoration: BoxDecoration(
            color: AppColors.osSurface.withValues(alpha: 0.80),
            boxShadow: [
              BoxShadow(
                color: AppColors.osOnSurface.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.only(top: topPadding, left: 20, right: 20),
          child: Row(
            children: [
              // User avatar — falls back to the name initial when unset.
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.osPrimaryContainer,
                backgroundImage: avatar,
                child: avatar == null
                    ? Text(
                        _getUserInitial(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.osPrimary,
                        ),
                      )
                    : null,
              ),
              // Brand name
              Expanded(
                child: Center(
                  child: Text(
                    'Moodiki',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.osOnSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              // Notification bell
              StreamBuilder<List<Map<String, dynamic>>>(
                // Rebuilt with the widget on purpose: this StreamBuilder sits in
                // a subtree that is torn down whenever _isLoading flips, and
                // `resilientStream` is single-subscription, so a hoisted stream
                // would throw "Stream has already been listened to" on re-inflate.
                stream: NotificationService().streamNotifications(
                  _supabaseService.currentUser?.id ?? '',
                ),
                builder: (context, snapshot) {
                  final unreadCount = (snapshot.data ?? [])
                      .where((n) => n['is_read'] != true)
                      .length;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationsPage()),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.osSurfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            IconsaxPlusLinear.notification,
                            color: AppColors.osPrimary,
                            size: 20,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.osError,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: AppColors.osOnError,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── WELCOME ──────────────────────────────────────────────────────────────

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting().toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.osOnSurfaceVariant,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chào ${_getUserName()},',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.osOnSurface,
            letterSpacing: -0.5,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── MOOD CHECK-IN CARD ───────────────────────────────────────────────────

  Widget _buildMoodCard() {
    const emojis = ['😢', '🙁', '😐', '😊', '🤩'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.osOnSurface.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.howAreYouFeelingShort,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.osOnSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final level = i + 1;
              return GestureDetector(
                onTap: () => _handleMoodSelection(level),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: level == 3
                            ? AppColors.osSurfaceContainerHigh
                            : AppColors.osSurfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(emojis[i], style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$level',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.osOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── STREAK CARD ──────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    final current = _streak?.currentStreak ?? 0;
    final longest = _streak?.longestStreak ?? 0;
    final total = _streak?.totalActivities ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StreakHistoryPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.osPrimary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.osPrimary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative blob
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.osPrimaryContainer.withValues(alpha: 0.15),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.yourWellnessStreak.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.osOnPrimary.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildStreakStat(
                        value: current.toString().padLeft(2, '0'),
                        label: context.l10n.currentDays,
                      ),
                      VerticalDivider(
                        color: AppColors.osOnPrimary.withValues(alpha: 0.2),
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      _buildStreakStat(
                        value: longest.toString().padLeft(2, '0'),
                        label: context.l10n.longestDays,
                      ),
                      VerticalDivider(
                        color: AppColors.osOnPrimary.withValues(alpha: 0.2),
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      _buildStreakStat(
                        value: total.toString().padLeft(2, '0'),
                        label: context.l10n.totalLogs,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakStat({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.osOnPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.osOnPrimary.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── FEATURED MEDITATION ──────────────────────────────────────────────────

  Widget _buildFeaturedMeditation(Meditation meditation) {
    // Covers are stored as base64 (or a legacy URL), not always a URL.
    final cover = imageProviderFromSource(meditation.thumbnailUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.featuredMeditation,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.osOnSurface,
                ),
              ),
            ),
            // Only route to the meditation library now that the quick-action
            // grid is gone.
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeditationLibraryPage()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.osOnPrimaryContainer,
                backgroundColor: AppColors.osSurfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 44),
                shape: const StadiumBorder(),
              ),
              child: Text(
                context.l10n.viewAll,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MeditationDetailPage(meditation: meditation)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.osOnSurface.withValues(alpha: 0.06),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: cover != null
                      ? Image(
                          image: cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.osSurfaceContainerHigh),
                        )
                          : Container(
                          color: AppColors.osSurfaceContainerHigh,
                          child: const Icon(PhosphorIconsRegular.personSimpleTaiChi, size: 48, color: AppColors.osPrimary),
                        ),
                ),
                // Info row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meditation.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.osOnSurface,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(IconsaxPlusLinear.clock, size: 14, color: AppColors.osOnSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  '${meditation.duration} min',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.osOnSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Play button
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.osPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(IconsaxPlusBold.play, color: AppColors.osOnPrimary, size: 30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── DAILY QUOTE ──────────────────────────────────────────────────────────

  Widget _buildDailyQuote() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFBEF5CA).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative quote mark
          Positioned(
            top: -4,
            left: -4,
            child: Text(
              '"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: AppColors.osPrimary.withValues(alpha: 0.12),
                height: 1,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.dailyInspiration.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.osPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '"${context.l10n.wellnessQuote}"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.osOnSurface,
                  fontStyle: FontStyle.italic,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '— ${context.l10n.wellnessQuoteAttribution}',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ERROR STATE ──────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Container(
      color: AppColors.osSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusLinear.danger,
                size: 56,
                color: AppColors.osError.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: AppColors.osOnSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _loadData,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.osPrimary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.tryAgain,
                    style: GoogleFonts.manrope(
                      color: AppColors.osOnPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
