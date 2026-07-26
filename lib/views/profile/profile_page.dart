import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../services/supabase_service.dart';
import '../mood/mood_analytics_page.dart';
import 'edit_profile_page.dart';
import '../../models/streak.dart';
import '../../shared/widgets/language_switcher.dart';
import '../../shared/widgets/logout_dialog.dart';
import '../../core/utils/image_source.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabaseService = SupabaseService.instance;
  String? _avatarUrl;

  static const Color _kBg = Color(0xFFDBFCDF);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x0F0B361D),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  String _getUserDisplayName(User user) {
    if (user.userMetadata?['full_name'] != null) {
      return user.userMetadata!['full_name'];
    }
    return user.email?.split('@').first ?? 'User';
  }

  Future<void> _loadProfile() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;
    try {
      final data = await _supabaseService.getUserProfile(user.id);
      if (data != null && data['avatar_url'] != null && mounted) {
        setState(() => _avatarUrl = data['avatar_url']);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _refreshProfile() async {
    final user = _supabaseService.currentUser;
    if (user != null) {
      await _supabaseService.recalculateStreak(user.id);
      await _loadProfile();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabaseService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppColors.osPrimary,
        backgroundColor: AppColors.osSurfaceContainerLowest,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  _buildAvatar(user),
                  const SizedBox(height: 20),
                  Text(
                    _getUserDisplayName(user),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.osOnSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email ?? '',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.osOnSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildStreakSection(user),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.settings,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.osOnSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildOption(
                    icon: IconsaxPlusLinear.user,
                    title: context.l10n.editProfile,
                    subtitle: context.l10n.editProfileSubtitle,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                      if (result == true && mounted) await _refreshProfile();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildOption(
                    icon: IconsaxPlusLinear.notification,
                    title: context.l10n.notifications,
                    subtitle: context.l10n.notificationsSubtitle,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _buildOption(
                    icon: IconsaxPlusLinear.chart_2,
                    title: context.l10n.statistics,
                    subtitle: context.l10n.statisticsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MoodAnalyticsPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildOption(
                    icon: IconsaxPlusLinear.security_safe,
                    title: context.l10n.privacySecurity,
                    subtitle: context.l10n.privacySecuritySubtitle,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _buildOption(
                    icon: IconsaxPlusLinear.message_question,
                    title: context.l10n.helpSupport,
                    subtitle: context.l10n.helpSupportSubtitle,
                    onTap: () {},
                  ),
                  const SizedBox(height: 10),
                  _buildOption(
                    icon: IconsaxPlusLinear.document,
                    title: 'Thông tin tác giả',
                    subtitle: 'Xem thông tin sinh viên thực hiện',
                    onTap: () => _showAuthorInfo(context),
                  ),
                  const SizedBox(height: 10),
                  const LanguageSettingsTile(),
                  const SizedBox(height: 24),
                  _buildLogoutButton(),
                  // Clears the AI chat FAB, which floats over this tab and
                  // otherwise swallows taps on the log-out button.
                  const SizedBox(height: 124),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(User user) {
    final avatar = imageProviderFromSource(_avatarUrl);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.osPrimary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 56,
        backgroundColor: AppColors.osPrimaryContainer,
        backgroundImage: avatar,
        child: avatar == null
            ? Text(
                _getUserDisplayName(user).substring(0, 1).toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.osOnPrimaryContainer,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildStreakSection(User user) {
    return StreamBuilder<Streak?>(
      stream: _supabaseService.streamStreak(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(child: _buildStreakCardLoading()),
              const SizedBox(width: 12),
              Expanded(child: _buildStreakCardLoading()),
            ],
          );
        }
        final streak = snapshot.data;
        final current = streak?.currentStreak ?? 0;
        final longest = streak?.longestStreak ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStreakCard(
                title: context.l10n.currentStreak,
                value:
                    '$current ${current == 1 ? context.l10n.day : context.l10n.days}',
                icon: IconsaxPlusBold.star,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStreakCard(
                title: context.l10n.longestStreak,
                value:
                    '$longest ${longest == 1 ? context.l10n.day : context.l10n.days}',
                icon: IconsaxPlusBold.star,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.osPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.osOnSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCardLoading() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 60,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.osSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.osOnSurface.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.osSurfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.osPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.osOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.osOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: AppColors.osOutlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => confirmAndLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.osError,
          side: BorderSide(
            color: AppColors.osError.withValues(alpha: 0.3),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(IconsaxPlusLinear.logout, size: 20),
            const SizedBox(width: 8),
            Text(
              context.l10n.logout,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthorInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4FAF5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.osOutlineVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.osPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          IconsaxPlusLinear.document,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Thông tin tác giả',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.osOnSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.osSurfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: _cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _authorRow(IconsaxPlusBold.user, 'Sinh viên', 'Phạm Hoàng Anh'),
                        const SizedBox(height: 14),
                        _authorRow(IconsaxPlusLinear.personalcard, 'MSSV', '22010477'),
                        const SizedBox(height: 14),
                        _authorRow(IconsaxPlusLinear.book_1, 'Lớp/Khóa', 'K16 (2022-2026)'),
                        const SizedBox(height: 14),
                        _authorRow(IconsaxPlusLinear.bank, 'Trường', 'Phenikaa University'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.osPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Đóng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _authorRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.osPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColors.osOnSurface,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.osOnSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.osOnSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
