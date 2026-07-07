import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/news_post.dart';
import '../../models/post_comment.dart';
import '../../services/news_service.dart';
import '../../services/supabase_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';

class PostDetailPage extends StatefulWidget {
  final NewsPost post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final NewsService _newsService = NewsService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  late final String currentUserId;
  bool _commentAnonymously = false; // Anonymous comment toggle
  bool _hasChanges = false;
  bool _isLikeUpdating = false;
  bool? _optimisticIsLiked;
  int? _optimisticLikeCount;
  int _pendingCommentDelta = 0;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    currentUserId = SupabaseService.instance.currentUser!.id;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  /// Load user avatar from Supabase
  Future<Map<String, dynamic>> _loadUserAvatar() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user == null) return {'avatarUrl': null, 'displayName': 'User'};

      final userData = await SupabaseService.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userData == null) return {'avatarUrl': null, 'displayName': 'User'};

      final avatarUrl = userData['avatar_url'];
      final displayName = userData['full_name'] ?? 'User';

      return {'avatarUrl': avatarUrl, 'displayName': displayName};
    } catch (e) {
      return {'avatarUrl': null, 'displayName': 'User'};
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final content = _commentController.text.trim();
    _commentController.clear();
    setState(() {
      _pendingCommentDelta += 1;
    });

    try {
      final user = SupabaseService.instance.currentUser!;

      // Determine user info based on anonymous toggle
      String userName;
      String? userAvatarUrl;

      if (_commentAnonymously) {
        userName = 'Anonymous';
        userAvatarUrl = null;
      } else {
        final userData = await SupabaseService.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        userName = userData?['full_name'] ?? 'User';
        userAvatarUrl = userData?['avatar_url'];
      }

      final comment = PostComment(
        commentId: '',
        postId: widget.post.postId,
        userId: user.id, // Keep real ID for moderation
        isAnonymous: _commentAnonymously,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        parentCommentId: _replyingToCommentId,
        content: content,
      );

      await _newsService.addComment(comment);

      if (!mounted) return;

      _hasChanges = true;
      _replyingToCommentId = null;
      _replyingToUserName = null;
      setState(() {});

      // Hide keyboard
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        _commentController.text = content;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.errorPostingComment}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingCommentDelta =
              _pendingCommentDelta > 0 ? _pendingCommentDelta - 1 : 0;
        });
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final l10n = context.l10n;

    if (difference.inSeconds < 60) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(context.l10n.postDetail, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primaryLight,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: Column(
        children: [
          // Post content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post card
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  widget.post.authorName == 'Anonymous'
                                  ? Colors.grey.shade300
                                  : AppColors.primaryLight.withValues(alpha: 0.2),
                              backgroundImage:
                                  widget.post.authorName != 'Anonymous' &&
                                          widget.post.authorAvatarUrl != null &&
                                          widget.post.authorAvatarUrl!.isNotEmpty
                                      ? (_isBase64(widget.post.authorAvatarUrl!)
                                              ? MemoryImage(
                                                  base64Decode(
                                                    widget.post.authorAvatarUrl!,
                                                  ),
                                                )
                                              : NetworkImage(
                                                  widget.post.authorAvatarUrl!,
                                                ))
                                          as ImageProvider
                                      : null,
                              child: widget.post.authorName == 'Anonymous'
                                  ? Icon(
                                      Icons.visibility_off,
                                      size: 20,
                                      color: Colors.grey.shade700,
                                    )
                                  : (widget.post.authorAvatarUrl == null || widget.post.authorAvatarUrl!.isEmpty
                                        ? Text(
                                            widget.post.authorName[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.primaryLight,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
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
                                      Text(
                                        widget.post.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),

                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(widget.post.createdAt),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(
                                  widget.post.category,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                categoryDisplayName(widget.post.category, context.l10n),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryColor(
                                    widget.post.category,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content
                        Text(
                          widget.post.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),

                        // Image
                        if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.post.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Actions
                        Row(
                          children: [
                            // Like button
                            StreamBuilder<NewsPost?>(
                              stream: _newsService.streamPosts().map((posts) {
                                return posts.firstWhere(
                                  (p) => p.postId == widget.post.postId,
                                  orElse: () => widget.post,
                                );
                              }),
                              builder: (context, snapshot) {
                                final post = snapshot.data ?? widget.post;
                                _syncLikeOverrideIfServerCaughtUp(post);
                                final isLiked = _optimisticIsLiked ??
                                    post.isLikedBy(currentUserId);
                                final likeCount =
                                    _optimisticLikeCount ?? post.likeCount;

                                return InkWell(
                                  onTap: () async {
                                    if (_isLikeUpdating) return;

                                    final previousLiked =
                                        _optimisticIsLiked ??
                                        post.isLikedBy(currentUserId);
                                    final previousCount =
                                        _optimisticLikeCount ?? post.likeCount;
                                    final nextLiked = !previousLiked;
                                    final nextCount = nextLiked
                                        ? previousCount + 1
                                        : previousCount - 1;

                                    setState(() {
                                      _isLikeUpdating = true;
                                      _optimisticIsLiked = nextLiked;
                                      _optimisticLikeCount =
                                          nextCount < 0 ? 0 : nextCount;
                                    });

                                    try {
                                      await _newsService.toggleLike(
                                        widget.post.postId,
                                        currentUserId,
                                      );
                                      if (mounted) {
                                        _hasChanges = true;
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        setState(() {
                                          _optimisticIsLiked = previousLiked;
                                          _optimisticLikeCount = previousCount;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${context.l10n.likeFailed}: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLikeUpdating = false;
                                        });
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.red
                                              : Colors.grey.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            // Comment count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  StreamBuilder<List<PostComment>>(
                                    stream: _newsService.streamComments(
                                      widget.post.postId,
                                    ),
                                    builder: (context, snapshot) {
                                      final count =
                                          (snapshot.data?.length ??
                                              widget.post.commentCount) +
                                          _pendingCommentDelta;
                                      return Text(
                                        '${count < 0 ? 0 : count}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Comments section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.comments,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<List<PostComment>>(
                          stream: _newsService.streamComments(
                            widget.post.postId,
                          ),
                          builder: (context, snapshot) {
                            // Show loading only on first load
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            // Handle error
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Text(
                                    context.l10n.errorLoadingComments,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final comments = snapshot.data ?? [];

                            if (comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 48,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        context.l10n.noCommentsYet,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return _buildCommentsTree(comments);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comment input
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToCommentId != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${context.l10n.comments} · ${_replyingToUserName ?? ''}',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              setState(() {
                                _replyingToCommentId = null;
                                _replyingToUserName = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _loadUserAvatar(),
                          builder: (context, snapshot) {
                            final avatarUrl = snapshot.data?['avatarUrl'] as String?;
                            final displayName = snapshot.data?['displayName'] as String?;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _commentAnonymously = !_commentAnonymously;
                                });
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: _commentAnonymously
                                    ? Colors.grey.shade300
                                    : AppColors.primaryLight.withValues(alpha: 0.2),
                                backgroundImage: !_commentAnonymously &&
                                        avatarUrl != null &&
                                        avatarUrl.isNotEmpty
                                    ? (_isBase64(avatarUrl)
                                          ? MemoryImage(base64Decode(avatarUrl))
                                          : NetworkImage(avatarUrl)) as ImageProvider
                                    : null,
                                child: _commentAnonymously
                                    ? Icon(
                                        Icons.visibility_off,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      )
                                    : (avatarUrl == null || avatarUrl.isEmpty
                                          ? Text(
                                              (displayName ?? 'U')[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: AppColors.primaryLight,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            )
                                          : null),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _loadUserAvatar(),
                          builder: (context, userSnapshot) {
                            final l10n = context.l10n;
                            return Container(
                              constraints: const BoxConstraints(maxHeight: 100),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocusNode,
                                decoration: InputDecoration(
                                  hintText: _replyingToCommentId != null
                                      ? (_commentAnonymously
                                            ? l10n.anonymousComment
                                            : l10n.writeComment)
                                      : _commentAnonymously
                                          ? l10n.anonymousComment
                                          : '${l10n.writeComment} ${l10n.anonymousComment}',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.primaryLight,
                          size: 24,
                        ),
                        onPressed: _submitComment,
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    final isReply = comment.parentCommentId != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isReply)
          Container(
            width: 2,
            height: 44,
            margin: const EdgeInsets.only(right: 10, top: 4),
            color: Colors.grey.shade300,
          ),
        CircleAvatar(
          radius: 18,
            backgroundColor: comment.userName == 'Anonymous'
              ? Colors.grey.shade300
              : AppColors.primaryLight.withValues(alpha: 0.2),
          backgroundImage:
              comment.userName != 'Anonymous' && comment.userAvatarUrl != null && comment.userAvatarUrl!.isNotEmpty
              ? (_isBase64(comment.userAvatarUrl!)
                        ? MemoryImage(base64Decode(comment.userAvatarUrl!))
                        : NetworkImage(comment.userAvatarUrl!))
                    as ImageProvider
              : null,
          child: comment.userName == 'Anonymous'
              ? Icon(
                  Icons.visibility_off,
                  size: 18,
                  color: Colors.grey.shade700,
                )
              : (comment.userAvatarUrl == null || comment.userAvatarUrl!.isEmpty
                    ? Text(
                        comment.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (comment.userRole == 'admin') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(comment.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _replyingToCommentId = comment.commentId;
                    _replyingToUserName = comment.userName;
                  });
                  _commentFocusNode.requestFocus();
                },
                child: Text(
                  context.l10n.submit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTree(List<PostComment> comments) {
    final commentsById = {for (final c in comments) c.commentId: c};
    final childrenMap = <String, List<PostComment>>{};
    final roots = <PostComment>[];

    for (final comment in comments) {
      final parentId = comment.parentCommentId;
      if (parentId == null || parentId.isEmpty || !commentsById.containsKey(parentId)) {
        roots.add(comment);
      } else {
        childrenMap.putIfAbsent(parentId, () => []).add(comment);
      }
    }

    List<Widget> buildNode(PostComment node, int depth) {
      final childComments = childrenMap[node.commentId] ?? const <PostComment>[];
      final widgets = <Widget>[
        Padding(
          padding: EdgeInsets.only(left: depth * 20.0),
          child: _buildCommentItem(node),
        ),
      ];

      for (final child in childComments) {
        widgets.add(const SizedBox(height: 12));
        widgets.addAll(buildNode(child, depth + 1));
      }

      return widgets;
    }

    final allWidgets = <Widget>[];
    for (var i = 0; i < roots.length; i++) {
      allWidgets.addAll(buildNode(roots[i], 0));
      if (i < roots.length - 1) {
        allWidgets.add(const Divider(height: 24));
      }
    }

    return Column(
      children: allWidgets,
    );
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.mentalHealth:
        return Colors.blue;
      case PostCategory.meditation:
        return Colors.purple;
      case PostCategory.wellness:
        return Colors.green;
      case PostCategory.tips:
        return Colors.orange;
      case PostCategory.community:
        return Colors.pink;
      case PostCategory.news:
        return Colors.teal;
    }
  }

  /// Check if string is Base64 encoded
  bool _isBase64(String str) {
    if (str.isEmpty) return false;
    // Base64 strings don't start with http/https
    if (str.startsWith('http://') || str.startsWith('https://')) {
      return false;
    }
    // Try to decode to verify it's valid Base64
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _syncLikeOverrideIfServerCaughtUp(NewsPost serverPost) {
    if (_optimisticIsLiked == null && _optimisticLikeCount == null) return;

    final serverLiked = serverPost.isLikedBy(currentUserId);
    final serverCount = serverPost.likeCount;

    if (_optimisticIsLiked == serverLiked && _optimisticLikeCount == serverCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _optimisticIsLiked = null;
          _optimisticLikeCount = null;
        });
      });
    }
  }
}
