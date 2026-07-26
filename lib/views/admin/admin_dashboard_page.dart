import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile/profile_page.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/localization_service.dart';
import '../../shared/widgets/logout_dialog.dart';

class AdminDashboardPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;

  // Totals
  int _totalUsers = 0;
  int _totalMeditations = 0;
  int _totalPosts = 0;
  int _totalMoods = 0;

  // New in the last 7 days
  int _newUsersWeek = 0;
  int _newMeditationsWeek = 0;
  int _newPostsWeek = 0;
  int _newMoodsWeek = 0;

  String get _currentUserName =>
      _supabase.auth.currentUser?.userMetadata?['full_name'] as String? ??
      _supabase.auth.currentUser?.email?.split('@').first ??
      'Admin';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _supabase.from('users').select('role, is_banned, created_at'),
        _supabase.from('meditations').select('created_at'),
        _supabase.from('posts').select('created_at'),
        _supabase.from('mood_entries').select('created_at'),
      ]);

      final users = results[0] as List;
      final meditations = results[1] as List;
      final posts = results[2] as List;
      final moods = results[3] as List;

      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      bool isNew(dynamic row) {
        final ts = DateTime.tryParse(row['created_at']?.toString() ?? '');
        return ts != null && ts.isAfter(weekAgo);
      }

      // Only count regular users (exclude admins).
      final regularUsers =
          users.where((u) => u['role'] == 'user').toList();

      setState(() {
        _totalUsers = regularUsers.length;
        _totalMeditations = meditations.length;
        _totalPosts = posts.length;
        _totalMoods = moods.length;
        _newUsersWeek = regularUsers.where(isNew).length;
        _newMeditationsWeek = meditations.where(isNew).length;
        _newPostsWeek = posts.where(isNew).length;
        _newMoodsWeek = moods.where(isNew).length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading admin dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  // Ambient tinted shadow — mimics natural light instead of a grey smudge.
  static const List<BoxShadow> _ambientShadow = [
    BoxShadow(
      color: Color(0x0F0B361D), // osOnSurface @ ~6%
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.osSurface,
      child: SafeArea(
        top: false, // allow the header to extend behind the status bar
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.osPrimary,
          backgroundColor: AppColors.osSurfaceContainerLowest,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: _isLoading ? _buildSkeleton() : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Overview — 4 headline metrics.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Tổng quan'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Người dùng',
                      '$_totalUsers',
                      IconsaxPlusLinear.profile_2user,
                      _newUsersWeek,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Bài thiền',
                      '$_totalMeditations',
                      PhosphorIconsRegular.flowerLotus,
                      _newMeditationsWeek,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Bài viết',
                      '$_totalPosts',
                      IconsaxPlusLinear.document_text,
                      _newPostsWeek,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Nhật ký cảm xúc',
                      '$_totalMoods',
                      IconsaxPlusLinear.emoji_happy,
                      _newMoodsWeek,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Analytics navigation.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onNavigate?.call(4),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.osSurfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _ambientShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.osPrimaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        IconsaxPlusLinear.chart_2,
                        color: AppColors.osOnPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Xem phân tích chi tiết',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.osOnSurface,
                        ),
                      ),
                    ),
                    Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      color: AppColors.osOnSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.osOnSurface,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.osPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfilePage(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            IconsaxPlusLinear.user_tick,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bảng điều khiển',
                                style: GoogleFonts.manrope(
                                  color: AppColors.osOnPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentUserName,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                IconsaxPlusLinear.shield_tick,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ADMIN',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => confirmAndLogout(context),
                          tooltip: context.l10n.logout,
                          icon: const Icon(
                            IconsaxPlusLinear.logout,
                            color: Colors.white,
                            size: 22,
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
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    int newThisWeek,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.osPrimaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.osOnPrimaryContainer,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (newThisWeek > 0) _buildDeltaChip(newThisWeek),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
              letterSpacing: -0.5,
              color: AppColors.osOnSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.osOnSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // "+N mới trong 7 ngày" pill shown on a stat card.
  Widget _buildDeltaChip(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.osPrimaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconsaxPlusLinear.arrow_up_1,
            size: 12,
            color: AppColors.osOnPrimaryContainer,
          ),
          const SizedBox(width: 2),
          Text(
            '$value',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.osOnPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton loader that matches the content shape (no generic spinner).
  Widget _buildSkeleton() {
    Widget block(double h, {double? w, double r = 16}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainer,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    Widget cardSkeleton() => Expanded(
      child: Container(
        height: 108,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.osSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _ambientShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            block(36, w: 36, r: 10),
            const Spacer(),
            block(20, w: 48),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(20, w: 120),
          const SizedBox(height: 16),
          Row(children: [cardSkeleton(), const SizedBox(width: 12), cardSkeleton()]),
          const SizedBox(height: 12),
          Row(children: [cardSkeleton(), const SizedBox(width: 12), cardSkeleton()]),
          const SizedBox(height: 24),
          block(60),
        ],
      ),
    );
  }
}
