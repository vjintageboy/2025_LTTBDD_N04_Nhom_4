import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/mood_entry.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';
import '../../services/supabase_service.dart';

class MoodLogPage extends StatefulWidget {
  final int? initialMoodLevel;

  const MoodLogPage({super.key, this.initialMoodLevel});

  @override
  State<MoodLogPage> createState() => _MoodLogPageState();
}

class _MoodLogPageState extends State<MoodLogPage> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _noteController = TextEditingController();

  late int _selectedMoodLevel;
  final Set<String> _selectedFactors = {};
  bool _isSaving = false;
  String? _imageUrl; // base64 of an attached photo, null if none

  static const Color _kBg = Color(0xFFDBFCDF);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x0F0B361D),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  // Emojis matching home page
  static const List<String> _emojis = ['😢', '🙁', '😐', '😊', '🤩'];

  @override
  void initState() {
    super.initState();
    _selectedMoodLevel = widget.initialMoodLevel ?? 3;
  }

  List<Map<String, dynamic>> get _moodLevels => [
    {
      'level': 1,
      'emoji': '😢',
      'labelKey': 'moodVeryBad',
      'color': const Color(0xFF6366F1),
    },
    {
      'level': 2,
      'emoji': '🙁',
      'labelKey': 'moodBad',
      'color': const Color(0xFF60A5FA),
    },
    {
      'level': 3,
      'emoji': '😐',
      'labelKey': 'moodNeutral',
      'color': const Color(0xFF94A3B8),
    },
    {
      'level': 4,
      'emoji': '😊',
      'labelKey': 'good',
      'color': const Color(0xFFFBBF24),
    },
    {
      'level': 5,
      'emoji': '🤩',
      'labelKey': 'moodExcellent',
      'color': const Color(0xFFFCA5A1),
    },
  ];

  List<Map<String, dynamic>> get _emotionFactors => [
    {'key': 'work', 'icon': IconsaxPlusLinear.briefcase, 'labelKey': 'work'},
    {'key': 'family', 'icon': IconsaxPlusLinear.profile_2user, 'labelKey': 'family'},
    {'key': 'health', 'icon': IconsaxPlusBold.heart, 'labelKey': 'health'},
    {'key': 'relationships', 'icon': IconsaxPlusLinear.people, 'labelKey': 'relationships'},
    {'key': 'sleep', 'icon': IconsaxPlusLinear.moon, 'labelKey': 'sleep'},
    {'key': 'food', 'icon': IconsaxPlusLinear.document, 'labelKey': 'food'},
    {'key': 'exercise', 'icon': IconsaxPlusBold.star, 'labelKey': 'exercise'},
    {'key': 'social', 'icon': IconsaxPlusLinear.global, 'labelKey': 'social'},
    {'key': 'money', 'icon': IconsaxPlusLinear.card, 'labelKey': 'money'},
    {'key': 'weather', 'icon': IconsaxPlusLinear.cloud, 'labelKey': 'weather'},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;
      // base64 in the image_url column, same as post/avatar images.
      // XFile.readAsBytes() works on web too (dart:io File would throw there).
      final bytes = await picked.readAsBytes();
      setState(() => _imageUrl = base64Encode(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveMoodEntry() async {
    final user = _supabaseService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final moodEntry = MoodEntry(
        entryId: '',
        userId: user.id,
        moodLevel: _selectedMoodLevel,
        note: _noteController.text.trim(),
        emotionFactors: _selectedFactors.toList(),
        tags: [],
        timestamp: DateTime.now(),
        imageUrl: _imageUrl,
      );

      await _supabaseService.createMoodEntry(moodEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.moodLoggedSuccess),
            backgroundColor: AppColors.osPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorSavingMood(e.toString())),
            backgroundColor: AppColors.osError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left),
          color: AppColors.osOnSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.moodTrackerTitle,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.4,
            color: AppColors.osOnSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.osPrimary,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _saveMoodEntry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.osPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  l10n.save,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          _buildHeroSection(),
          const SizedBox(height: 28),
          _buildMoodSelector(),
          const SizedBox(height: 24),
          _buildContextualFactors(),
          const SizedBox(height: 24),
          _buildNotesSection(),
          const SizedBox(height: 32),
          _buildQuoteCard(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final l10n = context.l10n;
    return Column(
      children: [
        Text(
          l10n.howAreYouFeelingHero,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.5,
            color: AppColors.osOnSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.moodHeroSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: _moodLevels.map((mood) {
          final isSelected = _selectedMoodLevel == mood['level'];
          final moodColor = mood['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMoodLevel = mood['level']),
              child: _MoodEmojiItem(
                emoji: mood['emoji'] as String,
                label: _getLocalizedMoodLabel(context, mood['labelKey']),
                isSelected: isSelected,
                moodColor: moodColor,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContextualFactors() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.factorsWhatAffect,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.osOnSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _emotionFactors.map((factor) {
            final key = factor['key']!;
            final icon = factor['icon']! as IconData;
            final labelKey = factor['labelKey']!;
            final isSelected = _selectedFactors.contains(key);
            return _FactorChip(
              icon: icon,
              label: _getLocalizedFactorLabel(context, labelKey),
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFactors.remove(key);
                  } else {
                    _selectedFactors.add(key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notesToday,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.osOnSurface,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.osSurfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _cardShadow,
          ),
          child: TextField(
            controller: _noteController,
            maxLines: null,
            minLines: 4,
            cursorColor: AppColors.osPrimary,
            style: GoogleFonts.manrope(
              fontSize: 15,
              color: AppColors.osOnSurface,
            ),
            decoration: InputDecoration(
              hintText: l10n.notesPlaceholder,
              hintStyle: GoogleFonts.manrope(
                color: AppColors.osOnSurfaceVariant,
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: _buildNoteAction(
                  IconsaxPlusLinear.gallery,
                  onTap: _pickImage,
                ),
              ),
            ),
          ),
        ),
        if (_imageUrl != null) ...[
          const SizedBox(height: 12),
          _buildImagePreview(),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.memory(
              base64Decode(_imageUrl!),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _imageUrl = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteAction(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.osSurfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.osOnSurfaceVariant),
      ),
    );
  }

  Widget _buildQuoteCard() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.osPrimary.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            IconsaxPlusLinear.quote_up,
            size: 40,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.dailyInspirationQuote,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 28,
                height: 2,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.quoteInspirationLabel,
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedMoodLabel(BuildContext context, String labelKey) {
    final l10n = context.l10n;
    switch (labelKey) {
      case 'moodVeryBad': return l10n.moodVeryBad;
      case 'moodBad': return l10n.moodBad;
      case 'moodNeutral': return l10n.moodNeutral;
      case 'good': return l10n.good;
      case 'moodExcellent': return l10n.moodExcellent;
      default: return '';
    }
  }

  String _getLocalizedFactorLabel(BuildContext context, String labelKey) {
    final l10n = context.l10n;
    switch (labelKey) {
      case 'work': return l10n.work;
      case 'family': return l10n.family;
      case 'health': return l10n.health;
      case 'relationships': return l10n.relationships;
      case 'sleep': return l10n.sleep;
      case 'food': return l10n.food;
      case 'exercise': return l10n.exercise;
      case 'social': return l10n.social;
      case 'money': return l10n.money;
      case 'weather': return l10n.weather;
      default: return labelKey;
    }
  }
}

class _MoodEmojiItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final Color moodColor;

  const _MoodEmojiItem({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.moodColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: isSelected ? 60 : 52,
          height: isSelected ? 60 : 52,
          decoration: BoxDecoration(
            color: isSelected
                ? moodColor.withValues(alpha: 0.12)
                : AppColors.osSurfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: isSelected
                ? Border.all(color: moodColor.withValues(alpha: 0.3), width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: isSelected ? 30 : 26),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? moodColor : AppColors.osOnSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FactorChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FactorChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.osPrimary.withValues(alpha: 0.08)
              : AppColors.osSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.osPrimary
                : AppColors.osSurfaceContainerHighest,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.osPrimary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.osPrimary
                  : AppColors.osOnSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppColors.osPrimary
                    : AppColors.osOnSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
