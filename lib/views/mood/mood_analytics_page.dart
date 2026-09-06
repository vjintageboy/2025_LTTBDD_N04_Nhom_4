import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../ai/mood_insight.dart';
import '../../models/mood_entry.dart';
import '../../core/services/localization_service.dart';
import '../../services/supabase_service.dart';

// ── Organic Sanctuary palette ─────────────────────────────────────────────
const _kSurface = Color(0xFFDDFFE2);
const _kSurfaceContainerLow = Color(0xFFCAFDD4);
const _kSurfaceContainerHigh = Color(0xFFB5F0C2);
const _kSurfaceContainerHighest = Color(0xFFACECBB);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kOnSurface = Color(0xFF0B361D);
const _kOnSurfaceVariant = Color(0xFF3B6447);
const _kPrimary = Color(0xFF006B1B);

class MoodAnalyticsPage extends StatefulWidget {
  const MoodAnalyticsPage({super.key});

  @override
  State<MoodAnalyticsPage> createState() => _MoodAnalyticsPageState();
}

class _MoodAnalyticsPageState extends State<MoodAnalyticsPage> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week';

  // AI insight — recomputed on demand, never persisted.
  String? _insight;
  String? _insightError;
  bool _insightLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      // The insight describes the old period — drop it.
      _insight = null;
      _insightError = null;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (_selectedPeriod) {
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      final entries = await _supabaseService.getMoodEntriesForPeriod(
        userId: user.id,
        start: startDate,
        end: now,
      );

      if (mounted) {
        setState(() {
          _moodEntries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.errorLoadingMoodData(e.toString()),
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _runAIInsight() async {
    if (_insightLoading || _moodEntries.isEmpty) return;

    setState(() {
      _insightLoading = true;
      _insightError = null;
    });

    try {
      final text = await MoodInsight.analyze(
        entries: _moodEntries,
        periodLabel: _periodLabel,
      );
      if (mounted) setState(() => _insight = text);
    } catch (e) {
      if (mounted) setState(() => _insightError = e.toString());
    } finally {
      if (mounted) setState(() => _insightLoading = false);
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case 'month': return context.l10n.month;
      case 'year': return context.l10n.year;
      default: return context.l10n.week;
    }
  }

  // ── Computed properties ───────────────────────────────────────────────────

  double get _averageMood {
    if (_moodEntries.isEmpty) return 0.0;
    return _moodEntries.fold<int>(0, (s, e) => s + e.moodLevel) /
        _moodEntries.length;
  }

  Map<int, int> get _moodDistribution {
    final d = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var e in _moodEntries) {
      d[e.moodLevel] = (d[e.moodLevel] ?? 0) + 1;
    }
    return d;
  }

  Map<String, int> get _emotionFactorFrequency {
    final freq = <String, int>{};
    for (var e in _moodEntries) {
      for (var f in e.emotionFactors) {
        freq[f] = (freq[f] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  MoodEntry? get _bestDay =>
      _moodEntries.isEmpty
          ? null
          : _moodEntries.reduce((a, b) => a.moodLevel > b.moodLevel ? a : b);

  MoodEntry? get _worstDay =>
      _moodEntries.isEmpty
          ? null
          : _moodEntries.reduce((a, b) => a.moodLevel < b.moodLevel ? a : b);

  // ── Mood helpers ──────────────────────────────────────────────────────────

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1: return '😫';
      case 2: return '😞';
      case 3: return '😐';
      case 4: return '😊';
      case 5: return '🤩';
      default: return '😐';
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1: return context.l10n.veryPoor;
      case 2: return context.l10n.poor;
      case 3: return context.l10n.okay;
      case 4: return context.l10n.good;
      case 5: return context.l10n.excellent;
      default: return context.l10n.okay;
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return const Color(0xFFE53935);
      case 2: return const Color(0xFFFB8C00);
      case 3: return const Color(0xFFF9A825);
      case 4: return const Color(0xFF7CB342);
      case 5: return const Color(0xFF2E7D32);
      default: return _kOnSurfaceVariant;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            IconsaxPlusLinear.arrow_left_2,
            color: _kPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.moodAnalyticsTitle,
          style: GoogleFonts.plusJakartaSans(
            color: _kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  if (_moodEntries.isNotEmpty) ...[
                    _buildOverviewCards(),
                    const SizedBox(height: 20),
                    _buildMoodTrendChart(),
                    const SizedBox(height: 20),
                    _buildMoodDistribution(),
                    const SizedBox(height: 20),
                    _buildTopEmotionFactors(),
                    const SizedBox(height: 20),
                    _buildBestWorstDays(),
                    const SizedBox(height: 20),
                    _buildAIInsight(),
                  ] else
                    _buildEmptyState(),
                ],
              ),
            ),
    );
  }

  // ── Period selector ───────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          _buildPeriodButton(context.l10n.week, 'week'),
          _buildPeriodButton(context.l10n.month, 'month'),
          _buildPeriodButton(context.l10n.year, 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _loadMoodData();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.25),
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : _kOnSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ── Overview stat cards ───────────────────────────────────────────────────

  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                emoji: _getMoodEmoji(_averageMood.round()),
                value: _averageMood.toStringAsFixed(1),
                subtitle: context.l10n.averageMood,
                label: context.l10n.mood,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                emoji: '📊',
                value: _moodEntries.length.toString(),
                subtitle: context.l10n.totalEntries,
                label: context.l10n.data,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                emoji: '🔥',
                value: '${_calculateStreak()} ${context.l10n.days}',
                subtitle: context.l10n.currentStreak,
                label: context.l10n.flow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                emoji: '↑',
                value: '+${_calculateTrend()}%',
                subtitle: context.l10n.moodTrend,
                label: context.l10n.growth,
                valueColor: const Color(0xFF006B1B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _calculateStreak() {
    if (_moodEntries.isEmpty) return 0;
    final sorted = List<MoodEntry>.from(_moodEntries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    int streak = 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < sorted.length - 1; i++) {
      final current = DateTime(sorted[i].timestamp.year, sorted[i].timestamp.month, sorted[i].timestamp.day);
      final next = DateTime(sorted[i + 1].timestamp.year, sorted[i + 1].timestamp.month, sorted[i + 1].timestamp.day);
      
      if (current.difference(next).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    
    // Check if the most recent entry is today or yesterday
    final mostRecent = DateTime(sorted.first.timestamp.year, sorted.first.timestamp.month, sorted.first.timestamp.day);
    if (today.difference(mostRecent).inDays > 1) {
      return 0;
    }
    
    return streak;
  }

  int _calculateTrend() {
    if (_moodEntries.length < 2) return 0;
    final sorted = List<MoodEntry>.from(_moodEntries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    final mid = sorted.length ~/ 2;
    final firstHalf = sorted.sublist(0, mid);
    final secondHalf = sorted.sublist(mid);
    
    final firstAvg = firstHalf.fold<int>(0, (s, e) => s + e.moodLevel) / firstHalf.length;
    final secondAvg = secondHalf.fold<int>(0, (s, e) => s + e.moodLevel) / secondHalf.length;
    
    if (firstAvg == 0) return 0;
    return ((secondAvg - firstAvg) / firstAvg * 100).round();
  }

  Widget _buildStatCard({
    required String emoji,
    required String value,
    required String subtitle,
    required String label,
    Color? valueColor,
  }) {
    final color = valueColor ?? _kOnSurface;
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kOnSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kOnSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood trend chart ──────────────────────────────────────────────────────

  Widget _buildMoodTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            context.l10n.moodTrends,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kOnSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: SizedBox(
            height: 200,
            child: _MoodLineChart(entries: _moodEntries),
          ),
        ),
      ],
    );
  }

  // ── Mood distribution ─────────────────────────────────────────────────────

  Widget _buildMoodDistribution() {
    final distribution = _moodDistribution;
    final total = _moodEntries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            context.l10n.distribution,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kOnSurface,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
        children: distribution.entries.map((entry) {
          final percentage = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getMoodEmoji(entry.key),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMoodLabel(entry.key),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kOnSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} (${(percentage * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: _kSurfaceContainerLow,
                    color: _getMoodColor(entry.key),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Key Influencers ───────────────────────────────────────────────────────

  Widget _buildTopEmotionFactors() {
    final topFactors = _emotionFactorFrequency.entries.take(8).toList();
    if (topFactors.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            context.l10n.keyInfluencers,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kOnSurface,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topFactors.map((entry) => _buildInfluencerChip(entry.key, entry.value)).toList(),
        ),
      ],
    );
  }

  // ── AI insight ────────────────────────────────────────────────────────────

  Widget _buildAIInsight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            context.l10n.aiInsight,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kOnSurface,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _insight ??
                    (_insightError != null
                        ? context.l10n.aiInsightError(_insightError!)
                        : context.l10n.aiInsightPrompt),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: _insightError != null ? _kOnSurfaceVariant : _kOnSurface,
                ),
              ),
              const SizedBox(height: 18),
              _buildInsightButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightButton() {
    final label = _insightLoading
        ? context.l10n.aiInsightAnalyzing
        : (_insight != null || _insightError != null)
            ? context.l10n.aiInsightRetry
            : context.l10n.aiInsightAnalyze;

    return GestureDetector(
      onTap: _insightLoading ? null : _runAIInsight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: _insightLoading ? _kSurfaceContainerHighest : _kPrimary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_insightLoading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_kPrimary),
                ),
              )
            else
              const Icon(IconsaxPlusBold.magicpen, size: 17, color: Colors.white),
            const SizedBox(width: 9),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _insightLoading ? _kPrimary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfluencerChip(String label, int count) {
    final icon = _getInfluencerIcon(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kOnSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getInfluencerIcon(String factor) {
    final lower = factor.toLowerCase();
    if (lower.contains('work') || lower.contains('job') || lower.contains('career')) {
      return IconsaxPlusLinear.briefcase;
    } else if (lower.contains('family') || lower.contains('home')) {
      return IconsaxPlusLinear.profile_2user;
    } else if (lower.contains('exercise') || lower.contains('sport') || lower.contains('fitness')) {
      return PhosphorIconsRegular.barbell;
    } else if (lower.contains('health') || lower.contains('medical')) {
      return PhosphorIconsRegular.leaf;
    } else if (lower.contains('social') || lower.contains('friend')) {
      return IconsaxPlusLinear.people;
    } else if (lower.contains('sleep')) {
      return IconsaxPlusLinear.moon;
    } else if (lower.contains('finance') || lower.contains('money')) {
      return IconsaxPlusLinear.dollar_square;
    } else if (lower.contains('love') || lower.contains('relationship')) {
      return IconsaxPlusLinear.heart;
    }
    return IconsaxPlusLinear.tag;
  }

  // ── Best & Worst days ─────────────────────────────────────────────────────

  Widget _buildBestWorstDays() {
    final best = _bestDay;
    final worst = _worstDay;
    if (best == null || worst == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            context.l10n.monthlyHighlights,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kOnSurface,
            ),
          ),
        ),
        _buildHighlightCard(
          title: context.l10n.bestDay,
          emoji: _getMoodEmoji(best.moodLevel),
          date: DateFormat('MMM dd, yyyy').format(best.timestamp),
          moodLevel: best.moodLevel,
          accentColor: const Color(0xFF2E7D32),
          bgColor: const Color(0xFFEAF7EA),
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          title: context.l10n.needsAttention,
          emoji: _getMoodEmoji(worst.moodLevel),
          date: DateFormat('MMM dd, yyyy').format(worst.timestamp),
          moodLevel: worst.moodLevel,
          accentColor: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String emoji,
    required String date,
    required int moodLevel,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kOnSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kOnSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _getMoodLabel(moodLevel).toUpperCase(),
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kSurfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconsaxPlusLinear.chart,
                size: 40,
                color: _kOnSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.noDataThisPeriod,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.startLoggingMoodAnalytics,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: _kOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Line chart ────────────────────────────────────────────────────────────

class _MoodLineChart extends StatelessWidget {
  final List<MoodEntry> entries;

  const _MoodLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noDataToDisplay,
          style: GoogleFonts.manrope(color: _kOnSurfaceVariant),
        ),
      );
    }

    final sorted = List<MoodEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return CustomPaint(
      painter: _LineChartPainter(sorted),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MoodEntry> entries;

  _LineChartPainter(this.entries);

  Color _moodColor(int level) {
    switch (level) {
      case 1: return const Color(0xFFE53935);
      case 2: return const Color(0xFFFB8C00);
      case 3: return const Color(0xFFF9A825);
      case 4: return const Color(0xFF7CB342);
      case 5: return const Color(0xFF2E7D32);
      default: return _kPrimary;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    // Grid
    final gridPaint = Paint()
      ..color = _kSurfaceContainerHigh.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (i * size.height / 4) - 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gradient fill under the line
    final points = <Offset>[];
    for (int i = 0; i < entries.length; i++) {
      final level = entries[i].moodLevel.clamp(1, 5);
      final x = entries.length > 1
          ? (i / (entries.length - 1)) * size.width
          : size.width / 2;
      final normalized = (level - 1) / 4;
      final y = size.height - (normalized * (size.height - 30) * 0.9) - 24;
      if (x.isFinite && y.isFinite) points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Fill path with smoother curve
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
          _kPrimary.withValues(alpha: 0.15),
          _kPrimary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line with smoother curve
    final linePaint = Paint()
      ..color = _kPrimary
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

    // Dots — colour-coded per mood level
    for (int i = 0; i < points.length; i++) {
      final level = entries[i].moodLevel.clamp(1, 5);
      final color = _moodColor(level);

      // White ring
      canvas.drawCircle(
        points[i],
        7,
        Paint()..color = Colors.white,
      );
      // Coloured fill
      canvas.drawCircle(
        points[i],
        5,
        Paint()..color = color,
      );
    }

    // Day labels
    final dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    
    for (int i = 0; i < entries.length && i < dayLabels.length; i++) {
      final x = entries.length > 1
          ? (i / (entries.length - 1)) * size.width
          : size.width / 2;
      
      textPainter.text = TextSpan(
        text: dayLabels[i],
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _kOnSurfaceVariant.withValues(alpha: 0.6),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 16),
      );
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.entries != entries;
}
