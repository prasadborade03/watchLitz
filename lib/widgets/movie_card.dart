import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_poster.dart';

/// Unified movie card widget supporting 4 states:
/// - NOT IN LIST: Shows "ADD" button (search results)
/// - TO WATCH: Red minus icon, "Mark as Watched" button
/// - WATCHED: Green checkmark icon, "Unmark" button
class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isInWatchlist;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onToggleWatched;

  const MovieCard({
    super.key,
    required this.movie,
    this.isInWatchlist = false,
    this.onTap,
    this.onAdd,
    this.onRemove,
    this.onToggleWatched,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(6, 6),
              blurRadius: 14,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.07),
              offset: const Offset(-4, -4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster area with state indicator
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  MoviePoster(
                    posterUrl: movie.poster,
                    heroTag: 'poster_${movie.imdbId}',
                    useHero: true,
                    borderRadius: 22,
                    width: double.infinity,
                  ),
                  // State icon - TOP LEFT CORNER
                  if (isInWatchlist) _buildStateIcon(),

                ],
              ),
            ),
            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.aBeeZee(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Year • IMDB Rating row
                    _buildYearAndRatingRow(),
                    const Spacer(),
                    // Contextual action button
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// State icon displayed on the top-left of the poster.
  /// Wrapped in GestureDetector with HitTestBehavior.opaque so taps
  /// are consumed by the icon and don't bubble up to the card's onTap.
  Widget _buildStateIcon() {
    final bool watched = movie.isWatched;
    final double circleSize = 25;

    final Widget icon = SizedBox(
      width: circleSize,
      height: circleSize,
      child: Container(
        decoration: BoxDecoration(
          color: watched ? const Color(0xFF4CAF50) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(1, 1),
              blurRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: watched
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : const SizedBox(
                  width: 14,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFE53935),
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
        ),
      ),
    );

    return Positioned(
      top: 8,
      left: 8,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRemove,
        child: icon,
      ),
    );
  }

  /// Year displayed on card
  Widget _buildYearAndRatingRow() {
    final hasYear = movie.year.isNotEmpty && movie.year != 'N/A';
    if (!hasYear) return const SizedBox.shrink();

    return Text(
      movie.year,
      style: GoogleFonts.aBeeZee(
        color: const Color(0xFF777777),
        fontSize: 12,
      ),
    );
  }

  /// Contextual action button based on movie state
  Widget _buildActionButton() {
    if (!isInWatchlist) {
      // STATE 1: ADD - Not in watchlist
      return _buildAddButton();
    } else if (movie.isWatched) {
      // STATE 3: WATCHED - Green checkmark, "Unmark" button
      return _buildUnmarkButton();
    } else {
      // STATE 2: TO WATCH - Red minus, "Mark as Watched" button
      return _buildMarkWatchedButton();
    }
  }

  /// STATE 1: ADD button for search results
  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'ADD',
            style: GoogleFonts.aBeeZee(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// STATE 2: "Mark as Watched" button for To Watch movies
  Widget _buildMarkWatchedButton() {
    return GestureDetector(
      onTap: onToggleWatched,
      child: Container(
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Mark as Watched',
            style: GoogleFonts.aBeeZee(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// STATE 3: "Unmark" button for Watched movies
  Widget _buildUnmarkButton() {
    return GestureDetector(
      onTap: onToggleWatched,
      child: Container(
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            'Unmark',
            style: GoogleFonts.aBeeZee(
              color: const Color(0xFF4CAF50),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
