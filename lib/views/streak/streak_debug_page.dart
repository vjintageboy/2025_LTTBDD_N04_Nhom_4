import 'package:flutter/material.dart';
import '../../scripts/create_streak_test_data.dart';

class StreakDebugPage extends StatefulWidget {
  const StreakDebugPage({super.key});

  @override
  State<StreakDebugPage> createState() => _StreakDebugPageState();
}

class _StreakDebugPageState extends State<StreakDebugPage> {
  bool _isLoading = false;
  String _status = 'Ready';

  Future<void> _createTestData(int days) async {
    setState(() {
      _isLoading = true;
      _status = 'Creating $days days of test data...';
    });

    try {
      await StreakTestDataGenerator.createStreakTestData(days: days);
      setState(() {
        _status = '✅ Created $days consecutive mood entries!\nExpected streak: $days days';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Deleting test data...';
    });

    try {
      await StreakTestDataGenerator.deleteTestData();
      setState(() {
        _status = '✅ Test data deleted!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Warning'),
        content: const Text('This will delete ALL your mood entries and reset streak to 0. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
        _status = 'Deleting all data...';
      });

      try {
        await StreakTestDataGenerator.deleteAllMoodEntries();
        setState(() {
          _status = '✅ All data deleted and streak reset!';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _status = '❌ Error: $e';
          _isLoading = false;
        });
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
          'Streak Debug Tools',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            Container(
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
                children: [
                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  const SizedBox(height: 16),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create test data section
            _buildSectionTitle('Create Test Data'),
            const SizedBox(height: 12),
            _buildButton(
              'Create 29 Days Streak',
              '29 consecutive days',
              Colors.blue,
              () => _createTestData(29),
            ),
            const SizedBox(height: 12),
            _buildButton(
              'Create 7 Days Streak',
              'One week',
              Colors.green,
              () => _createTestData(7),
            ),
            const SizedBox(height: 12),
            _buildButton(
              'Create 100 Days Streak',
              'For testing longest streak',
              Colors.purple,
              () => _createTestData(100),
            ),
            const SizedBox(height: 24),

            // Delete section
            _buildSectionTitle('Delete Data'),
            const SizedBox(height: 12),
            _buildButton(
              'Delete Test Data Only',
              'Removes entries with test_data tag',
              Colors.orange,
              _deleteTestData,
            ),
            const SizedBox(height: 12),
            _buildButton(
              'Delete ALL Data',
              '⚠️ Deletes everything and resets streak',
              Colors.red,
              _deleteAllData,
            ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'How to Test',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInstruction('1. Click "Create 29 Days Streak"'),
                  _buildInstruction('2. Wait for completion message'),
                  _buildInstruction('3. Go to Home or Streak History'),
                  _buildInstruction('4. Check streak values'),
                  _buildInstruction('5. Delete test data when done'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildButton(
    String title,
    String subtitle,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: _isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.science, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
