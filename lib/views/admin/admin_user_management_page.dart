import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = '';
  String _filterRole = 'all'; // all, user, expert, admin
  List<Map<String, dynamic>>? _allUsers;
  bool _isLoading = true;

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
      if (_filterRole != 'all' && user.role.name != _filterRole) return false;
      if (_searchQuery.isNotEmpty) {
        return user.displayName.toLowerCase().contains(_searchQuery) ||
            user.email.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _isLoading ? <Map<String, dynamic>>[] : _computeFilteredUsers();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B2BB0),
        elevation: 0,
        title: const Text(
          'User Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
          // Search and Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Users', 'user'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admins', 'admin'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B2BB0)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: const Color(0xFF7B2BB0),
                    child: filteredUsers.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No users found',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
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
                              final isBanned = data['is_banned'] as bool? ?? false;
                              final banReason = data['ban_reason'] as String?;
                              return _buildUserCard(user, isBanned, banReason);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterRole == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterRole = value);
      },
      selectedColor: const Color(0xFF7B2BB0).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF7B2BB0),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF7B2BB0) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserCard(AppUser user, bool isBanned, String? banReason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.2),
                child: Text(
                  _userInitial(user),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _getRoleColor(user.role),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildRoleBadge(user.role),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),

          // Show ban reason if user is banned
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
                          'Ban Reason:',
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
                'Joined: ${user.createdAt != null ? _formatDate(user.createdAt!) : 'N/A'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                        'BANNED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, user),
                    itemBuilder: (context) => [
                      if (!isBanned)
                        const PopupMenuItem(
                          value: 'ban',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Ban User'),
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
                              Text('Unban User'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete User'),
                          ],
                        ),
                      ),
                    ],
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
    Color color;
    String label;

    switch (role) {
      case UserRole.admin:
        color = Colors.purple;
        label = 'ADMIN';
        break;
      case UserRole.user:
        color = Colors.blue;
        label = 'USER';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.user:
        return Colors.blue;
    }
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
          const SnackBar(content: Text('User banned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          const SnackBar(content: Text('User unbanned successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          const SnackBar(content: Text('User deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _showBanDialog() async {
    String? reason;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Reason for ban...'),
          onChanged: (value) => reason = value,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reason),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(AppUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
