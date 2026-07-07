import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../mood/mood_history_page.dart';
import '../profile/profile_page.dart';
import '../news/news_feed_page.dart';
import '../chatbot/chatbot_page.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';
import 'new_home_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _fabGlowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);
  bool _shouldGlow = false;

  static const _pages = [
    NewHomePage(),
    MoodHistoryPage(),
    NewsFeedPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadMoodState();
  }

  @override
  void dispose() {
    _fabGlowController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodState() async {
    try {
      final service = SupabaseService.instance;
      final user = service.currentUser;
      if (user == null) return;
      final moods = await service.getMoodEntries(user.id);
      final latest = moods.isNotEmpty ? moods.first.moodLevel : null;
      final shouldGlow = latest != null && latest <= 2;
      if (mounted && _shouldGlow != shouldGlow) {
        setState(() => _shouldGlow = shouldGlow);
      }
    } catch (_) {}
  }

  void _onTabTap(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
    _loadMoodState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _OsBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onTabTap,
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: AnimatedBuilder(
        animation: _fabGlowController,
        builder: (context, child) {
          final t = _fabGlowController.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.osPrimary.withValues(
                    alpha: _shouldGlow ? 0.22 + 0.18 * t : 0.18,
                  ),
                  blurRadius: _shouldGlow ? 18 + 10 * t : 12,
                  spreadRadius: _shouldGlow ? 1 + 1.5 * t : 0,
                ),
              ],
            ),
            child: child,
          );
        },
        child: FloatingActionButton(
          heroTag: 'ai_fab',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatbotPage()),
          ),
          backgroundColor: AppColors.osPrimary,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(PhosphorIconsRegular.robot, color: AppColors.osOnPrimary, size: 26),
        ),
      ),
    );
  }
}

// ============================================================================
// GLASSMORPHISM BOTTOM NAV — 4 TABS
// ============================================================================
class _OsBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _OsBottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final items = [
      _NavItem(icon: IconsaxPlusLinear.home,        filledIcon: IconsaxPlusBold.home,        label: context.l10n.home),
      _NavItem(icon: PhosphorIconsRegular.smiley,         filledIcon: PhosphorIconsRegular.smiley,         label: context.l10n.mood),
      _NavItem(icon: IconsaxPlusLinear.document_text,      filledIcon: IconsaxPlusLinear.document_text,      label: context.l10n.news),
      _NavItem(icon: IconsaxPlusLinear.user,filledIcon: IconsaxPlusBold.user,       label: context.l10n.profile),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.osSurface.withValues(alpha: 0.70),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.osOnSurface.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, bottomPadding > 0 ? 0 : 8),
              child: Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final isSelected = selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: isSelected
                            ? BoxDecoration(
                                color: AppColors.osPrimary,
                                borderRadius: BorderRadius.circular(999),
                              )
                            : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? item.filledIcon : item.icon,
                              size: 22,
                              color: isSelected
                                  ? AppColors.osOnPrimary
                                  : AppColors.osOnSurface.withValues(alpha: 0.50),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: GoogleFonts.manrope(
                                fontSize: 9,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.osOnPrimary
                                    : AppColors.osOnSurface.withValues(alpha: 0.50),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData filledIcon;
  final String label;
  const _NavItem({required this.icon, required this.filledIcon, required this.label});
}
