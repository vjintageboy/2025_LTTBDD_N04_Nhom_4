import 'package:flutter/material.dart';
import '../../models/meditation.dart';

/// Admin Dashboard Widget - Hiển thị statistics và quick actions cho admin
class AdminDashboardWidget extends StatelessWidget {
  final List<Meditation> meditations;
  final int totalUsers;

  const AdminDashboardWidget({
    super.key,
    required this.meditations,
    required this.totalUsers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Dashboard Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Statistics Card
        _buildAdminStats(),
        const SizedBox(height: 24),

        // Quick Actions Title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Admin Controls
        _buildAdminControls(context),
        const SizedBox(height: 32),
      ],
    );
  }

  /// Platform Statistics Card
  Widget _buildAdminStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade400,
              Colors.purple.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Platform Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people_outline,
                    label: 'Total Users',
                    value: '$totalUsers',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.spa_outlined,
                    label: 'Meditations',
                    value: '${meditations.length}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Individual Stat Item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  /// Admin Quick Action Buttons
  Widget _buildAdminControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildAdminButton(
              context: context,
              icon: Icons.add_circle_outline,
              label: 'Add Meditation',
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              onTap: () {
                // TODO: Navigate to upload meditation page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upload Meditation - Coming Soon!'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAdminButton(
              context: context,
              icon: Icons.people_outline,
              label: 'Manage Users',
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
              onTap: () {
                // TODO: Navigate to user management page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User Management - Coming Soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Admin Action Button
  Widget _buildAdminButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
