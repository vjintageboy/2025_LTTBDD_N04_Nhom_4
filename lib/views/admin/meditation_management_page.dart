import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.osSurfaceContainerLowest,
        title: Text(
          'Xóa bài thiền',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa "${meditation.title}"?',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: GoogleFonts.manrope(
                color: AppColors.osOnSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.osError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Xóa',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
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
            content: Text('Đã xóa bài thiền'),
            backgroundColor: AppColors.osPrimary,
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      appBar: AppBar(
        title: Text(
          'Quản lý bài thiền',
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
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(IconsaxPlusLinear.add),
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
            color: AppColors.osSurface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  style: GoogleFonts.manrope(color: AppColors.osOnSurface),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài thiền',
                    hintStyle: GoogleFonts.manrope(
                      color: AppColors.osOnSurfaceVariant,
                    ),
                    prefixIcon: const Icon(
                      IconsaxPlusLinear.search_normal_1,
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
                        label: 'Tất cả',
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
                        label: 'Tất cả cấp',
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
                      strokeWidth: 2.5,
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
                              PhosphorIconsRegular.imageBroken,
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
                          PhosphorIconsRegular.flowerLotus,
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
                          IconsaxPlusLinear.clock,
                          '${meditation.duration} phút',
                        ),
                        _buildInfoChip(
                          IconsaxPlusLinear.category,
                          _getCategoryLabel(meditation.category),
                        ),
                        _buildInfoChip(
                          IconsaxPlusLinear.chart_2,
                          _getLevelLabel(meditation.level),
                        ),
                        _buildInfoChip(
                          IconsaxPlusBold.star,
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
                    icon: const Icon(IconsaxPlusLinear.edit_2, size: 20),
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
                    icon: const Icon(IconsaxPlusLinear.trash, size: 20),
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
            PhosphorIconsRegular.flowerLotus,
            size: 64,
            color: AppColors.osOutlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty &&
                    _selectedCategory == null &&
                    _selectedLevel == null
                ? 'Chưa có bài thiền nào'
                : 'Không tìm thấy bài thiền',
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
                ? 'Nhấn nút + để thêm bài thiền đầu tiên'
                : 'Thử thay đổi bộ lọc',
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
