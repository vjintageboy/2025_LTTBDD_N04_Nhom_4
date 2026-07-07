import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

/// Shared Organic Sanctuary input styling for the admin meditation forms
/// (add + edit). Keeps the two screens visually identical without repeating
/// the same InputDecoration on every field.
InputDecoration osFieldDecoration({
  required String label,
  String? hint,
  required IconData icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.manrope(color: AppColors.osOnSurfaceVariant),
    hintStyle: GoogleFonts.manrope(color: AppColors.osOnSurfaceVariant),
    prefixIcon: Icon(icon, color: AppColors.osOnSurfaceVariant),
    filled: true,
    fillColor: AppColors.osSurfaceContainerLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.osPrimary, width: 2),
    ),
  );
}
