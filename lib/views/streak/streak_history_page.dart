import '../../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';
import '../../models/streak.dart';

class StreakHistoryPage extends StatefulWidget {
  const StreakHistoryPage({super.key});

  @override
  State<StreakHistoryPage> createState() => _StreakHistoryPageState();
}

class _StreakHistoryPageState extends State<StreakHistoryPage> {
  final _supabaseService = SupabaseService.instance;
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
    final user = _supabaseService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.recalculateStreak(user.id);

      final streak = await _supabaseService.getStreak(user.id);
      final moodEntries = await _supabaseService.getMoodEntries(user.id);

      if (mounted) {
        setState(() {
          _streak = streak;
          _activityDates = moodEntries.map((e) => e.timestamp).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.streakHistoryTitle,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.osPrimary),
            )
          : RefreshIndicator(
              onRefresh: _loadStreakData,
              color: AppColors.osPrimary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 24),
                  _buildStreakStats(),
                  const SizedBox(height: 24),
                  _buildCalendarSection(),
                  const SizedBox(height: 24),
                  _buildStreakTips(),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakStats() {
    final l10n = context.l10n;
    final currentStreak = _streak?.currentStreak ?? 0;
    final longestStreak = _streak?.longestStreak ?? 0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.osPrimary.withValues(alpha: 0.3),
            blurRadius: 48,
            offset: const Offset(0, 24),
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
                  l10n.currentStreak,
                  l10n.daysUnit,
                ),
              ),
              // Tonal separator instead of hard line
              Container(
                width: 1,
                height: 80,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  '🏆',
                  '$longestStreak',
                  l10n.longestStreak,
                  l10n.daysUnit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Motivational message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  currentStreak > 0
                      ? PhosphorIconsRegular.fire
                      : IconsaxPlusLinear.magicpen,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    currentStreak > 0
                        ? l10n.keepItUp
                        : l10n.startYourStreak,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(IconsaxPlusLinear.arrow_left_2, color: Colors.grey.shade600),
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
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: Icon(IconsaxPlusLinear.arrow_right_3, color: Colors.grey.shade600),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildCalendarGrid(),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
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
    final firstWeekday = (firstDayOfMonth.weekday % 7);
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
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              )
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
            final hasActivity = _activityDates.any(
              (d) =>
                  d.year == date.year &&
                  d.month == date.month &&
                  d.day == date.day,
            );

            final isToday =
                DateTime.now().year == date.year &&
                DateTime.now().month == date.month &&
                DateTime.now().day == date.day;

            final isFuture = date.isAfter(DateTime.now());

            return Container(
              decoration: BoxDecoration(
                color: hasActivity
                    ? AppColors.osPrimary
                    : isFuture
                    ? Colors.grey.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: isToday
                    ? Border.all(
                        color: const Color(0xFF60A5FA),
                        width: 2.5,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: hasActivity
                            ? Colors.white
                            : isFuture
                            ? Colors.grey.shade300
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  if (hasActivity)
                    Positioned(
                      top: 4,
                      right: 4,
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
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.legend,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _buildLegendItem(AppColors.osPrimary, l10n.hasActivity),
              _buildLegendItem(Colors.grey.shade100, l10n.noActivity),
              _buildLegendItem(Colors.grey.shade50, l10n.future),
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
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakTips() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.osPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  IconsaxPlusLinear.lamp_on,
                  color: AppColors.osPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                l10n.streakTips,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTipItem(l10n.tipDailyMood),
          _buildTipItem(l10n.tipMeditation),
          _buildTipItem(l10n.tipDailyReminder),
          _buildTipItem(l10n.tipStreakReset),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot indicator
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.osPrimary,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
