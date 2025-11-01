import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/streak.dart';
import 'streak_debug_page.dart';

class StreakHistoryPage extends StatefulWidget {
  const StreakHistoryPage({super.key});

  @override
  State<StreakHistoryPage> createState() => _StreakHistoryPageState();
}

class _StreakHistoryPageState extends State<StreakHistoryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Streak? _streak;
  List<DateTime> _activityDates = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Recalculate streak first to ensure accuracy
      await _firestoreService.recalculateStreak(user.uid);
      
      // Then load streak data and activity dates
      final results = await Future.wait([
        _firestoreService.getOrCreateStreak(user.uid),
        _firestoreService.getUserActivityDates(user.uid),
      ]);

      if (mounted) {
        setState(() {
          _streak = results[0] as Streak;
          _activityDates = results[1] as List<DateTime>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading streak: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Streak History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Debug tools button
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StreakDebugPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : RefreshIndicator(
              onRefresh: _loadStreakData,
              color: const Color(0xFF4CAF50),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildStreakStats(),
                    const SizedBox(height: 16),
                    _buildCalendarSection(),
                    const SizedBox(height: 24),
                    _buildStreakTips(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStreakStats() {
    final currentStreak = _streak?.currentStreak ?? 0;
    final longestStreak = _streak?.longestStreak ?? 0;
    final totalActivities = _streak?.totalActivities ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '🔥',
                  '$currentStreak',
                  'Current Streak',
                  'days',
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  '🏆',
                  '$longestStreak',
                  'Longest Streak',
                  'days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$totalActivities total activities',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentStreak > 0
                        ? 'Keep it up! Come back tomorrow'
                        : 'Start your streak today!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label, String unit) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.all(16),
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
                        (nextMonth.year == now.year &&
                            nextMonth.month == now.month)) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildCalendarGrid(),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;
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
            final hasActivity = _activityDates.any((d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day);

            final isToday = DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            final isFuture = date.isAfter(DateTime.now());

            return Container(
              decoration: BoxDecoration(
                color: hasActivity
                    ? const Color(0xFF4CAF50)
                    : isFuture
                        ? Colors.grey.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday ? Colors.blue.shade400 : Colors.transparent,
                  width: isToday ? 2 : 0,
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
                        color: hasActivity
                            ? Colors.white
                            : isFuture
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (hasActivity)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              _buildLegendItem(const Color(0xFF4CAF50), 'Activity'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.grey.shade200, 'No Activity'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.grey.shade100, 'Future'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tips to Maintain Streak',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Log your mood daily to build consistency'),
          _buildTipItem('Complete meditation sessions regularly'),
          _buildTipItem('Set daily reminders to check in with yourself'),
          _buildTipItem('Streak resets if you miss a day'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
