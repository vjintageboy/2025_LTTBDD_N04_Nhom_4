import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meditation.dart';
import '../../core/constants/app_colors.dart';
import 'admin_form_styles.dart';

/// Add Meditation Page - Trang thêm meditation mới (Admin only)
class AddMeditationPage extends StatefulWidget {
  const AddMeditationPage({super.key});

  @override
  State<AddMeditationPage> createState() => _AddMeditationPageState();
}

class _AddMeditationPageState extends State<AddMeditationPage> {
  final _supabase = Supabase.instance.client;
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
      await _supabase.from('meditations').insert({
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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạo bài thiền mới!'),
            backgroundColor: AppColors.osPrimary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.osError,
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
      backgroundColor: AppColors.osSurface,
      appBar: AppBar(
        title: Text(
          'Thêm bài thiền mới',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.osOnSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: AppColors.osSurface,
        foregroundColor: AppColors.osOnSurface,
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
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Tiêu đề *',
                hint: 'VD: Biết ơn buổi sáng',
                icon: IconsaxPlusLinear.text,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
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
                label: 'Mô tả *',
                hint: 'Mô tả bài thiền này...',
                icon: IconsaxPlusLinear.document,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả';
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
                label: 'Thời lượng (phút) *',
                hint: 'VD: 10',
                icon: IconsaxPlusLinear.clock,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập thời lượng';
                }
                if (int.tryParse(value) == null) {
                  return 'Vui lòng nhập số hợp lệ';
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
                label: 'Danh mục *',
                icon: IconsaxPlusLinear.category,
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
                label: 'Cấp độ *',
                icon: IconsaxPlusLinear.chart_2,
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
                label: 'Đường dẫn âm thanh (tùy chọn)',
                hint: 'https://example.com/audio.mp3',
                icon: IconsaxPlusLinear.music,
              ),
            ),
            const SizedBox(height: 16),

            // Thumbnail URL
            TextFormField(
              controller: _thumbnailUrlController,
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Đường dẫn ảnh bìa (tùy chọn)',
                hint: 'https://example.com/image.jpg',
                icon: IconsaxPlusLinear.gallery,
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
                      'Tạo bài thiền',
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
        return 'Căng thẳng';
      case MeditationCategory.anxiety:
        return 'Lo âu';
      case MeditationCategory.sleep:
        return 'Giấc ngủ';
      case MeditationCategory.focus:
        return 'Tập trung';
    }
  }

  String _getLevelLabel(MeditationLevel level) {
    switch (level) {
      case MeditationLevel.beginner:
        return 'Cơ bản';
      case MeditationLevel.intermediate:
        return 'Trung cấp';
      case MeditationLevel.advanced:
        return 'Nâng cao';
    }
  }
}
