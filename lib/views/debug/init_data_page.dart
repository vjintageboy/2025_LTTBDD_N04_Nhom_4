import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';

/// 🔧 Debug page để khởi tạo dữ liệu Firebase
/// Chỉ sử dụng trong development
class InitDataPage extends StatefulWidget {
  const InitDataPage({super.key});

  @override
  State<InitDataPage> createState() => _InitDataPageState();
}

class _InitDataPageState extends State<InitDataPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _initializeMeditations() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang tạo meditation data...';
    });

    try {
      await _firestoreService.initializeSampleData();
      
      setState(() {
        _statusMessage = '✅ Đã tạo 3 meditation mẫu thành công!\n\nKiểm tra trên Firebase Console:\nFirestore Database → meditations';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meditation data đã được tạo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      setState(() {
        _statusMessage = '❌ Bạn cần đăng nhập trước!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang tạo user profile...';
    });

    try {
      final profile = UserProfile(
        profileId: user.uid,
        userId: user.uid,
        fullName: user.displayName ?? 'User',
        goals: ['Giảm stress', 'Ngủ ngon hơn', 'Tăng tập trung'],
      );
      
      await _firestoreService.createUserProfile(profile);
      
      setState(() {
        _statusMessage = '✅ Đã tạo user profile thành công!\n\nUser ID: ${user.uid}\nTên: ${profile.fullName}';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ User profile đã được tạo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createUserStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      setState(() {
        _statusMessage = '❌ Bạn cần đăng nhập trước!';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang tạo streak...';
    });

    try {
      final streak = await _firestoreService.getOrCreateStreak(user.uid);
      
      setState(() {
        _statusMessage = '✅ Đã tạo streak thành công!\n\nCurrent: ${streak.currentStreak} days\nLongest: ${streak.longestStreak} days';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Lỗi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('🔧 Khởi tạo Database'),
        backgroundColor: const Color(0xFF7B2BB0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user != null
                          ? '✅ Đã đăng nhập\nEmail: ${user.email}\nUID: ${user.uid}'
                          : '❌ Chưa đăng nhập',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              const Text(
                'Hướng dẫn:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1️⃣ Nhấn "Khởi tạo Meditations" để tạo 3 meditation mẫu\n'
                '2️⃣ Nhấn "Tạo User Profile" để tạo profile cho tài khoản hiện tại\n'
                '3️⃣ Nhấn "Tạo Streak" để tạo streak tracking\n\n'
                '⚠️ Chỉ chạy mỗi nút 1 lần!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Button 1: Initialize Meditations
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _initializeMeditations,
                  icon: const Icon(Icons.spa),
                  label: const Text(
                    'Khởi tạo Meditations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button 2: Create User Profile
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || user == null ? null : _createUserProfile,
                  icon: const Icon(Icons.person),
                  label: const Text(
                    'Tạo User Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button 3: Create Streak
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading || user == null ? null : _createUserStreak,
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text(
                    'Tạo Streak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Status message
              if (_statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusMessage.startsWith('✅')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _statusMessage.startsWith('✅')
                          ? Colors.green
                          : Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: _statusMessage.startsWith('✅')
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      height: 1.5,
                    ),
                  ),
                ),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
