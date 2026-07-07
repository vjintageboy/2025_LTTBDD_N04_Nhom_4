import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';
import 'meditation_management_page.dart';
import '../news/news_feed_page.dart';
import 'admin_analytics_page.dart';
import '../../core/constants/app_colors.dart';

/// Main navigation page for admins with specialized dashboard
/// Shows: Dashboard, Users, Meditations, Profile
class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentTab;

    switch (_selectedIndex) {
      case 0:
        currentTab = AdminDashboardPage(onNavigate: _switchTab);
        break;
      case 1:
        currentTab = const AdminUserManagementPage();
        break;
      case 2:
        currentTab = const NewsFeedPage(moderateAll: true);
        break;
      case 3:
        currentTab = const MeditationManagementPage();
        break;
      case 4:
        currentTab = const AdminAnalyticsPage();
        break;
      default:
        currentTab = const AdminDashboardPage();
    }

    return Scaffold(
      backgroundColor: AppColors.osSurface,
      body: currentTab,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.osSurfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0B361D), // osOnSurface @ ~6%
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    0,
                    IconsaxPlusLinear.element_3,
                    IconsaxPlusBold.element_3,
                    'Dashboard',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    1,
                    IconsaxPlusLinear.profile_2user,
                    IconsaxPlusBold.profile_2user,
                    'Users',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    2,
                    IconsaxPlusLinear.document_text,
                    IconsaxPlusBold.document_text,
                    'News',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    PhosphorIconsRegular.flowerLotus,
                    PhosphorIconsFill.flowerLotus,
                    'Meditations',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    4,
                    IconsaxPlusLinear.chart_2,
                    IconsaxPlusBold.chart_2,
                    'Phân tích',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected
                ? AppColors.osPrimary
                : AppColors.osOnSurfaceVariant,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: 11,
              color: isSelected
                  ? AppColors.osPrimary
                  : AppColors.osOnSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
