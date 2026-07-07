import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../../../l10n/app_localizations.dart';

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
          _buildFilterChip(
            context,
            AppLocalizations.of(context)!.all,
            0,
            IconsaxPlusLinear.filter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            '😞 ${AppLocalizations.of(context)!.veryPoor}',
            1,
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            '😕 ${AppLocalizations.of(context)!.poor}',
            2,
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            '😐 ${AppLocalizations.of(context)!.okay}',
            3,
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            '🙂 ${AppLocalizations.of(context)!.good}',
            4,
            null,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            '😄 ${AppLocalizations.of(context)!.excellent}',
            5,
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    int value,
    IconData? icon,
  ) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          onFilterChanged(value);
        }
      },
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
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
