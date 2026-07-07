import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/meditation.dart';
import '../../core/constants/app_colors.dart';
import 'edit_meditation_page.dart';
import 'add_meditation_page.dart';

/// Meditation Management Page - Admin page để quản lý tất cả meditations
class MeditationManagementPage extends StatefulWidget {
  const MeditationManagementPage({super.key});

  @override
  State<MeditationManagementPage> createState() =>
      _MeditationManagementPageState();
}

class _MeditationManagementPageState extends State<MeditationManagementPage> {
  final _supabase = Supabase.instance.client;
  List<Meditation> _meditations = [];
  List<Meditation> _filteredMeditations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  MeditationCategory? _selectedCategory;
  MeditationLevel? _selectedLevel;

  // Ambient tinted shadow — mimics natural light instead of a grey smudge.
  static const List<BoxShadow> _ambientShadow = [
    BoxShadow(
      color: Color(0x0F0B361D), // osOnSurface @ ~6%
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }

  Future<void> _loadMeditations() async {
    setState(() => _isLoading = true);

    try {
      final data = await _supabase
          .from('meditations')
          .select()
          .order('created_at', ascending: false);
      final meditations = (data as List).map((m) => Meditation.fromMap(m)).toList();
      setState(() {
        _meditations = meditations;
        _filteredMeditations = meditations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading meditations: $e')),
        );
      }
    }
  }

  void _filterMeditations() {
    setState(() {
      _filteredMeditations = _meditations.where((meditation) {
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

        // Level filter
        final matchesLevel =
            _selectedLevel == null || meditation.level == _selectedLevel;

        return matchesSearch && matchesCategory && matchesLevel;
      }).toList();
    });
  }

  Future<void> _deleteMeditation(Meditation meditation) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meditation'),
        content: Text('Are you sure you want to delete "${meditation.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('meditations').delete().eq('id', meditation.meditationId);
      _loadMeditations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meditation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meditation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      appBar: AppBar(
        title: Text(
          'Manage meditations',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddMeditationPage(),
                ),
              );
              if (result == true) {
                _loadMeditations();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            color: AppColors.osSurfaceContainerLowest,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  style: GoogleFonts.manrope(color: AppColors.osOnSurface),
                  decoration: InputDecoration(
                    hintText: 'Search meditations',
                    hintStyle: GoogleFonts.manrope(
                      color: AppColors.osOnSurfaceVariant,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.osOnSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.osSurfaceContainer,
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterMeditations();
                  },
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filter
                      _buildFilterChip(
                        label: 'All Categories',
                        isSelected: _selectedCategory == null,
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          _filterMeditations();
                        },
                      ),
                      ...MeditationCategory.values.map((category) {
                        return _buildFilterChip(
                          label: _getCategoryLabel(category),
                          isSelected: _selectedCategory == category,
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            _filterMeditations();
                          },
                        );
                      }),
                      const SizedBox(width: 12),

                      // Level Filter
                      _buildFilterChip(
                        label: 'All Levels',
                        isSelected: _selectedLevel == null,
                        onTap: () {
                          setState(() => _selectedLevel = null);
                          _filterMeditations();
                        },
                      ),
                      ...MeditationLevel.values.map((level) {
                        return _buildFilterChip(
                          label: _getLevelLabel(level),
                          isSelected: _selectedLevel == level,
                          onTap: () {
                            setState(() => _selectedLevel = level);
                            _filterMeditations();
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Meditation List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.osPrimary,
                    ),
                  )
                : _filteredMeditations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMeditations,
                    color: AppColors.osPrimary,
                    backgroundColor: AppColors.osSurfaceContainerLowest,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredMeditations.length,
                      itemBuilder: (context, index) {
                        return _buildMeditationCard(
                          _filteredMeditations[index],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.osSurfaceContainer,
        selectedColor: AppColors.osPrimaryContainer,
        side: BorderSide.none,
        labelStyle: GoogleFonts.manrope(
          color: isSelected
              ? AppColors.osOnPrimaryContainer
              : AppColors.osOnSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMeditationCard(Meditation meditation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _ambientShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditMeditationPage(meditation: meditation),
              ),
            );
            if (result == true) {
              _loadMeditations();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: meditation.thumbnailUrl != null
                    ? Image.network(
                        meditation.thumbnailUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: AppColors.osSurfaceContainerHigh,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.osOnSurfaceVariant,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: AppColors.osSurfaceContainerHigh,
                        child: const Icon(
                          Icons.spa,
                          size: 32,
                          color: AppColors.osOnSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meditation.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.osOnSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meditation.description,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: AppColors.osOnSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          Icons.schedule,
                          '${meditation.duration} min',
                        ),
                        _buildInfoChip(
                          Icons.category_outlined,
                          _getCategoryLabel(meditation.category),
                        ),
                        _buildInfoChip(
                          Icons.bar_chart,
                          _getLevelLabel(meditation.level),
                        ),
                        _buildInfoChip(
                          Icons.star,
                          '${meditation.rating.toStringAsFixed(1)} (${meditation.totalReviews})',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: AppColors.osPrimary,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditMeditationPage(meditation: meditation),
                        ),
                      );
                      if (result == true) {
                        _loadMeditations();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: AppColors.osError,
                    onPressed: () => _deleteMeditation(meditation),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    // Single muted accent — one consistent metadata treatment, no rainbow.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.osOnSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.spa_outlined,
            size: 64,
            color: AppColors.osOutlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty &&
                    _selectedCategory == null &&
                    _selectedLevel == null
                ? 'No meditations yet'
                : 'No meditations found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.osOnSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty &&
                    _selectedCategory == null &&
                    _selectedLevel == null
                ? 'Tap the + button to add your first meditation'
                : 'Try adjusting your filters',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.osOnSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.stress:
        return 'Stress';
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
