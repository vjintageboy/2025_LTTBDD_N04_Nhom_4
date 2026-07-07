import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/news_post.dart';
import '../../services/news_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

/// News Manager Page for Admin: manage all news posts (view, edit, delete, filter by author/category)
class NewsManagerPage extends StatefulWidget {
  const NewsManagerPage({super.key});

  @override
  State<NewsManagerPage> createState() => _NewsManagerPageState();
}

class _NewsManagerPageState extends State<NewsManagerPage> {
  final NewsService _newsService = NewsService();
  String _searchQuery = '';
  NewsPost? _selectedPost;

  // Build a consistent search card used by both narrow and wide layout
  Widget _buildSearchCard(bool isWide) {
    final borderRadius = BorderRadius.circular(12.0);
    final primary = AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        color: primary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(fontSize: 14, color: Colors.white),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    hintText: 'Search title or content',
                    hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: Icon(Icons.close, color: Colors.white70),
                  tooltip: 'Clear search',
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'News Manager',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostPage()),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          return isWide
              ? Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSearchCard(isWide),
                          Expanded(
                            child: StreamBuilder<List<NewsPost>>(
                              stream: _newsService.streamPosts(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                var posts = snapshot.data!;

                                // Apply search query if present
                                if (_searchQuery.isNotEmpty) {
                                  final q = _searchQuery.toLowerCase();
                                  posts = posts
                                      .where(
                                        (p) =>
                                            p.title.toLowerCase().contains(q) ||
                                            p.content.toLowerCase().contains(q),
                                      )
                                      .toList();
                                }

                                if (posts.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.article_outlined,
                                            size: 64,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No posts found',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Auto-select first post in wide view when none selected yet
                                if (isWide &&
                                    _selectedPost == null &&
                                    posts.isNotEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) {
                                      setState(
                                        () => _selectedPost = posts.first,
                                      );
                                    }
                                  });
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  itemCount: posts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) =>
                                      _buildPostCard(posts[index], isWide),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Right: detail preview
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Colors.grey.shade50,
                        child: _selectedPost == null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Select a post to preview',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: _buildDetailPane(_selectedPost!),
                              ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildSearchCard(false),
                    Expanded(
                      child: StreamBuilder<List<NewsPost>>(
                        stream: _newsService.streamPosts(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          var posts = snapshot.data!;

                          // Apply search query if present
                          if (_searchQuery.isNotEmpty) {
                            final q = _searchQuery.toLowerCase();
                            posts = posts
                                .where(
                                  (p) =>
                                      p.title.toLowerCase().contains(q) ||
                                      p.content.toLowerCase().contains(q),
                                )
                                .toList();
                          }

                          if (posts.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.article_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No posts found',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            itemCount: posts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) =>
                                _buildPostCard(posts[index], false),
                          );
                        },
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  String _shortDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _buildPostCard(NewsPost post, bool isWide) {
    final isSelected = _selectedPost?.postId == post.postId;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (isWide) {
            setState(() => _selectedPost = post);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: isSelected && isWide
              ? Border.all(color: AppColors.primaryLight, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: post.authorName == 'Anonymous'
                    ? Colors.grey.shade300
                  : AppColors.primaryLight.withValues(alpha: 0.12),
                backgroundImage:
                    post.authorName != 'Anonymous' &&
                        post.authorAvatarUrl != null &&
                        post.authorAvatarUrl!.isNotEmpty
                    ? (_isBase64(post.authorAvatarUrl!)
                              ? MemoryImage(base64Decode(post.authorAvatarUrl!))
                              : NetworkImage(post.authorAvatarUrl!))
                          as ImageProvider
                    : null,
                child: post.authorName == 'Anonymous'
                    ? Icon(
                        Icons.visibility_off,
                        size: 20,
                        color: Colors.grey.shade700,
                      )
                    : (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                          ? Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            )
                          : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleAction(value, post),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Left: author + date + category (wraps if narrow)
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                post.authorName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '•',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              Text(
                                _shortDate(post.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  categoryDisplayName(post.category, context.l10n),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Thumbnail if present
                        if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.imageUrl!,
                              width: 88,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 88,
                                    height: 64,
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // Small stats
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.likeCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.chat_bubble,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${post.commentCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPane(NewsPost post) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: post.authorName == 'Anonymous'
                    ? Colors.grey.shade300
                  : AppColors.primaryLight.withValues(alpha: 0.12),
                backgroundImage:
                    post.authorName != 'Anonymous' &&
                        post.authorAvatarUrl != null &&
                        post.authorAvatarUrl!.isNotEmpty
                    ? (_isBase64(post.authorAvatarUrl!)
                              ? MemoryImage(base64Decode(post.authorAvatarUrl!))
                              : NetworkImage(post.authorAvatarUrl!))
                          as ImageProvider
                    : null,
                child: post.authorName == 'Anonymous'
                    ? Icon(
                        Icons.visibility_off,
                        size: 20,
                        color: Colors.grey.shade700,
                      )
                    : (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                          ? Text(
                              post.authorName.isNotEmpty
                                  ? post.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            )
                          : null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${post.authorName} • ${_shortDate(post.createdAt)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            post.content,
            style: TextStyle(color: Colors.grey.shade800, height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _handleAction('edit', post),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _handleAction('delete', post),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade100),
                ),
              ),
              const Spacer(),
              Text(
                '${post.likeCount} ❤️  •  ${post.commentCount} comments',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Check if string is Base64 encoded
  bool _isBase64(String str) {
    if (str.isEmpty) return false;
    // Base64 strings typically don't start with http/https
    if (str.startsWith('http://') || str.startsWith('https://')) return false;
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _handleAction(String action, NewsPost post) async {
    switch (action) {
      case 'view':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
        );
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreatePostPage(postToEdit: post)),
        );
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _newsService.deletePost(post.postId);
          if (mounted) {
            // If the deleted post was selected in detail pane, clear it
            if (_selectedPost?.postId == post.postId) {
              setState(() => _selectedPost = null);
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Post deleted')));
          }
        }
        break;
    }
  }
}
