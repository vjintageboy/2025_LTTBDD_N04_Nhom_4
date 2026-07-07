import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final _supabase = Supabase.instance.client;
  String _period = '7';
  bool _isLoading = true;

  // Raw data
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _allMoods = [];
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _allPostLikes = [];
  List<Map<String, dynamic>> _allPostComments = [];
  List<Map<String, dynamic>> _allAiConversations = [];

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
    _loadData();
  }

  Future<T?> _safeQuery<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('Analytics query error: $e');
      return null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final usersResult = await _safeQuery(
        () => _supabase.from('users').select('id, role, is_banned, created_at'));
    final moodsResult = await _safeQuery(() => _supabase
        .from('mood_entries')
        .select('user_id, mood_score, emotion_factors, created_at'));
    final postsResult = await _safeQuery(() => _supabase
        .from('posts')
        .select('id, title, likes_count, comment_count, created_at'));
    final likesResult = await _safeQuery(
        () => _supabase.from('post_likes').select('created_at'));
    final commentsResult = await _safeQuery(
        () => _supabase.from('post_comments').select('created_at'));
    final aiResult = await _safeQuery(() => _supabase
        .from('ai_conversations')
        .select('user_id, created_at'));

    if (!mounted) return;

    setState(() {
      _allUsers = usersResult != null
          ? List<Map<String, dynamic>>.from(usersResult as List)
          : [];
      _allMoods = moodsResult != null
          ? List<Map<String, dynamic>>.from(moodsResult as List)
          : [];
      _allPosts = postsResult != null
          ? List<Map<String, dynamic>>.from(postsResult as List)
          : [];
      _allPostLikes = likesResult != null
          ? List<Map<String, dynamic>>.from(likesResult as List)
          : [];
      _allPostComments = commentsResult != null
          ? List<Map<String, dynamic>>.from(commentsResult as List)
          : [];
      _allAiConversations = aiResult != null
          ? List<Map<String, dynamic>>.from(aiResult as List)
          : [];
      _isLoading = false;
    });
  }

  DateTime get _rangeStart {
    final now = DateTime.now();
    final days = int.tryParse(_period) ?? 7;
    return now.subtract(Duration(days: days));
  }

  // ── Filtered helpers (client-side) ─────────────────────────────────────

  List<Map<String, dynamic>> _inRange(List<Map<String, dynamic>> rows) {
    final start = _rangeStart;
    return rows.where((r) {
      final ts = DateTime.tryParse(r['created_at']?.toString() ?? '');
      return ts != null && !ts.isBefore(start);
    }).toList();
  }

  // Regular users only — keep counts consistent with the dashboard.
  List<Map<String, dynamic>> get _regularUsers =>
      _allUsers.where((u) => u['role'] == 'user').toList();

  int get _newUsers => _inRange(_regularUsers).length;

  int get _prevRangeUserCount {
    final now = DateTime.now();
    final days = int.tryParse(_period) ?? 7;
    final start = now.subtract(Duration(days: days * 2));
    final end = now.subtract(Duration(days: days));
    return _regularUsers.where((r) {
      final ts = DateTime.tryParse(r['created_at']?.toString() ?? '');
      return ts != null && !ts.isBefore(start) && ts.isBefore(end);
    }).length;
  }

  List<Map<String, dynamic>> get _filteredMoods => _inRange(_allMoods);

  double get _averageMood {
    final moods = _filteredMoods;
    if (moods.isEmpty) return 0;
    final sum = moods.fold<double>(
        0, (p, e) => p + ((e['mood_score'] as num?)?.toDouble() ?? 0));
    return sum / moods.length;
  }

  // ── Section 1: User growth bar chart ───────────────────────────────────

  Widget _buildUserGrowthSection() {
    final start = _rangeStart;
    final days = int.tryParse(_period) ?? 7;

    // Bucket by day
    final buckets = <DateTime, int>{};
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      buckets[DateTime(d.year, d.month, d.day)] = 0;
    }
    for (final r in _regularUsers) {
      final ts = DateTime.tryParse(r['created_at']?.toString() ?? '');
      if (ts == null) continue;
      final d = DateTime(ts.year, ts.month, ts.day);
      if (buckets.containsKey(d)) buckets[d] = (buckets[d] ?? 0) + 1;
    }

    // For 30/90 days, group by week
    final bool groupByWeek = days > 7;
    List<MapEntry<String, int>> entries;
    if (groupByWeek) {
      final weekMap = <String, int>{};
      for (final e in buckets.entries) {
        final weekStart = e.key.subtract(Duration(days: e.key.weekday - 1));
        final key =
            '${weekStart.day}/${weekStart.month}';
        weekMap[key] = (weekMap[key] ?? 0) + e.value;
      }
      entries = weekMap.entries.toList();
    } else {
      const viWeekday = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      entries = buckets.entries
          .map((e) => MapEntry(viWeekday[e.key.weekday - 1], e.value))
          .toList();
    }

    final maxVal =
        entries.fold<int>(0, (p, e) => e.value > p ? e.value : p);
    final total = _newUsers;
    final prev = _prevRangeUserCount;
    final percentChange = prev > 0 ? ((total - prev) / prev * 100).round() : 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tăng trưởng người dùng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.osOnSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$total người dùng mới trong $_period ngày',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.osOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.osPrimaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    percentChange > 0
                        ? '↑ +$percentChange%'
                        : percentChange < 0
                            ? '↓ $percentChange%'
                            : '+$total',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.osOnPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu',
                      style: GoogleFonts.manrope(
                        color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(entries.length, (i) {
                      final value = entries[i].value;
                      final heightFactor =
                          maxVal == 0 ? 0.04 : (0.04 + 0.96 * value / maxVal);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: heightFactor,
                                    widthFactor: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: i == entries.length - 1
                                            ? AppColors.osPrimary
                                            : AppColors.osPrimaryFixedDim,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entries[i].key,
                                style: GoogleFonts.manrope(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.osOnSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Section 2: Emotional health ────────────────────────────────────────

  Widget _buildEmotionalHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Sức khỏe cảm xúc'),
        const SizedBox(height: 12),
        _buildMoodLineChart(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildEmotionDistribution()),
            const SizedBox(width: 12),
            Expanded(child: _buildFactorRanking()),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodLineChart() {
    final moods = _filteredMoods;
    final start = _rangeStart;
    final days = int.tryParse(_period) ?? 7;

    // Group by day, compute average mood_score
    final dayMap = <DateTime, List<double>>{};
    for (final r in moods) {
      final ts = DateTime.tryParse(r['created_at']?.toString() ?? '');
      final score = (r['mood_score'] as num?)?.toDouble();
      if (ts == null || score == null) continue;
      final d = DateTime(ts.year, ts.month, ts.day);
      dayMap.putIfAbsent(d, () => []).add(score);
    }

    final dayAvgs = <_DayAvg>[];
    for (int i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      final key = DateTime(d.year, d.month, d.day);
      final scores = dayMap[key];
      if (scores != null && scores.isNotEmpty) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        dayAvgs.add(_DayAvg(d, avg));
      }
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Mood trung bình theo ngày',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.osOnSurface,
                ),
              ),
              const Spacer(),
              if (_averageMood > 0)
                Text(
                  _averageMood.toStringAsFixed(1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getMoodColor(_averageMood.round()),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (dayAvgs.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Chưa có dữ liệu',
                  style: GoogleFonts.manrope(
                    color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: CustomPaint(
                size: Size.infinite,
                painter: _LineChartPainter(dayAvgs),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution() {
    final moods = _filteredMoods;
    final counts = List<int>.filled(5, 0);
    for (final r in moods) {
      final score = (r['mood_score'] as num?)?.toInt();
      if (score != null && score >= 1 && score <= 5) {
        counts[score - 1]++;
      }
    }
    final total = counts.fold<int>(0, (a, b) => a + b);
    const labels = ['😢', '😕', '😐', '🙂', '😄'];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bố cảm xúc',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.osOnSurface,
            ),
          ),
          const SizedBox(height: 14),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu',
                  style: GoogleFonts.manrope(
                    color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ...List.generate(5, (i) {
              final count = counts[i];
              final frac = total > 0 ? count / total : 0.0;
              final color = AppColors.getMoodColor(i + 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        labels[i],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: SizedBox(
                          height: 10,
                          child: FractionallySizedBox(
                            widthFactor: frac.clamp(0.0, 1.0),
                            alignment: Alignment.centerLeft,
                            child: Container(color: color),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$count',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.osOnSurface,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFactorRanking() {
    final moods = _filteredMoods;
    final factorCounts = <String, int>{};
    for (final r in moods) {
      final factors = r['emotion_factors'];
      if (factors is List) {
        for (final f in factors) {
          final s = f?.toString() ?? '';
          if (s.isNotEmpty) {
            factorCounts[s] = (factorCounts[s] ?? 0) + 1;
          }
        }
      }
    }

    final sorted = factorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    final maxCount = top5.isNotEmpty ? top5.first.value : 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yếu tố ảnh hưởng',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.osOnSurface,
            ),
          ),
          const SizedBox(height: 14),
          if (top5.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu',
                  style: GoogleFonts.manrope(
                    color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else
            ...List.generate(top5.length, (i) {
              final e = top5[i];
              final frac = maxCount > 0 ? e.value / maxCount : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        e.key,
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: AppColors.osOnSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: SizedBox(
                          height: 8,
                          child: FractionallySizedBox(
                            widthFactor: frac.clamp(0.0, 1.0),
                            alignment: Alignment.centerLeft,
                            child: Container(color: AppColors.osPrimary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.value}',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.osOnSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Section 3: Content activity ────────────────────────────────────────

  Widget _buildContentActivitySection() {
    final posts = _inRange(_allPosts);
    final likes = _inRange(_allPostLikes);
    final comments = _inRange(_allPostComments);

    // Top 3 posts by engagement in range
    final ranked = List<Map<String, dynamic>>.from(posts)
      ..sort((a, b) {
        final aScore =
            ((a['likes_count'] as num?)?.toInt() ?? 0) +
                ((a['comment_count'] as num?)?.toInt() ?? 0);
        final bScore =
            ((b['likes_count'] as num?)?.toInt() ?? 0) +
                ((b['comment_count'] as num?)?.toInt() ?? 0);
        return bScore.compareTo(aScore);
      });
    var top3 = ranked.take(3).toList();

    // Fallback to all-time if range is empty
    if (top3.isEmpty) {
      final allRanked = List<Map<String, dynamic>>.from(_allPosts)
        ..sort((a, b) {
          final aScore =
              ((a['likes_count'] as num?)?.toInt() ?? 0) +
                  ((a['comment_count'] as num?)?.toInt() ?? 0);
          final bScore =
              ((b['likes_count'] as num?)?.toInt() ?? 0) +
                  ((b['comment_count'] as num?)?.toInt() ?? 0);
          return bScore.compareTo(aScore);
        });
      top3 = allRanked.take(3).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Hoạt động nội dung'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _miniStat('Bài viết', '${posts.length}',
                  IconsaxPlusLinear.document_text),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStat(
                  'Lượt thích', '${likes.length}', IconsaxPlusBold.heart),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniStat('Bình luận', '${comments.length}',
                  IconsaxPlusLinear.message),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTopPosts(top3, posts.isEmpty),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return _card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.osPrimary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.osOnSurface,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.osOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPosts(List<Map<String, dynamic>> top3, bool isFallback) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bài viết nổi bật',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.osOnSurface,
                ),
              ),
              if (isFallback) ...[
                const SizedBox(width: 8),
                Text(
                  '(Mọi thời gian)',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.osOnSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (top3.isEmpty)
            Text(
              'Chưa có bài viết nào',
              style: GoogleFonts.manrope(
                color: AppColors.osOnSurfaceVariant.withValues(alpha: 0.5),
              ),
            )
          else
            ...List.generate(top3.length, (i) {
              final p = top3[i];
              final likes = (p['likes_count'] as num?)?.toInt() ?? 0;
              final cmts = (p['comment_count'] as num?)?.toInt() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.osSurfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.osPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p['title']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.osOnSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(IconsaxPlusBold.heart,
                            size: 12, color: AppColors.osOnSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '$likes',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.osOnSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(IconsaxPlusLinear.message,
                            size: 12, color: AppColors.osOnSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '$cmts',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppColors.osOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ── Section 4: Engagement ──────────────────────────────────────────────

  Widget _buildEngagementSection() {
    final regularIds =
        _regularUsers.map((u) => u['id']?.toString()).toSet();
    final moodUsers = _filteredMoods
        .map((r) => r['user_id']?.toString())
        .where((id) => id != null && regularIds.contains(id))
        .toSet();
    final activeCount = moodUsers.length;

    final totalRegular = _regularUsers.length;

    final aiConvos = _inRange(_allAiConversations).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mức độ tương tác'),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(IconsaxPlusLinear.user, size: 18, color: AppColors.osPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Người dùng hoạt động',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.osOnSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$activeCount / $totalRegular người dùng',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColors.osOnSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: SizedBox(
                  height: 8,
                  child: FractionallySizedBox(
                    widthFactor: totalRegular > 0
                        ? (activeCount / totalRegular).clamp(0.0, 1.0)
                        : 0.0,
                    alignment: Alignment.centerLeft,
                    child: Container(color: AppColors.osPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(IconsaxPlusLinear.message, size: 18, color: AppColors.osPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hội thoại AI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.osOnSurface,
                  ),
                ),
              ),
              Text(
                '$aiConvos',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.osOnSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.osOnSurface,
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _ambientShadow,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.osSurface,
      child: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.osPrimary,
          backgroundColor: AppColors.osSurfaceContainerLowest,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.osPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Phân tích',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thống kê nền tảng',
                              style: GoogleFonts.manrope(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _isLoading ? _buildSkeleton() : _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Period selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainer,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                _periodBtn('7 ngày', '7'),
                _periodBtn('30 ngày', '30'),
                _periodBtn('90 ngày', '90'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1
          _sectionTitle('Tăng trưởng người dùng'),
          const SizedBox(height: 12),
          _buildUserGrowthSection(),
          const SizedBox(height: 24),

          // Section 2
          _buildEmotionalHealthSection(),
          const SizedBox(height: 24),

          // Section 3
          _buildContentActivitySection(),
          const SizedBox(height: 24),

          // Section 4
          _buildEngagementSection(),
        ],
      ),
    );
  }

  Widget _periodBtn(String label, String value) {
    final isSelected = _period == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.osPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.osPrimary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.osOnSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    Widget block(double h, {double? w, double r = 16}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainer,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(36, r: 100),
          const SizedBox(height: 24),
          block(20, w: 140),
          const SizedBox(height: 12),
          block(160),
          const SizedBox(height: 24),
          block(20, w: 160),
          const SizedBox(height: 12),
          block(180),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: block(120)),
              const SizedBox(width: 12),
              Expanded(child: block(120)),
            ],
          ),
          const SizedBox(height: 24),
          block(20, w: 140),
          const SizedBox(height: 12),
          block(100),
          const SizedBox(height: 12),
          block(140),
        ],
      ),
    );
  }
}

// ── Line chart painter ─────────────────────────────────────────────────────

class _DayAvg {
  final DateTime day;
  final double avg;
  const _DayAvg(this.day, this.avg);
}

class _LineChartPainter extends CustomPainter {
  final List<_DayAvg> data;

  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.osSurfaceContainerHigh.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final y = size.height - (i * (size.height - 40) / 4) - 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Compute points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x =
          data.length > 1 ? (i / (data.length - 1)) * size.width : size.width / 2;
      final normalized = (data[i].avg - 1) / 4;
      final y =
          size.height - (normalized * (size.height - 40) * 0.9) - 28;
      if (x.isFinite && y.isFinite) points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, size.height - 20);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      fillPath.quadraticBezierTo(p0.dx, p0.dy, midX, (p0.dy + p1.dy) / 2);
    }
    fillPath
      ..lineTo(points.last.dx, size.height - 20)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.osPrimary.withValues(alpha: 0.15),
          AppColors.osPrimary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.osPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      final midY = (p0.dy + p1.dy) / 2;
      linePath.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    for (int i = 0; i < points.length; i++) {
      final level = data[i].avg.round().clamp(1, 5);
      final color = AppColors.getMoodColor(level);
      canvas.drawCircle(points[i], 7, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.data != data;
}
