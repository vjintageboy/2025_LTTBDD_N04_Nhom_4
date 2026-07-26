import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  bool _commentAnonymously = false;
  bool _hasChanges = false;
  bool _isLikeUpdating = false;
  bool? _optimisticIsLiked;
  int? _optimisticLikeCount;
  int _pendingCommentDelta = 0;
  String? _replyingToCommentId;
  String? _replyingToUserName;

  static const Color _kBg = Color(0xFFDBFCDF);
  static const Color _kCardBg = Color(0xFFFFFFFF);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x0F0B361D),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

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
      return {
        'avatarUrl': userData['avatar_url'],
        'displayName': userData['full_name'] ?? 'User',
      };
    } catch (e) {
      return {'avatarUrl': null, 'displayName': 'User'};
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final content = _commentController.text.trim();
    _commentController.clear();
    setState(() => _pendingCommentDelta += 1);

    try {
      final user = SupabaseService.instance.currentUser!;
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
        userId: user.id,
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
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        _commentController.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.errorPostingComment}: $e'),
            backgroundColor: AppColors.osError,
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
    final difference = DateTime.now().difference(dateTime);
    final l10n = context.l10n;
    if (difference.inSeconds < 60) return l10n.justNow;
    if (difference.inMinutes < 60) return l10n.minutesAgo(difference.inMinutes);
    if (difference.inHours < 24) return l10n.hoursAgo(difference.inHours);
    if (difference.inDays < 7) return l10n.daysAgo(difference.inDays);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(IconsaxPlusLinear.arrow_left_2),
            color: AppColors.osOnSurface,
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: Text(
            context.l10n.postDetail,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.osOnSurface,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostCard(),
                    const SizedBox(height: 16),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorRow(),
          const SizedBox(height: 20),
          Text(
            widget.post.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.osOnSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.post.content,
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppColors.osOnSurfaceVariant,
              height: 1.6,
            ),
          ),
          if (widget.post.imageUrl != null &&
              widget.post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _isBase64(widget.post.imageUrl!)
                  ? Image.memory(
                      base64Decode(widget.post.imageUrl!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      widget.post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ],
          const SizedBox(height: 20),
          _buildActionsRow(),
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    final post = widget.post;
    final isAnonymous = post.authorName == 'Anonymous';

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: isAnonymous
              ? AppColors.osSurfaceContainer
              : AppColors.osPrimaryContainer,
          backgroundImage: !isAnonymous &&
                  post.authorAvatarUrl != null &&
                  post.authorAvatarUrl!.isNotEmpty
              ? (_isBase64(post.authorAvatarUrl!)
                  ? MemoryImage(base64Decode(post.authorAvatarUrl!))
                  : NetworkImage(post.authorAvatarUrl!)) as ImageProvider
              : null,
          child: isAnonymous
              ? Icon(IconsaxPlusLinear.eye_slash,
                  size: 20, color: AppColors.osOnSurfaceVariant)
              : (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                  ? Text(
                      post.authorName[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.osOnPrimaryContainer,
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
                post.authorName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.osOnSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(post.createdAt),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _getCategoryColor(post.category).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            categoryDisplayName(post.category, context.l10n),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getCategoryColor(post.category),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
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
            final isLiked =
                _optimisticIsLiked ?? post.isLikedBy(currentUserId);
            final likeCount = _optimisticLikeCount ?? post.likeCount;

            return InkWell(
              onTap: () async {
                if (_isLikeUpdating) return;
                final prevLiked =
                    _optimisticIsLiked ?? post.isLikedBy(currentUserId);
                final prevCount = _optimisticLikeCount ?? post.likeCount;
                final nextLiked = !prevLiked;
                final nextCount =
                    nextLiked ? prevCount + 1 : prevCount - 1;

                setState(() {
                  _isLikeUpdating = true;
                  _optimisticIsLiked = nextLiked;
                  _optimisticLikeCount = nextCount < 0 ? 0 : nextCount;
                });

                try {
                  await _newsService.toggleLike(
                      widget.post.postId, currentUserId);
                  if (mounted) _hasChanges = true;
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _optimisticIsLiked = prevLiked;
                      _optimisticLikeCount = prevCount;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${context.l10n.likeFailed}: $e'),
                        backgroundColor: AppColors.osError,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLikeUpdating = false);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isLiked
                      ? AppColors.osError.withValues(alpha: 0.08)
                      : AppColors.osSurfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? IconsaxPlusBold.heart : IconsaxPlusLinear.heart,
                      color:
                          isLiked ? AppColors.osError : AppColors.osOnSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$likeCount',
                      style: GoogleFonts.manrope(
                        color: AppColors.osOnSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.osSurfaceContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconsaxPlusLinear.message,
                  color: AppColors.osOnSurfaceVariant, size: 20),
              const SizedBox(width: 6),
              StreamBuilder<List<PostComment>>(
                stream: _newsService.streamComments(widget.post.postId),
                builder: (context, snapshot) {
                  final count = (snapshot.data?.length ??
                          widget.post.commentCount) +
                      _pendingCommentDelta;
                  return Text(
                    '${count < 0 ? 0 : count}',
                    style: GoogleFonts.manrope(
                      color: AppColors.osOnSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.comments,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.osOnSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<PostComment>>(
            stream: _newsService.streamComments(widget.post.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.osPrimary),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      context.l10n.errorLoadingComments,
                      style: GoogleFonts.manrope(
                        color: AppColors.osOnSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(IconsaxPlusLinear.message,
                            size: 48, color: AppColors.osOutlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.noCommentsYet,
                          style: GoogleFonts.manrope(
                            color: AppColors.osOnSurfaceVariant,
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
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          boxShadow: [
            BoxShadow(
              color: AppColors.osOnSurface.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyingToCommentId != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.osSurfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.arrowBendUpLeft,
                        size: 16, color: AppColors.osPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${context.l10n.comments} · ${_replyingToUserName ?? ''}',
                        style: GoogleFonts.manrope(
                          color: AppColors.osOnSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(IconsaxPlusLinear.close_circle,
                          size: 18, color: AppColors.osOnSurfaceVariant),
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
                  padding: const EdgeInsets.only(bottom: 6),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _loadUserAvatar(),
                    builder: (context, snapshot) {
                      final avatarUrl =
                          snapshot.data?['avatarUrl'] as String?;
                      final displayName =
                          snapshot.data?['displayName'] as String?;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _commentAnonymously = !_commentAnonymously),
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: _commentAnonymously
                              ? AppColors.osSurfaceContainerHighest
                              : AppColors.osPrimaryContainer,
                          backgroundImage: !_commentAnonymously &&
                                  avatarUrl != null &&
                                  avatarUrl.isNotEmpty
                              ? (_isBase64(avatarUrl)
                                  ? MemoryImage(base64Decode(avatarUrl))
                                  : NetworkImage(avatarUrl)) as ImageProvider
                              : null,
                          child: _commentAnonymously
                              ? Icon(IconsaxPlusLinear.eye_slash,
                                  size: 16, color: AppColors.osOnSurfaceVariant)
                              : (avatarUrl == null || avatarUrl.isEmpty
                                  ? Text(
                                      (displayName ?? 'U')[0].toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.osOnPrimaryContainer,
                                      ),
                                    )
                                  : null),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: AppColors.osSurfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.osOnSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: _replyingToCommentId != null
                            ? (_commentAnonymously
                                ? context.l10n.anonymousComment
                                : context.l10n.writeComment)
                            : _commentAnonymously
                                ? context.l10n.anonymousComment
                                : '${context.l10n.writeComment}',
                        hintStyle: GoogleFonts.manrope(
                          color: AppColors.osOnSurfaceVariant,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.osPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(IconsaxPlusBold.send_2,
                        color: Colors.white, size: 20),
                    onPressed: _submitComment,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    final isReply = comment.parentCommentId != null;
    final isAnon = comment.userName == 'Anonymous';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isReply)
          Container(
            width: 2,
            height: 44,
            margin: const EdgeInsets.only(right: 10, top: 4),
            color: AppColors.osOutlineVariant,
          ),
        CircleAvatar(
          radius: 16,
          backgroundColor: isAnon
              ? AppColors.osSurfaceContainer
              : AppColors.osPrimaryContainer,
          backgroundImage: !isAnon &&
                  comment.userAvatarUrl != null &&
                  comment.userAvatarUrl!.isNotEmpty
              ? (_isBase64(comment.userAvatarUrl!)
                  ? MemoryImage(base64Decode(comment.userAvatarUrl!))
                  : NetworkImage(comment.userAvatarUrl!)) as ImageProvider
              : null,
          child: isAnon
              ? Icon(IconsaxPlusLinear.eye_slash,
                  size: 16, color: AppColors.osOnSurfaceVariant)
              : (comment.userAvatarUrl == null || comment.userAvatarUrl!.isEmpty
                  ? Text(
                      comment.userName[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.osOnPrimaryContainer,
                      ),
                    )
                  : null),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.osOnSurface,
                    ),
                  ),
                  if (comment.userRole == 'admin') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.osPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Admin',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.osPrimary,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(comment.createdAt),
                    style: GoogleFonts.manrope(
                        fontSize: 11, color: AppColors.osOnSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.osOnSurface,
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
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.osPrimary,
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
      if (parentId == null ||
          parentId.isEmpty ||
          !commentsById.containsKey(parentId)) {
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
        allWidgets.add(const Divider(height: 24, color: AppColors.osSurfaceContainer));
      }
    }
    return Column(children: allWidgets);
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.mentalHealth:
        return const Color(0xFF0077B6); // blue
      case PostCategory.meditation:
        return const Color(0xFF6C3FBF); // purple
      case PostCategory.wellness:
        return const Color(0xFF2E7D32); // green
      case PostCategory.tips:
        return const Color(0xFFD97706); // amber
      case PostCategory.community:
        return const Color(0xFFC62828); // red
      case PostCategory.news:
        return const Color(0xFF00838F); // teal
    }
  }

  bool _isBase64(String str) {
    if (str.isEmpty) return false;
    if (str.startsWith('http://') || str.startsWith('https://')) return false;
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
