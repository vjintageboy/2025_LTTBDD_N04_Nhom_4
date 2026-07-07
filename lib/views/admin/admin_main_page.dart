import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_user_management_page.dart';
import 'meditation_management_page.dart';
import '../news/news_manager_page.dart';
import '../profile/profile_page.dart';
import '../../core/services/localization_service.dart';

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
        currentTab = const NewsManagerPage();
        break;
      case 3:
        currentTab = const MeditationManagementPage();
        break;
      case 4:
        currentTab = const ProfilePage();
        break;
      default:
        currentTab = const AdminDashboardPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: currentTab,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
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
                    Icons.dashboard_outlined,
                    Icons.dashboard,
                    'Dashboard',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    1,
                    Icons.people_outline,
                    Icons.people,
                    'Users',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    2,
                    Icons.article_outlined,
                    Icons.article,
                    'News',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    3,
                    Icons.spa_outlined,
                    Icons.spa,
                    'Meditations',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    4,
                    Icons.person_outline,
                    Icons.person,
                    context.l10n.profile,
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
            color: isSelected ? const Color(0xFF7B2BB0) : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF7B2BB0) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
