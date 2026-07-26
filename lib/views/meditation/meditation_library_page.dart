import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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

  // Dynamic colors for meditation cards
  final List<Color> _meditationColors = [
    Colors.green.shade700,
    Colors.blue.shade400,
    Colors.purple.shade400,
    Colors.orange.shade400,
    Colors.pink.shade400,
    Colors.teal.shade400,
  ];

  Color _getMeditationColor(int index) {
    return _meditationColors[index % _meditationColors.length];
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          context.l10n.meditationLibrary,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: context.l10n.searchMeditations,
                    prefixIcon: Icon(IconsaxPlusLinear.search_normal_1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),

                // Sort Options
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Icon(IconsaxPlusLinear.sort, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.sortBy,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildSortChip(context.l10n.ratingSort, 'rating'),
                      const SizedBox(width: 8),
                      _buildSortChip(context.l10n.durationSort, 'duration'),
                      const SizedBox(width: 8),
                      _buildSortChip(context.l10n.nameSort, 'title'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredMeditations.length} ${_filteredMeditations.length != 1 ? context.l10n.meditationsFound : context.l10n.meditationFound}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

          // Meditation Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  )
                : _filteredMeditations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMeditations,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _filteredMeditations.length,
                      itemBuilder: (context, index) {
                        return _buildMeditationCard(
                          _filteredMeditations[index],
                          _getMeditationColor(index),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String sortValue) {
    final isSelected = _sortBy == sortValue;
    return InkWell(
      onTap: () {
        setState(() => _sortBy = sortValue);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationCard(Meditation meditation, Color color) {
    final cover = imageProviderFromSource(meditation.thumbnailUrl);
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background: Thumbnail or Gradient
              Positioned.fill(
                child:
                    cover != null
                    ? Image(
                        image: cover,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to gradient if image fails
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          // Show gradient while loading
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withValues(alpha: 0.7)],
                          ),
                        ),
                      ),
              ),

              // Overlay gradient for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Subtle pattern overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Rating badge
              if (meditation.rating > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(IconsaxPlusBold.star, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          meditation.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      meditation.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meditation.duration} ${context.l10n.min} • ${_getLevelLabel(context, meditation.level)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIconsRegular.flowerLotus, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            context.l10n.noMeditationsFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tryDifferentSearch,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
