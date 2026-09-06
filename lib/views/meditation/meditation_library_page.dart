import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/image_source.dart';
import '../../models/meditation.dart';
import '../../services/supabase_service.dart';
import 'meditation_detail_page.dart';

/// Meditation Library Page - Browse all meditations with search & filter
class MeditationLibraryPage extends StatefulWidget {
  const MeditationLibraryPage({super.key});

  @override
  State<MeditationLibraryPage> createState() => _MeditationLibraryPageState();
}

class _MeditationLibraryPageState extends State<MeditationLibraryPage> {
  final _supabaseService = SupabaseService.instance;
  List<Meditation> _allMeditations = [];
  List<Meditation> _filteredMeditations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  MeditationCategory? _selectedCategory;
  String _sortBy = 'rating'; // rating, duration, title

  // Tonal accents for meditation categories, kept within the app's green/teal family.
  Color _getCategoryColor(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.stress:
        return AppColors.osPrimary;
      case MeditationCategory.anxiety:
        return AppColors.osTertiary;
      case MeditationCategory.sleep:
        return AppColors.osSecondary;
      case MeditationCategory.focus:
        return AppColors.osPrimaryDim;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }

  Future<void> _loadMeditations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final data = await _supabaseService.getMeditations();
      final meditations = data.map((m) => Meditation.fromMap(m)).toList();

      if (mounted) {
        setState(() {
          _allMeditations = meditations;
          _filteredMeditations = meditations;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error loading meditations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meditations: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMeditations = _allMeditations.where((meditation) {
        // Search filter
        final matchesSearch =
            _searchQuery.isEmpty ||
            meditation.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            meditation.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        // Category filter
        final matchesCategory =
            _selectedCategory == null ||
            meditation.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();

      // Sort
      switch (_sortBy) {
        case 'rating':
          _filteredMeditations.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'duration':
          _filteredMeditations.sort((a, b) => a.duration.compareTo(b.duration));
          break;
        case 'title':
          _filteredMeditations.sort((a, b) => a.title.compareTo(b.title));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 64),

          // Search & Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildSortRow(),
              ],
            ),
          ),

          // Results Count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filteredMeditations.length} ${_filteredMeditations.length != 1 ? context.l10n.meditationsFound : context.l10n.meditationFound}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.osOnSurfaceVariant,
                  ),
                ),
              ),
            ),

          // Meditation Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.osPrimary),
                  )
                : _filteredMeditations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMeditations,
                    color: AppColors.osPrimary,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredMeditations.length,
                      itemBuilder: (context, index) {
                        return _buildMeditationCard(_filteredMeditations[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.osSurface.withValues(alpha: 0.80),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(IconsaxPlusLinear.arrow_left),
                        color: AppColors.osOnSurface,
                        splashRadius: 22,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.meditationLibrary,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.osOnSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        _searchQuery = value;
        _applyFilters();
      },
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.osOnSurface,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.searchMeditations,
        hintStyle: GoogleFonts.manrope(
          fontSize: 15,
          color: AppColors.osOnSurfaceVariant,
        ),
        prefixIcon: const Icon(
          IconsaxPlusLinear.search_normal_1,
          size: 20,
          color: AppColors.osOnSurfaceVariant,
        ),
        filled: true,
        fillColor: AppColors.osSurfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Row(
      children: [
        const Icon(IconsaxPlusLinear.sort, size: 18, color: AppColors.osOnSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          context.l10n.sortBy,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(context.l10n.ratingSort, 'rating'),
                const SizedBox(width: 8),
                _buildSortChip(context.l10n.durationSort, 'duration'),
                const SizedBox(width: 8),
                _buildSortChip(context.l10n.nameSort, 'title'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(String label, String sortValue) {
    final isSelected = _sortBy == sortValue;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = sortValue);
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.osPrimary : AppColors.osSurfaceContainerHighest,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.osOnPrimary : AppColors.osOnSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationCard(Meditation meditation) {
    final cover = imageProviderFromSource(meditation.thumbnailUrl);
    final accent = _getCategoryColor(meditation.category);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeditationDetailPage(meditation: meditation),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.osSurfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.osOnSurface.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image / fallback
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  cover != null
                      ? Image(
                          image: cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.osSurfaceContainerHigh),
                        )
                      : Container(
                          color: AppColors.osSurfaceContainerHigh,
                          child: Icon(
                            PhosphorIconsRegular.flowerLotus,
                            size: 36,
                            color: accent,
                          ),
                        ),
                  if (meditation.rating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.osOnSurface.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(IconsaxPlusBold.star, color: AppColors.osPrimaryFixed, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              meditation.rating.toStringAsFixed(1),
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.osOnSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(IconsaxPlusLinear.clock, size: 13, color: AppColors.osOnSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${meditation.duration} ${context.l10n.min} • ${_getLevelLabel(context, meditation.level)}',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.osOnSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.flowerLotus, size: 64, color: AppColors.osSurfaceContainerHighest),
          const SizedBox(height: 16),
          Text(
            context.l10n.noMeditationsFound,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.osOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tryDifferentSearch,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColors.osOnSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _getLevelLabel(BuildContext context, MeditationLevel level) {
    switch (level) {
      case MeditationLevel.beginner:
        return context.l10n.beginner;
      case MeditationLevel.intermediate:
        return context.l10n.intermediate;
      case MeditationLevel.advanced:
        return context.l10n.advanced;
    }
  }
}
