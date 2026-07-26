import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/news_post.dart';
import '../models/post_comment.dart';
import '../core/utils/stream_utils.dart';

/// Notifying a post's author on a like or comment is a database trigger
/// (`notify_post_author`), not client code — users have no INSERT rights on
/// `notifications`, so writing them from here was silently denied by RLS.
class NewsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== POSTS ====================

  /// Stream all posts, ordered by createdAt descending
  Stream<List<NewsPost>> streamPosts({PostCategory? category}) {
    return resilientStream(() {
      final query = category != null
          ? _supabase
              .from('posts')
              .stream(primaryKey: ['id'])
              .eq('category', category.name)
              .order('created_at', ascending: false)
          : _supabase
              .from('posts')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false);

      return query.asyncMap((postList) async {
        // Fetch users and likes for these posts
        final userIds = postList
            .map((p) => p['author_id'])
            .where((id) => id != null)
            .map((id) => id.toString())
            .toSet()
            .toList();
        final postIds = postList.map((p) => p['id'] as String).toList();

        final usersData = userIds.isEmpty ? [] : await _supabase
            .from('users')
            .select('id, full_name, avatar_url, role')
            .inFilter('id', userIds);

        final likesData = postIds.isEmpty ? [] : await _supabase
            .from('post_likes')
            .select('post_id, user_id')
            .inFilter('post_id', postIds);

        final usersMap = {
          for (var u in usersData) u['id']: u
        };

        final likesMap = <String, List<Map<String, dynamic>>>{};
        for (var like in likesData) {
          final pid = like['post_id'] as String;
          likesMap[pid] ??= [];
          likesMap[pid]!.add(like);
        }

        return postList.map((post) {
          final enrichedPost = Map<String, dynamic>.from(post);
          enrichedPost['users'] = usersMap[post['author_id']];
          enrichedPost['post_likes'] = likesMap[post['id']] ?? [];
          return NewsPost.fromMap(enrichedPost);
        }).toList();
      });
    });
  }

  /// Get single post by ID
  Future<NewsPost?> getPost(String postId) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*, users(full_name, avatar_url, role), post_likes(user_id)')
          .eq('id', postId)
          .maybeSingle();

      if (data != null) {
        return NewsPost.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post: $e');
      return null;
    }
  }

  /// Create new post
  Future<String?> createPost(NewsPost post) async {
    try {
      final response = await _supabase
          .from('posts')
          .insert(post.toMap())
          .select()
          .single();
      return response['id'] as String;
    } on PostgrestException catch (e) {
      // Backward compatibility: if DB doesn't have is_anonymous yet.
      if (e.message.toLowerCase().contains('is_anonymous') && post.isAnonymous) {
        final fallbackMap = post.toMap()..remove('is_anonymous');
        fallbackMap['author_id'] = null;
        final response = await _supabase
            .from('posts')
            .insert(fallbackMap)
            .select()
            .single();
        return response['id'] as String;
      }
      debugPrint('Error creating post: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error creating post: $e');
      rethrow;
    }
  }

  /// Update post
  Future<void> updatePost(NewsPost post) async {
    try {
      await _supabase
          .from('posts')
          .update({
            'title': post.title,
            'content': post.content,
            'image_url': post.imageUrl,
            'category': post.category.name,
            'is_anonymous': post.isAnonymous,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', post.postId);
    } on PostgrestException catch (e) {
      // Backward compatibility: if DB doesn't have is_anonymous yet.
      if (e.message.toLowerCase().contains('is_anonymous')) {
        await _supabase
            .from('posts')
            .update({
              'title': post.title,
              'content': post.content,
              'image_url': post.imageUrl,
              'category': post.category.name,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', post.postId);
        return;
      }
      debugPrint('Error updating post: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error updating post: $e');
      rethrow;
    }
  }

  /// Delete post (and its comments)
  Future<void> deletePost(String postId) async {
    try {
      // Supabase handles cascade deletes if configured, but to be safe we would do it here if not, 
      // however our constraints don't explicitly say ON DELETE CASCADE.
      // So we delete comments, likes, then post.
      await _supabase.from('post_comments').delete().eq('post_id', postId);
      await _supabase.from('post_likes').delete().eq('post_id', postId);
      await _supabase.from('posts').delete().eq('id', postId);
    } catch (e) {
      debugPrint('Error deleting post: $e');
      rethrow;
    }
  }

  // ==================== LIKES ====================

  /// Toggle like on a post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
            
        // Decrement likes_count
        /* Using rpc if available, otherwise just update post but since we don't have RPC definition, 
           we can select and update. BUT our query gets it. Wait, the count is maintained via 
           likes table so we just leave likes_count alone or manually update it if required by your DB. */
        final post = await _supabase.from('posts').select('likes_count').eq('id', postId).single();
        final currentCount = post['likes_count'] as int? ?? 0;
        await _supabase.from('posts').update({'likes_count': currentCount > 0 ? currentCount - 1 : 0}).eq('id', postId);
      } else {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        
        final post = await _supabase.from('posts').select('likes_count').eq('id', postId).single();
        final currentCount = post['likes_count'] as int? ?? 0;
        await _supabase.from('posts').update({'likes_count': currentCount + 1}).eq('id', postId);
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  // ==================== COMMENTS ====================

  /// Stream live comment count for a post (source of truth from post_comments)
  Stream<int> streamCommentCount(String postId) {
    return resilientStream(() => _supabase
        .from('post_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) => rows.length));
  }

  /// Stream comments for a post
  Stream<List<PostComment>> streamComments(String postId) {
    return resilientStream(() => _supabase
        .from('post_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .asyncMap((commentList) async {
          if (commentList.isEmpty) return [];

            final userIds = commentList
              .map((c) => c['user_id'])
              .where((id) => id != null)
              .map((id) => id.toString())
              .toSet()
              .toList();
              final usersData = userIds.isEmpty
                ? []
                : await _supabase
                  .from('users')
                  .select('id, full_name, avatar_url, role')
                  .inFilter('id', userIds);

          final usersMap = {
            for (var u in usersData) u['id']: u
          };

          return commentList.map((comment) {
            final enrichedComment = Map<String, dynamic>.from(comment);
            enrichedComment['users'] = usersMap[comment['user_id']];
            return PostComment.fromMap(enrichedComment);
          }).toList();
        }));
  }

  /// Add comment to post
  Future<void> addComment(PostComment comment) async {
    try {
      await _supabase.from('post_comments').insert({
        'post_id': comment.postId,
        'user_id': comment.userId.isEmpty ? null : comment.userId,
        'is_anonymous': comment.isAnonymous,
        'parent_comment_id': comment.parentCommentId,
        'content': comment.content,
      });

      // Increment comment count
      final post = await _supabase.from('posts').select('comment_count').eq('id', comment.postId).single();
      final currentCount = post['comment_count'] as int? ?? 0;
      await _supabase.from('posts').update({'comment_count': currentCount + 1}).eq('id', comment.postId);
    } on PostgrestException catch (e) {
      // Backward compatibility: if DB doesn't have is_anonymous yet.
      if (e.message.toLowerCase().contains('is_anonymous') && comment.isAnonymous) {
        await _supabase.from('post_comments').insert({
          'post_id': comment.postId,
          'user_id': null,
          'parent_comment_id': comment.parentCommentId,
          'content': comment.content,
        });

        final post = await _supabase
            .from('posts')
            .select('comment_count')
            .eq('id', comment.postId)
            .single();
        final currentCount = post['comment_count'] as int? ?? 0;
        await _supabase
            .from('posts')
            .update({'comment_count': currentCount + 1})
            .eq('id', comment.postId);
        return;
      }
      debugPrint('Error adding comment: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  /// Delete comment
  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _supabase.from('post_comments').delete().eq('id', commentId);

      // Decrement comment count
      final post = await _supabase.from('posts').select('comment_count').eq('id', postId).single();
      final currentCount = post['comment_count'] as int? ?? 0;
      if (currentCount > 0) {
        await _supabase.from('posts').update({'comment_count': currentCount - 1}).eq('id', postId);
      }
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  // ==================== UTILITY ====================

  /// Get user's posts
  Future<List<NewsPost>> getUserPosts(String userId) async {
    try {
      final data = await _supabase
          .from('posts')
          .select('*, users(full_name, avatar_url, role), post_likes(user_id)')
          .eq('author_id', userId)
          .order('created_at', ascending: false);

      return data.map((doc) => NewsPost.fromMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting user posts: $e');
      return [];
    }
  }
}

