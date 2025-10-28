import 'package:flutter/material.dart';

class MoodFilterBar extends StatelessWidget {
  final int selectedFilter;
  final Function(int) onFilterChanged;

  const MoodFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', 0, Icons.filter_list),
          const SizedBox(width: 8),
          _buildFilterChip('😞 Very Poor', 1, null),
          const SizedBox(width: 8),
          _buildFilterChip('😕 Poor', 2, null),
          const SizedBox(width: 8),
          _buildFilterChip('😐 Okay', 3, null),
          const SizedBox(width: 8),
          _buildFilterChip('🙂 Good', 4, null),
          const SizedBox(width: 8),
          _buildFilterChip('😄 Excellent', 5, null),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value, IconData? icon) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4CAF50),
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
    );
  }
}
