import 'package:flutter/material.dart';
import '../../models/meditation.dart';
import '../../services/firestore_service.dart';
import 'edit_meditation_page.dart';
import 'add_meditation_page.dart';

/// Meditation Management Page - Admin page để quản lý tất cả meditations
class MeditationManagementPage extends StatefulWidget {
  const MeditationManagementPage({super.key});

  @override
  State<MeditationManagementPage> createState() => _MeditationManagementPageState();
}

class _MeditationManagementPageState extends State<MeditationManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Meditation> _meditations = [];
  List<Meditation> _filteredMeditations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  MeditationCategory? _selectedCategory;
  MeditationLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _loadMeditations();
  }

  Future<void> _loadMeditations() async {
    setState(() => _isLoading = true);
    
    try {
      final meditations = await _firestoreService.getAllMeditations();
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
        final matchesSearch = _searchQuery.isEmpty ||
            meditation.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            meditation.description.toLowerCase().contains(_searchQuery.toLowerCase());

        // Category filter
        final matchesCategory = _selectedCategory == null ||
            meditation.category == _selectedCategory;

        // Level filter
        final matchesLevel = _selectedLevel == null ||
            meditation.level == _selectedLevel;

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
      await _firestoreService.deleteMeditation(meditation.meditationId);
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Manage Meditations',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search meditations...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
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
                ? const Center(child: CircularProgressIndicator())
                : _filteredMeditations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMeditations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
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
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade100,
        selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
        checkmarkColor: const Color(0xFF4CAF50),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildMeditationCard(Meditation meditation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        borderRadius: BorderRadius.circular(16),
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
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.spa, size: 32),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meditation.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    onPressed: () async {
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
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    color: Colors.red,
                    onPressed: () => _deleteMeditation(meditation),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _selectedCategory == null && _selectedLevel == null
                ? 'No meditations yet'
                : 'No meditations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedCategory == null && _selectedLevel == null
                ? 'Tap the + button to add your first meditation'
                : 'Try adjusting your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
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
