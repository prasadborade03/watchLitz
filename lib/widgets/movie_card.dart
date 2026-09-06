import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';
import 'movie_poster.dart';
import 'rating_badge.dart';

/// Unified movie card widget with poster, title, year, IMDb rating badge,
/// optional watched indicator, and add/remove button
class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isInWatchlist;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final bool showWatchedBadge;

  const MovieCard({
    super.key,
    required this.movie,
    this.isInWatchlist = false,
    this.onTap,
    this.onAdd,
    this.onRemove,
    this.showWatchedBadge = false,
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
            // Poster area
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
                  // IMDb Rating badge
                  if (movie.imdbRating != null && movie.imdbRating != 'N/A')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RatingBadge(rating: movie.imdbRating),
                    ),
                  // Watched badge
                  if (showWatchedBadge && movie.isWatched)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
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
                    Text(
                      movie.year,
                      style: GoogleFonts.aBeeZee(
                        color: const Color(0xFF777777),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // Add/Remove button
                    isInWatchlist
                        ? _buildRemoveButton()
                        : _buildAddButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
            'ADD TO WATCHLIST',
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

  Widget _buildRemoveButton() {
    return GestureDetector(
      onTap: onRemove,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 34,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: Colors.transparent,
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Center(
          child: Text(
            'REMOVE',
            style: GoogleFonts.aBeeZee(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
