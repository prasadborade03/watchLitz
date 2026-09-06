import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color-coded IMDb rating badge pill
/// Green (7.0+), Yellow (5.0–6.9), Red (<5.0)
class RatingBadge extends StatelessWidget {
  final String? rating;
  final double size;

  const RatingBadge({
    super.key,
    required this.rating,
    this.size = 12,
  });

  Color get _badgeColor {
    final value = double.tryParse(rating ?? '') ?? 0;
    if (value >= 7.0) return const Color(0xFF4CAF50);
    if (value >= 5.0) return const Color(0xFFFFC107);
    return const Color(0xFFEF5350);
  }

  bool get _isValid =>
      rating != null && rating != 'N/A' && (double.tryParse(rating!) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    if (!_isValid) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: Colors.white, size: size),
          const SizedBox(width: 3),
          Text(
            rating!,
            style: GoogleFonts.aBeeZee(
              color: Colors.white,
              fontSize: size,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
