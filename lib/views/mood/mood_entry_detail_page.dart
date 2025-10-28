import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';

class MoodEntryDetailPage extends StatefulWidget {
  final MoodEntry entry;

  const MoodEntryDetailPage({
    super.key,
    required this.entry,
  });

  @override
  State<MoodEntryDetailPage> createState() => _MoodEntryDetailPageState();
}

class _MoodEntryDetailPageState extends State<MoodEntryDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _noteController = TextEditingController();
  
  late int _selectedMoodLevel;
  late Set<String> _selectedFactors;
  bool _isEditing = false;
  bool _isSaving = false;

  final List<String> _emotionFactors = [
    'Work',
    'Family',
    'Health',
    'Relationships',
    'Sleep',
    'Exercise',
    'Social',
    'Money',
    'Weather',
    'Food',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMoodLevel = widget.entry.moodLevel;
    _selectedFactors = Set<String>.from(widget.entry.emotionFactors);
    _noteController.text = widget.entry.note ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      await _firestoreService.updateMoodEntry(
        widget.entry.entryId,
        {
          'moodLevel': _selectedMoodLevel,
          'note': _noteController.text.trim(),
          'emotionFactors': _selectedFactors.toList(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood entry updated successfully! 🎉'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating mood: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

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
          'Mood Entry',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing) ...[
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _saveChanges,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF4CAF50)),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Time Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateFormat.format(widget.entry.timestamp),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeFormat.format(widget.entry.timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mood Level
              const Text(
                'How were you feeling?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              if (_isEditing) ...[
                // Editable mood selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final level = index + 1;
                    final isSelected = _selectedMoodLevel == level;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMoodLevel = level),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? _getMoodColor(level).withOpacity(0.2)
                                  : Colors.grey.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? _getMoodColor(level)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getMoodEmoji(level),
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getMoodLabel(level).split(' ').last,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected 
                                  ? _getMoodColor(level)
                                  : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ] else ...[
                // Display mood
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _getMoodColor(_selectedMoodLevel).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getMoodColor(_selectedMoodLevel).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getMoodEmoji(_selectedMoodLevel),
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getMoodLabel(_selectedMoodLevel),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _getMoodColor(_selectedMoodLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Notes
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _noteController,
                  enabled: _isEditing,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: _isEditing ? 'Add a note...' : 'No notes',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    color: _isEditing ? Colors.black : Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Emotion Factors
              const Text(
                'What influenced your mood?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _emotionFactors.map((factor) {
                  final isSelected = _selectedFactors.contains(factor);
                  return GestureDetector(
                    onTap: _isEditing ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedFactors.remove(factor);
                        } else {
                          _selectedFactors.add(factor);
                        }
                      });
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF81C784).withOpacity(0.3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        factor,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected 
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
