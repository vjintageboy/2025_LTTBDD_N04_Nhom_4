import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';
import '../../core/constants/app_colors.dart';

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
    if (_searchQuery.isEmpty) return all;
    return all.where((data) {
      final user = AppUser.fromMap(data);
      return user.displayName.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers =
        _isLoading ? <Map<String, dynamic>>[] : _computeFilteredUsers();
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      appBar: AppBar(
        backgroundColor: AppColors.osPrimary,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
            ),
          ),
        ),
        title: Text(
          'Quản lý người dùng',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar only (no filter)
          Container(
            color: AppColors.osSurfaceContainerLowest,
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
                            itemBuilder: (context, index) {
                              final data = filteredUsers[index];
                              final user = AppUser.fromMap(data);
                              final isBanned =
                                  data['is_banned'] as bool? ?? false;
                              final banReason =
                                  data['ban_reason'] as String?;
                              return _buildUserCard(user, isBanned, banReason);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user, bool isBanned, String? banReason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              _buildRoleBadge(user.role),
            ],
          ),
          const SizedBox(height: 16),

          if (isBanned && banReason != null && banReason.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 20,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lý do khóa:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banReason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tham gia ${user.createdAt != null ? _formatDate(user.createdAt!) : 'N/A'}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
              Row(
                children: [
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
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: PopupMenuButton<String>(
                      onSelected: (value) => _handleAction(value, user),
                      itemBuilder: (context) => [
                        if (!isBanned)
                          const PopupMenuItem(
                            value: 'ban',
                            child: Row(
                              children: [
                                Icon(Icons.block, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Khóa người dùng'),
                              ],
                            ),
                          )
                        else
                          const PopupMenuItem(
                            value: 'unban',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Mở khóa'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa người dùng'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.osSurfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color: AppColors.osOnSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final bool isAdmin = role == UserRole.admin;
    final Color bg = isAdmin
        ? AppColors.osPrimaryContainer
        : AppColors.osSurfaceContainer;
    final Color fg = isAdmin
        ? AppColors.osOnPrimaryContainer
        : AppColors.osOnSurfaceVariant;
    final String label = isAdmin ? 'ADMIN' : 'USER';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  Future<void> _handleAction(String action, AppUser user) async {
    switch (action) {
      case 'ban':
        await _banUser(user);
        break;
      case 'unban':
        await _unbanUser(user);
        break;
      case 'delete':
        await _deleteUser(user);
        break;
    }
  }

  Future<void> _banUser(AppUser user) async {
    final reason = await _showBanDialog();
    if (reason == null) return;

    try {
      await _supabase.from('users').update({
        'is_banned': true,
        'ban_reason': reason,
      }).eq('id', user.id);

      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã khóa người dùng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _unbanUser(AppUser user) async {
    try {
      await _supabase.from('users').update({
        'is_banned': false,
        'ban_reason': null,
      }).eq('id', user.id);

      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã mở khóa người dùng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await _showDeleteConfirmation(user);
    if (!confirmed) return;

    try {
      await _supabase.from('users').delete().eq('id', user.id);

      await _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa người dùng')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<String?> _showBanDialog() async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khóa người dùng'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Lý do khóa...'),
          onChanged: (value) => reason = value,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reason),
            child: const Text('Khóa'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(AppUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc muốn xóa ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
