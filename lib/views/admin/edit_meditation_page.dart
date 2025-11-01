import 'package:flutter/material.dart';
import '../../models/meditation.dart';
import '../../services/firestore_service.dart';

/// Edit Meditation Page - Trang chỉnh sửa meditation (Admin only)
class EditMeditationPage extends StatefulWidget {
  final Meditation meditation;

  const EditMeditationPage({
    super.key,
    required this.meditation,
  });

  @override
  State<EditMeditationPage> createState() => _EditMeditationPageState();
}

class _EditMeditationPageState extends State<EditMeditationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
  late TextEditingController _audioUrlController;
  late TextEditingController _thumbnailUrlController;
  
  late MeditationCategory _selectedCategory;
  late MeditationLevel _selectedLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meditation.title);
    _descriptionController = TextEditingController(text: widget.meditation.description);
    _durationController = TextEditingController(text: widget.meditation.duration.toString());
    _audioUrlController = TextEditingController(text: widget.meditation.audioUrl ?? '');
    _thumbnailUrlController = TextEditingController(text: widget.meditation.thumbnailUrl ?? '');
    _selectedCategory = widget.meditation.category;
    _selectedLevel = widget.meditation.level;
  }

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
      final updates = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration': int.parse(_durationController.text),
        'category': _selectedCategory.toString().split('.').last,
        'level': _selectedLevel.toString().split('.').last,
        'audioUrl': _audioUrlController.text.trim().isEmpty 
            ? null 
            : _audioUrlController.text.trim(),
        'thumbnailUrl': _thumbnailUrlController.text.trim().isEmpty 
            ? null 
            : _thumbnailUrlController.text.trim(),
      };

      await FirestoreService().updateMeditation(
        widget.meditation.meditationId,
        updates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meditation updated successfully!'),
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
          'Edit Meditation',
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
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meditation ID: ${widget.meditation.meditationId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rating: ${widget.meditation.rating.toStringAsFixed(1)} ★ (${widget.meditation.totalReviews} reviews)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                      'Save Changes',
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
