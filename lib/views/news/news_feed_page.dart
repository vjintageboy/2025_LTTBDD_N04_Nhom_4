import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/news_post.dart';
import '../../services/news_service.dart';
import '../../services/supabase_service.dart';
import '../../core/services/localization_service.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

enum SortBy {
  latest,
  hot,
  mostLiked,
  mostDiscussed,
}


class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({super.key});

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final NewsService _newsService = NewsService();
  final _sortButtonKey = GlobalKey();
  late final String currentUserId;
  Map<String, bool>? _optimisticLikeState;
  Map<String, int>? _optimisticLikeCount;
  Set<String>? _likeUpdatingPosts;

  PostCategory? _selectedCategory;
  SortBy _sortBy = SortBy.latest;

  @override
  void initState() {
    super.initState();
    currentUserId = SupabaseService.instance.currentUser!.id;
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
    return Scaffold(
      backgroundColor: _kSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Column(
        children: [
          // Spacer cho glass header (SafeArea top + 72px header)
          SizedBox(height: MediaQuery.of(context).padding.top + 72),
          _buildFilterBar(),
          Expanded(child: _buildPostFeed()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    final user = SupabaseService.instance.currentUser;
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: _kSurface.withValues(alpha: 0.80),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Avatar user hiện tại
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _kPrimaryContainer,
                        backgroundImage: (user?.userMetadata?['avatar_url'] as String?)?.isNotEmpty == true
                            ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                            : null,
                        child: (user?.userMetadata?['avatar_url'] as String?)?.isNotEmpty != true
                            ? Icon(Icons.person, size: 20, color: _kPrimary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        context.l10n.community,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.search, color: _kOnSurface),
                        onPressed: () {},
                        splashRadius: 22,
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: _kOnSurface),
                        onPressed: () {},
                        splashRadius: 22,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: _kOnSurface),
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreatePostPage(),
                            ),
                          );
                          if (changed == true && mounted) setState(() {});
                        },
                        splashRadius: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final l10n = context.l10n;
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPillChip(l10n.all, null),
                  const SizedBox(width: 8),
                  ...PostCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildPillChip(categoryDisplayName(cat, l10n), cat),
                  )),
                ],
              ),
            ),
          ),
          IconButton(
            key: _sortButtonKey,
            icon: const Icon(Icons.tune, color: _kOnSurfaceVariant),
            onPressed: _showSortMenu,
            splashRadius: 22,
            tooltip: l10n.sortBy,
          ),
        ],
      ),
    );
  }

  Widget _buildPillChip(String label, PostCategory? category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : _kSurfaceContainerHighest,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? _kOnPrimary : _kOnSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showSortMenu() {
    final l10n = context.l10n;
    final RenderBox button =
        _sortButtonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<SortBy>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      items: [
        _sortMenuItem(l10n.latest, SortBy.latest),
        _sortMenuItem(l10n.hottest, SortBy.hot),
        _sortMenuItem(l10n.mostLiked, SortBy.mostLiked),
        _sortMenuItem(l10n.mostDiscussed, SortBy.mostDiscussed),
      ],
    ).then((value) {
      if (value != null && mounted) setState(() => _sortBy = value);
    });
  }

  PopupMenuItem<SortBy> _sortMenuItem(String label, SortBy value) {
    return PopupMenuItem<SortBy>(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check, size: 18, color: _kPrimary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              color: _kOnSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostFeed() {
    final l10n = context.l10n;
    return StreamBuilder<List<NewsPost>>(
      stream: _newsService.streamPosts(category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    l10n.cannotLoadPosts,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _kOnSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _kOnSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedCategory = null),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.tryAgain),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: _kOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _kPrimary));
        }

        final posts = snapshot.data!;
        final sortedPosts = _sortPosts(posts);

        if (sortedPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80, color: _kSurfaceContainerHighest),
                const SizedBox(height: 16),
                Text(
                  l10n.noPostsYet,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kOnSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.beFirstToShare,
                  style: TextStyle(color: _kOnSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: _kPrimary,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            itemCount: sortedPosts.length,
            itemBuilder: (context, index) => _buildPostCard(sortedPosts[index]),
          ),
        );
      },
    );
  }

  /// Sort posts based on selected option
  List<NewsPost> _sortPosts(List<NewsPost> posts) {
    final sorted = List<NewsPost>.from(posts);

    switch (_sortBy) {
      case SortBy.latest:
        // Already sorted by createdAt descending from Supabase
        break;

      case SortBy.hot:
        // Hot = combination of likes and comments (weighted)
        sorted.sort((a, b) {
          final scoreA = (a.likeCount * 2) + a.commentCount;
          final scoreB = (b.likeCount * 2) + b.commentCount;
          return scoreB.compareTo(scoreA);
        });
        break;

      case SortBy.mostLiked:
        sorted.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;

      case SortBy.mostDiscussed:
        sorted.sort((a, b) => b.commentCount.compareTo(a.commentCount));
        break;
    }

    return sorted;
  }

  Widget _buildPostCard(NewsPost post) {
    if (post.postId.isEmpty) {
      return _buildPostCardContent(post, post.isLikedBy(currentUserId), post.likeCount);
    }

    _syncLikeOverridesIfServerCaughtUp(post);
    final isLiked = _likeState[post.postId] ?? post.isLikedBy(currentUserId);
    final likeCount = _likeCountState[post.postId] ?? post.likeCount;

    return _buildPostCardContent(post, isLiked, likeCount);
  }

  Widget _buildPostCardContent(NewsPost post, bool isLiked, int likeCount) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => PostDetailPage(post: post)),
        );
        if (changed == true && mounted) setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _kSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _kOnSurface.withValues(alpha: 0.06),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main content — left padding 40 to clear avatar
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 16, top: 20, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    post.authorName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _kOnSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(post.createdAt),
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: _kOnSurfaceVariant.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryBadge(post),
                      if (post.authorId == currentUserId)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: _kOnSurfaceVariant,
                            size: 20,
                          ),
                          onSelected: (value) => _handlePostAction(value, post),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(context.l10n.edit),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(context.l10n.delete,
                                      style: const TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    post.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kOnSurface,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Content preview
                  Text(
                    post.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: _kOnSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  // Image
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: _kSurfaceContainerHighest,
                            child: const Icon(Icons.broken_image,
                                size: 48, color: _kOnSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Divider
                  Container(height: 1, color: _kSurfaceContainer),

                  // Action bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        // Like
                        InkWell(
                          onTap: () => _handleLikeTap(post, isLiked, likeCount),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked
                                      ? Colors.red
                                      : _kOnSurfaceVariant,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$likeCount',
                                  style: GoogleFonts.manrope(
                                    color: _kOnSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Comment
                        Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline,
                                color: _kPrimary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              '${post.commentCount}',
                              style: GoogleFonts.manrope(
                                color: _kOnSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Share
                        const Icon(Icons.share_outlined,
                            color: _kOnSurfaceVariant, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Asymmetric avatar — lệch -8px ra ngoài bên trái
            Positioned(
              left: -8,
              top: 20,
              child: _buildAvatarWidget(post),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(PostCategory category) {
    switch (category) {
      case PostCategory.mentalHealth:
        return _kOnSecondaryContainer;
      case PostCategory.meditation:
        return const Color(0xFF7B3FC4); // purple tint
      case PostCategory.wellness:
        return _kPrimary;
      case PostCategory.tips:
        return _kOnSecondaryContainer;
      case PostCategory.community:
        return _kOnTertiaryContainer;
      case PostCategory.news:
        return _kOnSurfaceVariant;
    }
  }

  Color _getCategoryBgColor(PostCategory category) {
    switch (category) {
      case PostCategory.mentalHealth:
        return _kSecondaryContainer;
      case PostCategory.meditation:
        return const Color(0xFFE9D5FF); // purple-100
      case PostCategory.wellness:
        return _kPrimaryContainer;
      case PostCategory.tips:
        return _kSecondaryContainer;
      case PostCategory.community:
        return _kTertiaryContainer;
      case PostCategory.news:
        return _kSurfaceContainerHigh;
    }
  }

  Widget _buildAvatarWidget(NewsPost post) {
    final isAnon = post.authorName == 'Anonymous';
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _kSurface, width: 4),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: isAnon ? _kSurfaceContainerHighest : _kPrimaryContainer,
        backgroundImage: !isAnon &&
                post.authorAvatarUrl != null &&
                post.authorAvatarUrl!.isNotEmpty
            ? (_isBase64(post.authorAvatarUrl!)
                    ? MemoryImage(base64Decode(post.authorAvatarUrl!))
                    : NetworkImage(post.authorAvatarUrl!))
                as ImageProvider
            : null,
        child: isAnon
            ? const Icon(Icons.visibility_off, size: 18, color: _kOnSurfaceVariant)
            : (post.authorAvatarUrl == null || post.authorAvatarUrl!.isEmpty
                ? Text(
                    post.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null),
      ),
    );
  }

  Widget _buildCategoryBadge(NewsPost post) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryBgColor(post.category),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        categoryDisplayName(post.category, l10n).toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _getCategoryColor(post.category),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _handleLikeTap(NewsPost post, bool currentlyLiked, int currentCount) async {
    if (post.postId.isEmpty) return;
    if (_likeUpdating.contains(post.postId)) return;

    final nextLiked = !currentlyLiked;
    final nextCount = nextLiked
        ? currentCount + 1
        : (currentCount - 1 < 0 ? 0 : currentCount - 1);

    setState(() {
      _likeUpdating.add(post.postId);
      _likeState[post.postId] = nextLiked;
      _likeCountState[post.postId] = nextCount;
    });

    try {
      await _newsService.toggleLike(post.postId, currentUserId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likeState[post.postId] = currentlyLiked;
        _likeCountState[post.postId] = currentCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.l10n.errorPrefix}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _likeUpdating.remove(post.postId));
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

  void _syncLikeOverridesIfServerCaughtUp(NewsPost post) {
    if (post.postId.isEmpty) return;

    final optimisticLiked = _likeState[post.postId];
    final optimisticCount = _likeCountState[post.postId];

    if (optimisticLiked == null && optimisticCount == null) return;

    final serverLiked = post.isLikedBy(currentUserId);
    final serverCount = post.likeCount;

    if (optimisticLiked == serverLiked && optimisticCount == serverCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _likeState.remove(post.postId);
          _likeCountState.remove(post.postId);
        });
      });
    }
  }

  Map<String, bool> get _likeState => _optimisticLikeState ??= <String, bool>{};
  Map<String, int> get _likeCountState => _optimisticLikeCount ??= <String, int>{};
  Set<String> get _likeUpdating => _likeUpdatingPosts ??= <String>{};

  /// Handle post menu actions (Edit/Delete)
  void _handlePostAction(String action, NewsPost post) {
    switch (action) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
    }
  }

  /// Edit post
  Future<void> _editPost(NewsPost post) async {
    // Navigate to edit page (we'll create this)
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage(postToEdit: post)),
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }

  /// Delete post with confirmation
  Future<void> _deletePost(NewsPost post) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deletePost),
        content: Text(l10n.deletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _newsService.deletePost(post.postId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.postDeletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.errorDeletingPost}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Organic Sanctuary color palette
const _kSurface = Color(0xFFDDFFE2);
const _kPrimary = Color(0xFF006B1B);
const _kOnPrimary = Color(0xFFD1FFC8);
const _kOnSurface = Color(0xFF0B361D);
const _kOnSurfaceVariant = Color(0xFF3B6447);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kSurfaceContainerHighest = Color(0xFFACECBB);
const _kPrimaryContainer = Color(0xFF76FB7A);
const _kSecondaryContainer = Color(0xFF86FAAC);
const _kOnSecondaryContainer = Color(0xFF005F32);
const _kTertiaryContainer = Color(0xFF11EAFF);
const _kOnTertiaryContainer = Color(0xFF005159);
const _kSurfaceContainerHigh = Color(0xFFB5F0C2);
const _kSurfaceContainer = Color(0xFFBEF5CA);
