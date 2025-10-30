import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/appointment.dart';

class DurationSelector extends StatelessWidget {
  final int selectedDuration;
  final CallType callType;
  final double expertBasePrice; // ✅ NEW
  final ValueChanged<int> onChanged;

  const DurationSelector({
    super.key,
    required this.selectedDuration,
    required this.callType,
    required this.expertBasePrice, // ✅ NEW
    required this.onChanged,
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
                price: Appointment.calculatePrice(
                  expertBasePrice: expertBasePrice,
                  callType: callType,
                  duration: 30,
                ),
                isSelected: selectedDuration == 30,
                onTap: () => onChanged(30),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDurationOption(
                duration: 60,
                price: Appointment.calculatePrice(
                  expertBasePrice: expertBasePrice,
                  callType: callType,
                  duration: 60,
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color: Colors.white,
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
                        : const Color(0xFF1A1A1A),
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
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    return '₫${price.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
}
