import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';
import 'mood_log_page.dart';
import 'mood_analytics_page.dart';
import 'mood_entry_detail_page.dart';

class MoodHistoryPage extends StatefulWidget {
  const MoodHistoryPage({super.key});

  @override
  State<MoodHistoryPage> createState() => _MoodHistoryPageState();
}

class _MoodHistoryPageState extends State<MoodHistoryPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedMoodFilter = 0; // 0 = All, 1-5 = specific mood levels
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMoodEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final entries = await _firestoreService.getMoodEntries(user.uid);
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
          SnackBar(content: Text('Error loading mood history: $e')),
        );
      }
    }
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Okay';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Okay';
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen.shade600;
      case 5:
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  // Group entries by date
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

  // Filter entries by mood level
  List<MoodEntry> get _filteredEntries {
    if (_selectedMoodFilter == 0) return _moodEntries;
    return _moodEntries.where((e) => e.moodLevel == _selectedMoodFilter).toList();
  }

  // Delete mood entry
  Future<void> _deleteMoodEntry(String entryId) async {
    try {
      await _firestoreService.deleteMoodEntry(entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood entry deleted'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
        _loadMoodEntries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show delete confirmation
  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Entry',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to delete this mood entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Mood History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoodLogPage(),
                ),
              );
              if (result == true && mounted) {
                setState(() {});
              }
            },
            tooltip: 'Log Mood',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.black),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4CAF50),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF4CAF50),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          tabs: const [
            Tab(text: 'Grouped'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupedView(),
                _buildCalendarView(),
              ],
            ),
    );
  }

  Widget _buildMoodFilterBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 0, Icons.filter_list),
          const SizedBox(width: 8),
          _buildFilterChip('😞 Very Poor', 1, null),
          const SizedBox(width: 8),
          _buildFilterChip('😕 Poor', 2, null),
          const SizedBox(width: 8),
          _buildFilterChip('😐 Okay', 3, null),
          const SizedBox(width: 8),
          _buildFilterChip('🙂 Good', 4, null),
          const SizedBox(width: 8),
          _buildFilterChip('😄 Excellent', 5, null),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value, IconData? icon) {
    final isSelected = _selectedMoodFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
      selectedColor: const Color(0xFF4CAF50),
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setState(() {
          _selectedMoodFilter = value;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildGroupedView() {
    final grouped = _groupedEntries;
    
    if (grouped.isEmpty) {
      return _buildEmptyState();
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        // Mood filter bar (only in Grouped view)
        _buildMoodFilterBar(),
        
        // Grouped list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMoodEntries,
            color: const Color(0xFF4CAF50),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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

  Widget _buildDateGroup(DateTime date, List<MoodEntry> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);
    
    String dateLabel;
    if (entryDate == today) {
      dateLabel = 'Today';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM dd').format(date);
    }

    // Calculate average mood for the day
    final avgMood = entries.fold<int>(0, (sum, e) => sum + e.moodLevel) / entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMoodColor(avgMood.round()).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getMoodColor(avgMood.round()).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getMoodEmoji(avgMood.round()),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg: ${avgMood.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getMoodColor(avgMood.round()),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => _buildMoodEntryCard(entry, showDate: false)),
      ],
    );
  }

  Widget _buildCalendarView() {
    if (_moodEntries.isEmpty) {
      return _buildEmptyState();
    }

    // Group entries by date
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final now = DateTime.now();
                  final nextMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                  if (nextMonth.isBefore(now) || 
                      (nextMonth.year == now.year && nextMonth.month == now.month)) {
                    setState(() {
                      _selectedMonth = nextMonth;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // Calendar grid
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCalendarGrid(entriesByDate),
                  
                  const SizedBox(height: 24),
                  
                  // Legend
                  _buildCalendarLegend(),
                  
                  const SizedBox(height: 24),
                  
                  // Selected date entries
                  if (_selectedDate != null) ...[
                    _buildSelectedDateEntries(entriesByDate),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<MoodEntry>> entriesByDate) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((daysInMonth + firstWeekday) / 7).ceil() * 7;

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - firstWeekday + 1;
            
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
            final entries = entriesByDate[date] ?? [];
            final avgMood = entries.isEmpty
                ? null
                : entries.fold<int>(0, (sum, e) => sum + e.moodLevel) / entries.length;

            final isSelected = _selectedDate != null &&
                _selectedDate!.year == date.year &&
                _selectedDate!.month == date.month &&
                _selectedDate!.day == date.day;

            final isToday = DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            return GestureDetector(
              onTap: entries.isNotEmpty
                  ? () {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: avgMood != null
                      ? _getMoodColor(avgMood.round()).withOpacity(0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: avgMood != null
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                    if (entries.isNotEmpty)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _getMoodColor(avgMood!.round()),
                            shape: BoxShape.circle,
                          ),
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
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem('😞', 'Very Poor', Colors.red.shade400),
              _buildLegendItem('😕', 'Poor', Colors.orange.shade400),
              _buildLegendItem('😐', 'Okay', Colors.yellow.shade700),
              _buildLegendItem('🙂', 'Good', Colors.lightGreen.shade600),
              _buildLegendItem('😄', 'Excellent', Colors.green.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$emoji $label',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelectedDateEntries(Map<DateTime, List<MoodEntry>> entriesByDate) {
    final entries = entriesByDate[_selectedDate!] ?? [];
    
    if (entries.isEmpty) return const SizedBox.shrink();

    final avgMood = entries.fold<int>(0, (sum, e) => sum + e.moodLevel) / entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM dd').format(_selectedDate!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getMoodColor(avgMood.round()).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getMoodColor(avgMood.round()).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getMoodEmoji(avgMood.round()),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      avgMood.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _getMoodColor(avgMood.round()),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedMoodFilter == 0 ? Icons.mood : Icons.filter_alt_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedMoodFilter == 0 
                ? 'No mood entries yet'
                : 'No entries for this mood',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedMoodFilter == 0
                ? 'Start tracking your mood today!'
                : 'Try a different filter',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEntryCard(MoodEntry entry, {required bool showDate}) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Dismissible(
      key: Key(entry.entryId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteDialog(context),
      onDismissed: (direction) {
        _deleteMoodEntry(entry.entryId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoodEntryDetailPage(entry: entry),
                ),
              );
              
              if (result == true) {
                _loadMoodEntries(); // Reload if entry was edited
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and mood level
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getMoodColor(entry.moodLevel).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getMoodEmoji(entry.moodLevel),
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getMoodLabel(entry.moodLevel),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _getMoodColor(entry.moodLevel),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              showDate 
                                  ? '${dateFormat.format(entry.timestamp)} • ${timeFormat.format(entry.timestamp)}'
                                  : timeFormat.format(entry.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  
                  // Note
                  if (entry.note != null && entry.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  
                  // Emotion factors
                  if (entry.emotionFactors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.emotionFactors.take(4).map((factor) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF81C784).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            factor,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList()
                        ..addAll(
                          entry.emotionFactors.length > 4
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '+${entry.emotionFactors.length - 4}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
