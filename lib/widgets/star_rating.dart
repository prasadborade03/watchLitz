import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Interactive 1-10 star rating widget for personal ratings
/// Supports tap to select rating, drag to adjust
class StarRating extends StatefulWidget {
  final double? rating;
  final ValueChanged<double?> onRatingChanged;
  final int maxRating;
  final double starSize;
  final bool interactive;

  const StarRating({
    super.key,
    this.rating,
    required this.onRatingChanged,
    this.maxRating = 10,
    this.starSize = 32,
    this.interactive = true,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  double? _hoverRating;

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.interactive) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final double starWidth = box.size.width / widget.maxRating;
    final double position = details.localPosition.dx;
    final double newRating = (position / starWidth).clamp(1, widget.maxRating).toDouble();

    setState(() {
      _hoverRating = newRating;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_hoverRating != null) {
      widget.onRatingChanged(_hoverRating);
    }
    setState(() {
      _hoverRating = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRating = _hoverRating ?? widget.rating ?? 0;

    return GestureDetector(
      onHorizontalDragUpdate: widget.interactive ? _handleDragUpdate : null,
      onHorizontalDragEnd: widget.interactive ? _handleDragEnd : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.maxRating, (index) {
          final starNumber = index + 1.0;
          final isFilled = starNumber <= currentRating;

          return GestureDetector(
            onTap: widget.interactive
                ? () {
                    if (widget.rating == starNumber) {
                      widget.onRatingChanged(null);
                    } else {
                      widget.onRatingChanged(starNumber);
                    }
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFilled ? AppColors.accent : AppColors.textSecondary,
                size: widget.starSize,
              ),
            ),
          );
        }),
      ),
    );
  }
}
