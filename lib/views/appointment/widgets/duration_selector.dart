import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DurationSelector extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onChanged;
  final double price30;
  final double price60;

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
    required this.price30,
    required this.price60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDurationOption(
                duration: 30,
                price: price30,
                isSelected: selectedDuration == 30,
                onTap: () => onChanged(30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDurationOption(
                duration: 60,
                price: price60,
                isSelected: selectedDuration == 60,
                onTap: () => onChanged(60),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationOption({
    required int duration,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Radio button
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  '$duration min',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatPrice(price),
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '₫${(price / 1000).toStringAsFixed(0)}k';
    } else {
      return '₫${price.toInt()}';
    }
  }
}
