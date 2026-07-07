import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';
import '../../core/constants/app_colors.dart';
import 'user_detail_page.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = '';
  List<Map<String, dynamic>>? _allUsers;
  bool _isLoading = true;

  // Uniform page background.
  static const Color _kBg = Color(0xFFDBFCDF);

  static const List<BoxShadow> _ambientShadow = [
    BoxShadow(
      color: Color(0x0F0B361D),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _allUsers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _computeFilteredUsers() {
    final all = _allUsers ?? const <Map<String, dynamic>>[];
    return all.where((data) {
      final user = AppUser.fromMap(data);
      // Only manage regular users — hide admin accounts.
      if (user.role == UserRole.admin) return false;
      if (_searchQuery.isEmpty) return true;
      return user.displayName.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers =
        _isLoading ? <Map<String, dynamic>>[] : _computeFilteredUsers();
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),

          // Search bar only (no filter)
          Container(
            color: _kBg,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                hintStyle: GoogleFonts.manrope(
                  color: AppColors.osOnSurfaceVariant,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.osOnSurfaceVariant,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.osSurfaceContainer,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.osPrimary,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: AppColors.osPrimary,
                    backgroundColor: AppColors.osSurfaceContainerLowest,
                    child: filteredUsers.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: AppColors.osOutlineVariant,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Không tìm thấy người dùng',
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          color:
                                              AppColors.osOnSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) =>
                                _buildUserCard(filteredUsers[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // Full-width header with a light green gradient background.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _kBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Quản lý người dùng',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.osOnSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.osOnSurface,
                ),
                onPressed: _loadUsers,
                tooltip: 'Làm mới',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data) {
    final user = AppUser.fromMap(data);
    final isBanned = data['is_banned'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _ambientShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetail(data),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.osPrimaryContainer,
                  child: Text(
                    _userInitial(user),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.osOnPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppColors.osOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: AppColors.osOnSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isBanned)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BỊ KHÓA',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Open the full detail page; reload the list if anything changed.
  Future<void> _openDetail(Map<String, dynamic> data) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UserDetailPage(data: data)),
    );
    if (changed == true) _loadUsers();
  }

  String _userInitial(AppUser user) {
    final displayName = user.displayName.trim();
    if (displayName.isNotEmpty) {
      return displayName.characters.first.toUpperCase();
    }

    final email = user.email.trim();
    if (email.isNotEmpty) {
      return email.characters.first.toUpperCase();
    }

    return '?';
  }

}
