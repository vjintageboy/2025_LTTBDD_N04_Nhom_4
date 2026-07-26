import 'dart:convert';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meditation.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_source.dart';
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
  String? _thumbnailData; // base64 of the picked cover image, null if none

  MeditationCategory _selectedCategory = MeditationCategory.stress;
  MeditationLevel _selectedLevel = MeditationLevel.beginner;
  bool _isSaving = false;

  final ap.AudioPlayer _previewPlayer = ap.AudioPlayer();
  bool _isPreviewPlaying = false;

  @override
  void initState() {
    super.initState();
    _previewPlayer.onPlayerComplete.listen(
      (_) {
        if (mounted) setState(() => _isPreviewPlaying = false);
      },
      // audioplayers surfaces web media errors (unreachable URL / unsupported
      // format) through this stream; without onError they become uncaught
      // async errors.
      onError: (Object _) {
        if (!mounted) return;
        setState(() => _isPreviewPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không phát được link này (định dạng/nguồn không hỗ trợ trên web)',
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _audioUrlController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  String? _validateAudioUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // optional
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      return 'URL phải bắt đầu bằng http:// hoặc https://';
    }
    return null;
  }

  Future<void> _pickThumbnail() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _thumbnailData = base64Encode(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _togglePreview() async {
    final url = _audioUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có đường dẫn âm thanh')),
      );
      return;
    }
    if (_isPreviewPlaying) {
      await _previewPlayer.stop();
      if (mounted) setState(() => _isPreviewPlaying = false);
      return;
    }
    try {
      await _previewPlayer.play(ap.UrlSource(url));
      if (mounted) setState(() => _isPreviewPlaying = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không phát được: $e')),
        );
      }
    }
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
        'thumbnail_url': _thumbnailData,
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

            // Audio URL — kept as a URL: playback streams via UrlSource, and
            // base64 is the wrong tool for multi-MB mp3s.
            TextFormField(
              controller: _audioUrlController,
              style: GoogleFonts.manrope(color: AppColors.osOnSurface),
              decoration: osFieldDecoration(
                label: 'Đường dẫn âm thanh (tùy chọn)',
                hint: 'https://example.com/audio.mp3',
                icon: IconsaxPlusLinear.music,
              ),
              validator: _validateAudioUrl,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _togglePreview,
                icon: Icon(
                  _isPreviewPlaying
                      ? IconsaxPlusLinear.pause
                      : IconsaxPlusLinear.play,
                  size: 18,
                  color: AppColors.osPrimary,
                ),
                label: Text(
                  _isPreviewPlaying ? 'Dừng' : 'Nghe thử',
                  style: GoogleFonts.manrope(
                    color: AppColors.osPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cover image — pick from gallery, stored as base64 (like avatars/
            // posts/mood), so no Storage bucket is needed.
            _buildThumbnailPicker(),
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

  Widget _buildThumbnailPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ảnh bìa (tùy chọn)',
          style: GoogleFonts.manrope(
            color: AppColors.osOnSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_thumbnailData != null && _thumbnailData!.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image(
                    image: imageProviderFromSource(_thumbnailData!),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _thumbnailData = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: _pickThumbnail,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.osSurfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  IconsaxPlusLinear.gallery,
                  color: AppColors.osPrimary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _thumbnailData == null ? 'Chọn ảnh bìa' : 'Đổi ảnh khác',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.osPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
