import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';

class MoodAnalyticsPage extends StatefulWidget {
  const MoodAnalyticsPage({super.key});

  @override
  State<MoodAnalyticsPage> createState() => _MoodAnalyticsPageState();
}

class _MoodAnalyticsPageState extends State<MoodAnalyticsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<MoodEntry> _moodEntries = [];
  bool _isLoading = true;
  String _selectedPeriod = 'week'; // week, month, year

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

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

      final entries = await _firestoreService.getMoodEntriesForPeriod(
        userId: user.uid,
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
          SnackBar(content: Text('Error loading mood data: $e')),
        );
      }
    }
  }

  // Calculate average mood
  double get _averageMood {
    if (_moodEntries.isEmpty) return 0.0;
    final sum = _moodEntries.fold<int>(0, (sum, entry) => sum + entry.moodLevel);
    return sum / _moodEntries.length;
  }

  // Get mood distribution (count for each level)
  Map<int, int> get _moodDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var entry in _moodEntries) {
      distribution[entry.moodLevel] = (distribution[entry.moodLevel] ?? 0) + 1;
    }
    return distribution;
  }

  // Get most common emotion factors
  Map<String, int> get _emotionFactorFrequency {
    final frequency = <String, int>{};
    for (var entry in _moodEntries) {
      for (var factor in entry.emotionFactors) {
        frequency[factor] = (frequency[factor] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // Find best and worst day
  MoodEntry? get _bestDay {
    if (_moodEntries.isEmpty) return null;
    return _moodEntries.reduce((a, b) => a.moodLevel > b.moodLevel ? a : b);
  }

  MoodEntry? get _worstDay {
    if (_moodEntries.isEmpty) return null;
    return _moodEntries.reduce((a, b) => a.moodLevel < b.moodLevel ? a : b);
  }

  String _getMoodEmoji(int level) {
    switch (level) {
      case 1: return '😞';
      case 2: return '😕';
      case 3: return '😐';
      case 4: return '🙂';
      case 5: return '😄';
      default: return '😐';
    }
  }

  String _getMoodLabel(int level) {
    switch (level) {
      case 1: return 'Very Poor';
      case 2: return 'Poor';
      case 3: return 'Okay';
      case 4: return 'Good';
      case 5: return 'Excellent';
      default: return 'Okay';
    }
  }

  Color _getMoodColor(int level) {
    switch (level) {
      case 1: return Colors.red.shade400;
      case 2: return Colors.orange.shade400;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.lightGreen.shade600;
      case 5: return Colors.green.shade600;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mood Analytics',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 24),

                    // Overview cards
                    if (_moodEntries.isNotEmpty) ...[
                      _buildOverviewCards(),
                      const SizedBox(height: 24),

                      // Mood trend chart
                      _buildMoodTrendChart(),
                      const SizedBox(height: 24),

                      // Mood distribution
                      _buildMoodDistribution(),
                      const SizedBox(height: 24),

                      // Top emotion factors
                      _buildTopEmotionFactors(),
                      const SizedBox(height: 24),

                      // Best & Worst days
                      _buildBestWorstDays(),
                    ] else
                      _buildEmptyState(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('Year', 'year'),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Average Mood',
            value: _averageMood.toStringAsFixed(1),
            emoji: _getMoodEmoji(_averageMood.round()),
            color: _getMoodColor(_averageMood.round()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Entries',
            value: _moodEntries.length.toString(),
            emoji: '📊',
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String emoji,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(emoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _MoodLineChart(entries: _moodEntries),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution() {
    final distribution = _moodDistribution;
    final total = _moodEntries.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...distribution.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getMoodEmoji(entry.key),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getMoodLabel(entry.key),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value} (${(percentage * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey.shade200,
                      color: _getMoodColor(entry.key),
                      minHeight: 8,
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

  Widget _buildTopEmotionFactors() {
    final topFactors = _emotionFactorFrequency.entries.take(5).toList();
    
    if (topFactors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Influencing Factors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...topFactors.map((entry) {
            final maxCount = topFactors.first.value;
            final percentage = entry.value / maxCount;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF4CAF50),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
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

  Widget _buildBestWorstDays() {
    final best = _bestDay;
    final worst = _worstDay;

    if (best == null || worst == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Highlights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          title: 'Best Day',
          emoji: _getMoodEmoji(best.moodLevel),
          date: DateFormat('MMM dd, yyyy').format(best.timestamp),
          moodLevel: best.moodLevel,
          color: Colors.green.shade50,
          borderColor: Colors.green.shade200,
        ),
        const SizedBox(height: 12),
        _buildHighlightCard(
          title: 'Needs Attention',
          emoji: _getMoodEmoji(worst.moodLevel),
          date: DateFormat('MMM dd, yyyy').format(worst.timestamp),
          moodLevel: worst.moodLevel,
          color: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String emoji,
    required String date,
    required int moodLevel,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getMoodColor(moodLevel),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getMoodLabel(moodLevel),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No data for this period',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your mood to see analytics',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple Line Chart Widget
class _MoodLineChart extends StatelessWidget {
  final List<MoodEntry> entries;

  const _MoodLineChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    // Sort by date
    final sortedEntries = List<MoodEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return CustomPaint(
      painter: _LineChartPainter(sortedEntries),
      child: Container(),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MoodEntry> entries;

  _LineChartPainter(this.entries);

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height - (i * size.height / 5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Calculate points
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < entries.length; i++) {
      final x = (i / (entries.length - 1)) * size.width;
      final y = size.height - ((entries[i].moodLevel - 1) / 4) * size.height;
      
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 7, paint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) => true;
}
