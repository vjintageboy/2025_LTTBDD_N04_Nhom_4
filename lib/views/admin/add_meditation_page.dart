import 'package:flutter/material.dart';
import '../../models/meditation.dart';
import '../../services/firestore_service.dart';

/// Add Meditation Page - Trang thêm meditation mới (Admin only)
class AddMeditationPage extends StatefulWidget {
  const AddMeditationPage({super.key});

  @override
  State<AddMeditationPage> createState() => _AddMeditationPageState();
}

class _AddMeditationPageState extends State<AddMeditationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _thumbnailUrlController = TextEditingController();
  
  MeditationCategory _selectedCategory = MeditationCategory.stress;
  MeditationLevel _selectedLevel = MeditationLevel.beginner;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _audioUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveMeditation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final meditationId = 'med_${DateTime.now().millisecondsSinceEpoch}';
      
      final meditation = Meditation(
        meditationId: meditationId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        duration: int.parse(_durationController.text),
        category: _selectedCategory,
        level: _selectedLevel,
        audioUrl: _audioUrlController.text.trim().isEmpty 
            ? null 
            : _audioUrlController.text.trim(),
        thumbnailUrl: _thumbnailUrlController.text.trim().isEmpty 
            ? null 
            : _thumbnailUrlController.text.trim(),
        rating: 0.0,
        totalReviews: 0,
      );

      await FirestoreService().createMeditation(meditation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meditation created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add New Meditation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g., Morning Gratitude',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe this meditation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Duration
            TextFormField(
              controller: _durationController,
              decoration: InputDecoration(
                labelText: 'Duration (minutes) *',
                hintText: 'e.g., 10',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.schedule),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter duration';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<MeditationCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
              items: MeditationCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryLabel(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Level
            DropdownButtonFormField<MeditationLevel>(
              value: _selectedLevel,
              decoration: InputDecoration(
                labelText: 'Level *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.bar_chart),
              ),
              items: MeditationLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Text(_getLevelLabel(level)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLevel = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Audio URL
            TextFormField(
              controller: _audioUrlController,
              decoration: InputDecoration(
                labelText: 'Audio URL (optional)',
                hintText: 'https://example.com/audio.mp3',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.audiotrack),
              ),
            ),
            const SizedBox(height: 16),

            // Thumbnail URL
            TextFormField(
              controller: _thumbnailUrlController,
              decoration: InputDecoration(
                labelText: 'Thumbnail URL (optional)',
                hintText: 'https://example.com/image.jpg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.image),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeditation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Meditation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.stress:
        return 'Stress Relief';
      case MeditationCategory.anxiety:
        return 'Anxiety';
      case MeditationCategory.sleep:
        return 'Sleep';
      case MeditationCategory.focus:
        return 'Focus';
    }
  }

  String _getLevelLabel(MeditationLevel level) {
    switch (level) {
      case MeditationLevel.beginner:
        return 'Beginner';
      case MeditationLevel.intermediate:
        return 'Intermediate';
      case MeditationLevel.advanced:
        return 'Advanced';
    }
  }
}
