enum PostCategory {
  mentalHealth, // Sức khỏe tâm thần
  meditation, // Thiền & Mindfulness
  wellness, // Sức khỏe tổng quát
  tips, // Mẹo & Lời khuyên
  community, // Cộng đồng
  news, // Tin tức
}

/// Returns the localized display name for a post category.
String categoryDisplayName(PostCategory category, dynamic l10n) {
  switch (category) {
    case PostCategory.mentalHealth:
      return l10n.catMentalHealth;
    case PostCategory.meditation:
      return l10n.catMeditation;
    case PostCategory.wellness:
      return l10n.catWellness;
    case PostCategory.tips:
      return l10n.catTips;
    case PostCategory.community:
      return l10n.catCommunity;
    case PostCategory.news:
      return l10n.catNews;
  }
}

class NewsPost {
  final String postId;
  final String authorId;
  final bool isAnonymous;
  final String authorName;
  final String? authorAvatarUrl;
  final String authorRole; // 'user', 'admin'

  final String title;
  final String content;
  final String? imageUrl;
  final PostCategory category;

  final List<String> likedBy; // List of user IDs who liked
  final int commentCount;

  final DateTime createdAt;
  final DateTime? updatedAt;

  NewsPost({
    required this.postId,
    required this.authorId,
    this.isAnonymous = false,
    required this.authorName,
    this.authorAvatarUrl,
    required this.authorRole,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    List<String>? likedBy,
    this.commentCount = 0,
    DateTime? createdAt,
    this.updatedAt,
  }) : likedBy = likedBy ?? [],
       createdAt = createdAt ?? DateTime.now();

  // Helper methods
  int get likeCount => likedBy.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

  // Supabase conversion
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'author_id': authorId.isEmpty ? null : authorId,
      'is_anonymous': isAnonymous,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'category': category.name,
      'likes_count': likedBy.length,
      'comment_count': commentCount,
      'created_at': createdAt.toIso8601String(),
    };
    
    if (postId.isNotEmpty) {
      map['id'] = postId;
    }
    
    if (updatedAt != null) {
      map['updated_at'] = updatedAt!.toIso8601String();
    }
    
    return map;
  }

  factory NewsPost.fromMap(Map<String, dynamic> data) {
    // Check if author data is joined
    final isAnonymous = data['is_anonymous'] == true || data['author_id'] == null;
    final users = data['users'] as Map<String, dynamic>?;
    final authorName = isAnonymous ? 'Anonymous' : (users?['full_name'] ?? 'Unknown');
    final authorAvatarUrl = isAnonymous ? null : users?['avatar_url'];
    final authorRole = isAnonymous ? 'user' : (users?['role'] ?? 'user');
    
    // Parse likedBy if we join with post_likes
    List<String> likedByList = [];
    if (data['post_likes'] != null) {
      likedByList = (data['post_likes'] as List)
          .map((e) => e['user_id'].toString())
          .toList();
    }

    return NewsPost(
      postId: data['id'] ?? '',
      authorId: data['author_id']?.toString() ?? '',
      isAnonymous: isAnonymous,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorRole: authorRole,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['image_url'],
      category: PostCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => PostCategory.community,
      ),
      likedBy: likedByList,
      commentCount: data['comment_count'] ?? 0,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']).toLocal() 
          : DateTime.now(),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at']).toLocal() 
          : null,
    );
  }

  NewsPost copyWith({
    String? postId,
    String? authorId,
    bool? isAnonymous,
    String? authorName,
    String? authorAvatarUrl,
    String? authorRole,
    String? title,
    String? content,
    String? imageUrl,
    PostCategory? category,
    List<String>? likedBy,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NewsPost(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorRole: authorRole ?? this.authorRole,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
