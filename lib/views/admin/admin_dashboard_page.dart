import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class AdminDashboardPage extends StatefulWidget {
  final Function(int)? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;

  // Stats
  int _totalUsers = 0;
  int _totalMeditations = 0;

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
        _supabase.from('users').select('role'),
        _supabase.from('meditations').select('id'),
      ]);

      final users = results[0] as List;
      final meditations = results[1] as List;

      final regularUsersCount = users.where((u) => u['role'] == 'user').length;

      setState(() {
        _totalUsers = regularUsersCount;
        _totalMeditations = meditations.length;
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

        // Overview
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Overview'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Users',
                      '$_totalUsers',
                      Icons.people_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Meditations',
                      '$_totalMeditations',
                      Icons.spa_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Quick actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      'Manage users',
                      Icons.people,
                      () => widget.onNavigate?.call(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      'Meditations',
                      Icons.spa,
                      () => widget.onNavigate?.call(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Analytics is not built yet — shown as a muted, disabled action.
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      'Analytics',
                      Icons.analytics_outlined,
                      null,
                      comingSoon: true,
                    ),
                  ),
                ],
              ),
            ],
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
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
                              'Admin dashboard',
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
                              Icons.verified_user,
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
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.osPrimaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.osOnPrimaryContainer, size: 20),
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

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    VoidCallback? onTap, {
    bool comingSoon = false,
  }) {
    final Color tileColor = comingSoon
        ? AppColors.osSurfaceContainer
        : AppColors.osPrimaryContainer;
    final Color iconColor = comingSoon
        ? AppColors.osOnSurfaceVariant
        : AppColors.osOnPrimaryContainer;

    return Opacity(
      opacity: comingSoon ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: _ambientShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tileColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.osOnSurface,
                  ),
                ),
                if (comingSoon) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Coming soon',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.osOnSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
          const SizedBox(height: 32),
          block(20, w: 140),
          const SizedBox(height: 16),
          Row(children: [cardSkeleton(), const SizedBox(width: 12), cardSkeleton()]),
        ],
      ),
    );
  }
}
