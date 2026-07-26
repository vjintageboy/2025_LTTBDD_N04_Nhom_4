import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/meditation.dart';
import '../models/streak.dart';
import '../models/mood_entry.dart';
import '../core/utils/stream_utils.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  factory SupabaseService() => instance;
  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  SupabaseClient get client => _supabase;
  User? get currentUser => _supabase.auth.currentUser;

  // ==========================================
  // USERS (bảng `users` thay vì `profiles`)
  // ==========================================

  /// Tạo hoặc cập nhật user trong bảng `users`
  Future<void> createUserProfile({
    required String id,
    required String email,
    required String fullName,
  }) async {
    try {
      // Intentionally does NOT write `role`. This upsert runs on every sign-in
      // via AuthProvider._ensureProfile; writing role here would reset an
      // existing admin back to 'user'. New rows fall back to the column
      // default ('user').
      await _supabase.from('users').upsert({
        'id': id,
        'email': email,
        'full_name': fullName,
      });
    } catch (e) {
      debugPrint('⚠️ createUserProfile failed: $e');
      rethrow;
    }
  }

  /// Lấy thông tin user từ bảng `users`
  Future<AppUser?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return AppUser.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Lấy role của user
  Future<String> getUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();
      return response['role'] ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  // --- Mood Entries ---
  Future<void> createMoodEntry(MoodEntry entry) async {
    final data = <String, dynamic>{
      'user_id': entry.userId,
      'mood_score': entry.moodLevel,
      'note': entry.note,
      'emotion_factors': entry.emotionFactors,
      'tags': entry.tags,
    };
    // Only sent when a photo is attached, so mood logging keeps working even
    // before the image_url column migration is applied.
    if (entry.imageUrl != null) data['image_url'] = entry.imageUrl;
    await _supabase.from('mood_entries').insert(data);

    // ✅ Tự động tính lại streak sau mỗi lần log mood
    await recalculateStreak(entry.userId);
  }

  Stream<List<MoodEntry>> streamMoodEntries(String userId) {
    return resilientStream(() => _supabase
        .from('mood_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((map) => MoodEntry.fromMap(map)).toList()));
  }

  Future<List<MoodEntry>> getMoodEntries(String userId) async {
    final response = await _supabase
        .from('mood_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((map) => MoodEntry.fromMap(map)).toList();
  }

  Future<void> deleteMoodEntry(String id) async {
    await _supabase.from('mood_entries').delete().eq('id', id);
  }

  Future<List<MoodEntry>> getMoodEntriesForPeriod({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _supabase
        .from('mood_entries')
        .select()
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: false);

    return (response as List).map((map) => MoodEntry.fromMap(map)).toList();
  }

  Future<void> updateMoodEntry(String id, Map<String, dynamic> data) async {
    final supabaseData = <String, dynamic>{};
    if (data.containsKey('moodLevel')) {
      supabaseData['mood_score'] = data['moodLevel'];
    }
    if (data.containsKey('note')) supabaseData['note'] = data['note'];
    if (data.containsKey('emotionFactors')) {
      supabaseData['emotion_factors'] = data['emotionFactors'];
    }
    if (data.containsKey('tags')) supabaseData['tags'] = data['tags'];

    await _supabase.from('mood_entries').update(supabaseData).eq('id', id);
  }

  /// Kiểm tra user có bị ban không (cột `is_banned` trên bảng `users`).
  Future<bool> isUserBanned(String userId) async {
    try {
      final row = await _supabase
          .from('users')
          .select('is_banned')
          .eq('id', userId)
          .maybeSingle();
      return row?['is_banned'] == true;
    } catch (e) {
      // ponytail: fail-open — lỗi truy vấn không khóa nhầm người dùng hợp lệ;
      // ban chỉ là kiểm duyệt, không phải cổng bảo mật cốt lõi.
      debugPrint('isUserBanned query failed: $e');
      return false;
    }
  }

  /// Lấy danh sách tất cả users (admin only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((data) => AppUser.fromMap(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Cập nhật thông tin user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _supabase.from('users').update(data).eq('id', userId);
  }

  // ==========================================
  // MOOD ENTRIES (bảng `mood_entries`)
  // ==========================================

  /// Ghi nhật ký cảm xúc
  Future<void> addMoodEntry({
    required String userId,
    required int moodScore,
    String? note,
  }) async {
    await _supabase.from('mood_entries').insert({
      'user_id': userId,
      'mood_score': moodScore,
      'note': note,
    });
  }

  /// Lấy lịch sử cảm xúc của user
  Future<List<Map<String, dynamic>>> getMoodHistory(String userId) async {
    try {
      final response = await _supabase
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // POSTS (bảng `posts`, thay vì `news_posts`)
  // ==========================================

  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select('*, users!author_id(full_name, avatar_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> createPost({
    required String authorId,
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    await _supabase.from('posts').insert({
      'author_id': authorId,
      'title': title,
      'content': content,
      'image_url': imageUrl,
    });
  }

  Future<void> toggleLike(String postId, int currentLikes, bool isLiked) async {
    await _supabase
        .from('posts')
        .update({'likes_count': isLiked ? currentLikes - 1 : currentLikes + 1})
        .eq('id', postId);
  }

  // ==========================================
  // POST COMMENTS (bảng `post_comments`)
  // ==========================================

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('*, users!user_id(full_name, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    await _supabase.from('post_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  // ==========================================
  // MEDITATIONS (bảng `meditations`)
  // ==========================================

  Future<List<Map<String, dynamic>>> getMeditations({String? category}) async {
    try {
      var query = _supabase.from('meditations').select();
      if (category != null) {
        query = query.eq('category', category);
      }
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Stream meditations (Realtime)
  Stream<List<Meditation>> streamMeditations() {
    return resilientStream(() => _supabase
        .from('meditations')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((map) => Meditation.fromMap(map)).toList()));
  }

  /// Get meditations (Future-based for robustness)
  Future<List<Meditation>> getFeaturedMeditations({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('meditations')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((m) => Meditation.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error fetching featured meditations: $e');
      return [];
    }
  }

  // ==========================================
  // STREAKS (Lấy từ bảng `users`)
  // ==========================================

  Future<Streak?> getStreak(String userId) async {
    try {
      // Đọc toàn bộ mood entries rồi tính streak client-side
      // → không cần bảng phụ, không cần trigger DB
      final entries = await getMoodEntries(userId);
      return Streak.fromMoodEntries(userId: userId, entries: entries);
    } catch (e) {
      debugPrint('getStreak error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Tính lại streak từ bảng mood_entries và lưu kết quả vào users.streak_count.
  /// Không cần bảng phụ nào thêm.
  Future<void> recalculateStreak(String userId) async {
    try {
      final entries = await getMoodEntries(userId);
      final streak = Streak.fromMoodEntries(userId: userId, entries: entries);

      // Ghi streak_count về bảng users (cột này đã tồn tại)
      await _supabase
          .from('users')
          .update({'streak_count': streak.currentStreak})
          .eq('id', userId);

      debugPrint(
        '🔥 Streak recalculated for $userId: '
        'current=${streak.currentStreak}, longest=${streak.longestStreak}',
      );
    } catch (e) {
      debugPrint('recalculateStreak error: $e');
    }
  }

  Stream<Streak?> streamStreak(String userId) {
    return resilientStream(() => _supabase
        .from('mood_entries')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) {
          final entries = rows.map((m) => MoodEntry.fromMap(m)).toList();
          return Streak.fromMoodEntries(userId: userId, entries: entries);
        }));
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
}
