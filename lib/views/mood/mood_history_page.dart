import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/mood_entry.dart';
import '../../services/supabase_service.dart';
import 'mood_log_page.dart';
import 'mood_analytics_page.dart';
import 'mood_entry_detail_page.dart';
import 'utils/mood_helpers.dart';
import 'widgets/mood_empty_state.dart';
import 'widgets/calendar_legend.dart';
import '../../core/services/localization_service.dart';
import '../../l10n/app_localizations.dart';

// ── Organic Sanctuary palette ─────────────────────────────────────────────
const _kSurface = Color(0xFFDDFFE2);
const _kSurfaceContainerLow = Color(0xFFCAFDD4);
const _kSurfaceContainerHigh = Color(0xFFB5F0C2);
const _kSurfaceContainerHighest = Color(0xFFACECBB);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kOnSurface = Color(0xFF0B361D);
const _kOnSurfaceVariant = Color(0xFF3B6447);
const _kPrimary = Color(0xFF006B1B);
const _kPrimaryContainer = Color(0xFF76FB7A);
const _kOnPrimaryContainer = Color(0xFF005E17);

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  bool _hasCompletedInitialFetch = false;
  StreamSubscription<List<MoodEntry>>? _moodSubscription;
  late TabController _tabController;
  int _currentTabIndex = 0; // source-of-truth for the pill UI (updates immediately on tap)
  int _selectedMoodFilter = 0;
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMoodEntries();
    _subscribeToMoodEntries();
  }

  @override
  void dispose() {
    _moodSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToMoodEntries() {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    _moodSubscription = _supabaseService.streamMoodEntries(user.id).listen(
      (entries) {
        if (mounted) {
          setState(() {
            _moodEntries = entries;
            _isLoading = false;
            _hasCompletedInitialFetch = true;
          });
        }
      },
      onError: (e) {
        debugPrint('Mood stream error (ignored): $e');
      },
    );
  }

  Future<void> _loadMoodEntries() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final entries = await _supabaseService.getMoodEntries(user.id);
      if (mounted) {
        setState(() {
          _moodEntries = entries;
          _isLoading = false;
          _hasCompletedInitialFetch = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasCompletedInitialFetch = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading mood history: $e')),
        );
      }
    }
  }

  Map<String, List<MoodEntry>> get _groupedEntries {
    final grouped = <String, List<MoodEntry>>{};
    for (var entry in _filteredEntries) {
      final dateKey = DateFormat('yyyy-MM-dd').format(entry.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }
    return grouped;
  }

  List<MoodEntry> get _filteredEntries {
    if (_selectedMoodFilter == 0) return _moodEntries;
    return _moodEntries
        .where((e) => e.moodLevel == _selectedMoodFilter)
        .toList();
  }

  Future<void> _deleteMoodEntry(String entryId) async {
    try {
      await _supabaseService.deleteMoodEntry(entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mood entry deleted',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadMoodEntries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _kSurfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Delete Entry',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: _kOnSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this mood entry?',
            style: GoogleFonts.manrope(color: _kOnSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  color: _kOnSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  IconsaxPlusLinear.arrow_left_2,
                  color: _kPrimary,
                  size: 20,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          context.l10n.moodHistory,
          style: GoogleFonts.plusJakartaSans(
            color: _kPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              IconsaxPlusLinear.chart,
              color: _kOnSurfaceVariant,
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoodAnalyticsPage(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodLogPage()),
                );
                if (result == true && mounted) {
                  _loadMoodEntries();
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(IconsaxPlusLinear.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildTabSelector(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kPrimary),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildGroupedView(), _buildCalendarView()],
            ),
    );
  }

  // ── Tab selector ──────────────────────────────────────────────────────────

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            _buildTabItem(0, context.l10n.grouped),
            _buildTabItem(1, context.l10n.calendar),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final selected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentTabIndex = index);
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: selected
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
              color: selected ? Colors.white : _kOnSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  // ── Grouped view ──────────────────────────────────────────────────────────

  Widget _buildGroupedView() {
    final grouped = _groupedEntries;
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: grouped.isEmpty
              ? const MoodEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadMoodEntries,
                  color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 124),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final dateKey = sortedKeys[index];
                      final entries = grouped[dateKey]!;
                      final date = DateTime.parse(dateKey);
                      return _buildDateGroup(date, entries);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;
    final filters = [
      (0, l10n.all, ''),
      (1, l10n.veryPoor, '😫'),
      (2, l10n.poor, '😞'),
      (3, l10n.okay, '😐'),
      (4, l10n.good, '😊'),
      (5, l10n.excellent, '🤩'),
    ];

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (value, label, emoji) = filters[index];
          final selected = _selectedMoodFilter == value;
          return GestureDetector(
            onTap: () => setState(() => _selectedMoodFilter = value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _kPrimary : _kSurfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji.isNotEmpty) ...[
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? Colors.white : _kOnSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateGroup(DateTime date, List<MoodEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    String dateLabel;
    String dateSubLabel;

    if (entryDate == today) {
      dateLabel = context.l10n.today;
      final locale = Localizations.localeOf(context).toString();
      dateSubLabel = DateFormat('EEEE, d MMMM', locale).format(date);
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      dateLabel = context.l10n.yesterday;
      final locale = Localizations.localeOf(context).toString();
      dateSubLabel = DateFormat('EEEE, d MMMM', locale).format(date);
    } else {
      final locale = Localizations.localeOf(context).toString();
      dateLabel = DateFormat('EEEE', locale).format(date);
      dateSubLabel = DateFormat('d MMMM', locale).format(date);
    }

    final avgMood =
        entries.fold<int>(0, (sum, e) => sum + e.moodLevel) / entries.length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kOnSurface,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateSubLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kOnSurfaceVariant,
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
                    color: _kPrimaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${context.l10n.avg}: ${avgMood.toStringAsFixed(1)}',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _kOnPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...entries.map(
            (entry) => _buildMoodEntryCard(entry, showDate: false),
          ),
        ],
      ),
    );
  }

  // ── Calendar view ─────────────────────────────────────────────────────────

  Widget _buildCalendarView() {
    if (_moodEntries.isEmpty) {
      return const MoodEmptyState();
    }

    final entriesByDate = <DateTime, List<MoodEntry>>{};
    for (var entry in _moodEntries) {
      final date = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      if (!entriesByDate.containsKey(date)) {
        entriesByDate[date] = [];
      }
      entriesByDate[date]!.add(entry);
    }

    return Column(
      children: [
        // Month selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          color: _kSurface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMonthNavButton(
                IconsaxPlusLinear.arrow_left_2,
                () => setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                }),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kOnSurface,
                ),
              ),
              _buildMonthNavButton(
                IconsaxPlusLinear.arrow_right_3,
                () {
                  final now = DateTime.now();
                  final next = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                  if (next.isBefore(now) ||
                      (next.year == now.year && next.month == now.month)) {
                    setState(() => _selectedMonth = next);
                  }
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 124),
              child: Column(
                children: [
                  _buildCalendarGrid(entriesByDate),
                  const SizedBox(height: 24),
                  const CalendarLegend(),
                  const SizedBox(height: 24),
                  if (_selectedDate != null)
                    _buildSelectedDateEntries(entriesByDate),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kSurfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _kOnSurface, size: 24),
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<MoodEntry>> entriesByDate) {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((daysInMonth + firstWeekday) / 7).ceil() * 7;

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _kOnSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekday + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              dayNumber,
            );
            final entries = entriesByDate[date] ?? [];
            final avgMood = entries.isEmpty
                ? null
                : entries.fold<int>(0, (sum, e) => sum + e.moodLevel) /
                      entries.length;

            final isSelected =
                _selectedDate != null &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day;

            final isToday =
                DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            return GestureDetector(
              onTap: entries.isNotEmpty
                  ? () => setState(() => _selectedDate = date)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: avgMood != null
                      ? MoodHelpers.getMoodColor(
                          avgMood.round(),
                        ).withValues(alpha: 0.3)
                      : _kSurfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? _kPrimary
                        : isToday
                        ? Colors.blue.shade400
                        : Colors.transparent,
                    width: isSelected || isToday ? 2 : 0,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$dayNumber',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                          color: avgMood != null
                              ? _kOnSurface
                              : _kOnSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    if (entries.isNotEmpty)
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: MoodHelpers.getMoodColor(avgMood!.round()),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entries.length}',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedDateEntries(
    Map<DateTime, List<MoodEntry>> entriesByDate,
  ) {
    final entries = entriesByDate[_selectedDate!] ?? [];
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgMood =
        entries.fold<int>(0, (sum, e) => sum + e.moodLevel) / entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kOnSurface.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM dd').format(_selectedDate!),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entries.length} ${entries.length == 1 ? context.l10n.entry : context.l10n.entries}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: _kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _kPrimaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(
                      MoodHelpers.getMoodEmoji(avgMood.round()),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      avgMood.toStringAsFixed(1),
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kOnPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((entry) => _buildMoodEntryCard(entry, showDate: false)),
      ],
    );
  }

  // ── Mood entry card ───────────────────────────────────────────────────────

  Widget _buildMoodEntryCard(MoodEntry entry, {required bool showDate}) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Dismissible(
      key: Key(entry.entryId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteDialog(context),
      onDismissed: (direction) => _deleteMoodEntry(entry.entryId),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(IconsaxPlusLinear.trash, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodEntryDetailPage(entry: entry),
                ),
              );
              if (result == true) _loadMoodEntries();
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji
                  Text(
                    MoodHelpers.getMoodEmoji(entry.moodLevel),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mood label + time
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                MoodHelpers.getMoodLabel(
                                  context,
                                  entry.moodLevel,
                                ),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _kOnSurface,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              showDate
                                  ? '${dateFormat.format(entry.timestamp)}\n${timeFormat.format(entry.timestamp)}'
                                  : timeFormat.format(entry.timestamp),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kOnSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        // Note
                        if (entry.note != null && entry.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"${entry.note!}"',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: _kOnSurfaceVariant,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        // Emotion factor tags
                        if (entry.emotionFactors.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...entry.emotionFactors
                                  .take(4)
                                  .map((factor) => _buildTag(factor)),
                              if (entry.emotionFactors.length > 4)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kSurfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '+${entry.emotionFactors.length - 4}',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _kOnSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String factor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _kSurfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getEmotionFactorLabel(factor).toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _kOnPrimaryContainer,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getEmotionFactorLabel(String factor) {
    final key = factor.toLowerCase().replaceAll(' ', '');
    switch (key) {
      case 'work':
        return context.l10n.work;
      case 'family':
        return context.l10n.family;
      case 'health':
        return context.l10n.health;
      case 'relationships':
        return context.l10n.relationships;
      case 'sleep':
        return context.l10n.sleep;
      case 'exercise':
        return context.l10n.exercise;
      case 'social':
        return context.l10n.social;
      case 'money':
        return context.l10n.money;
      case 'weather':
        return context.l10n.weather;
      case 'food':
        return context.l10n.food;
      default:
        return factor;
    }
  }
}
