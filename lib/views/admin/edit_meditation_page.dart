import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meditation.dart';
import '../../core/constants/app_colors.dart';
import 'admin_form_styles.dart';

/// Edit Meditation Page - Trang chỉnh sửa meditation (Admin only)
class EditMeditationPage extends StatefulWidget {
  final Meditation meditation;

  const EditMeditationPage({super.key, required this.meditation});

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

  final _supabase = Supabase.instance.client;
  late MeditationCategory _selectedCategory;
  late MeditationLevel _selectedLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meditation.title);
    _descriptionController = TextEditingController(
      text: widget.meditation.description,
    );
    _durationController = TextEditingController(
      text: widget.meditation.duration.toString(),
    );
    _audioUrlController = TextEditingController(
      text: widget.meditation.audioUrl ?? '',
    );
    _thumbnailUrlController = TextEditingController(
      text: widget.meditation.thumbnailUrl ?? '',
    );
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
        'duration_minutes': int.parse(_durationController.text),
        'category': _selectedCategory.toString().split('.').last,
        'audio_url': _audioUrlController.text.trim().isEmpty
            ? null
            : _audioUrlController.text.trim(),
        'thumbnail_url': _thumbnailUrlController.text.trim().isEmpty
            ? null
            : _thumbnailUrlController.text.trim(),
      };

      await _supabase
          .from('meditations')
          .update(updates)
          .eq('id', widget.meditation.meditationId);

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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      backgroundColor: AppColors.osSurface,
      appBar: AppBar(
        title: Text(
          'Edit meditation',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.osPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
            ),
          ),
        ),
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
                color: AppColors.osSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.osOnPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meditation ID: ${widget.meditation.meditationId}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.osOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rating: ${widget.meditation.rating.toStringAsFixed(1)} ★ (${widget.meditation.totalReviews} reviews)',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.osOnSurfaceVariant,
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
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Title *',
                hint: 'e.g., Morning Gratitude',
                icon: Icons.title,
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
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Description *',
                hint: 'Describe this meditation...',
                icon: Icons.description,
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
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Duration (minutes) *',
                hint: 'e.g., 10',
                icon: Icons.schedule,
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
              initialValue: _selectedCategory,
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Category *',
                icon: Icons.category,
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
              initialValue: _selectedLevel,
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Level *',
                icon: Icons.bar_chart,
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
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Audio URL (optional)',
                hint: 'https://example.com/audio.mp3',
                icon: Icons.audiotrack,
              ),
            ),
            const SizedBox(height: 16),

            // Thumbnail URL
            TextFormField(
              controller: _thumbnailUrlController,
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Thumbnail URL (optional)',
                hint: 'https://example.com/image.jpg',
                icon: Icons.image,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMeditation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.osPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
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
                  : Text(
                      'Save changes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
