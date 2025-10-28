import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/mood_entry.dart';
import '../../services/firestore_service.dart';

class MoodLogPage extends StatefulWidget {
  const MoodLogPage({super.key});

  @override
  State<MoodLogPage> createState() => _MoodLogPageState();
}

class _MoodLogPageState extends State<MoodLogPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _noteController = TextEditingController();
  
  int _selectedMoodLevel = 3; // Default: Okay
  final Set<String> _selectedFactors = {};
  bool _isSaving = false;

  // Mood levels with emojis
  final List<Map<String, dynamic>> _moodLevels = [
    {'level': 1, 'emoji': '😞', 'label': 'Very Poor'},
    {'level': 2, 'emoji': '😕', 'label': 'Poor'},
    {'level': 3, 'emoji': '😐', 'label': 'Okay'},
    {'level': 4, 'emoji': '🙂', 'label': 'Good'},
    {'level': 5, 'emoji': '😄', 'label': 'Excellent'},
  ];

  // Emotion factors
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
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMoodEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final moodEntry = MoodEntry(
        entryId: '', // Firestore will generate
        userId: user.uid,
        moodLevel: _selectedMoodLevel,
        note: _noteController.text.trim(),
        emotionFactors: _selectedFactors.toList(),
        tags: [], // Can add tags later
        timestamp: DateTime.now(),
      );

      await _firestoreService.createMoodEntry(moodEntry);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood logged successfully! 🎉'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving mood: $e'),
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
          'Mood Log',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
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
              onPressed: _saveMoodEntry,
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
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question
              const Text(
                'How are you feeling\ntoday?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),

              // Mood selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _moodLevels.map((mood) {
                  final isSelected = _selectedMoodLevel == mood['level'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMoodLevel = mood['level']),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF81C784).withOpacity(0.2)
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? const Color(0xFF4CAF50)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              mood['emoji'],
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          mood['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected 
                                ? const Color(0xFF4CAF50)
                                : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // Notes section
              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 32),

              // What's influencing your mood
              const Text(
                'What\'s influencing your mood?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _emotionFactors.map((factor) {
                  final isSelected = _selectedFactors.contains(factor);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFactors.remove(factor);
                        } else {
                          _selectedFactors.add(factor);
                        }
                      });
                    },
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
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }
}
