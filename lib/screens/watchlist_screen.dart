import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import 'movie_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/watchlist_service.dart';


class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistService _watchlistService = WatchlistService();

  List<Movie> _watchlist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() {
      _isLoading = true;
    });
    final watchlist = await _watchlistService.getWatchlist();
    setState(() {
      _watchlist = watchlist;
      _isLoading = false;
    });
  }

  Future<void> _removeFromWatchlist(Movie movie) async {
    await _watchlistService.removeFromWatchlist(movie.imdbId);
    await _loadWatchlist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${movie.title}" removed from watchlist',
            style: GoogleFonts.aBeeZee(),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 102, 7),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTopHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(6, 6),
                blurRadius: 16,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.05),
                offset: const Offset(-4, -4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.movie_filter,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)],
                  ),
                ),
                child: Text(
                  'Your Saved List',
                  style: GoogleFonts.aBeeZee(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_watchlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBg,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(6, 6),
                    blurRadius: 14,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 44,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your watchlist is empty',
              style: GoogleFonts.aBeeZee(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for movies and add them here',
              style: GoogleFonts.aBeeZee(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(34),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search Movies',
                      style: GoogleFonts.aBeeZee(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.58,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _watchlist.length,
      itemBuilder: (context, index) {
        final movie = _watchlist[index];
        return _buildWatchlistCard(movie);
      },
    );
  }

  Widget _buildWatchlistCard(Movie movie) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(imdbId: movie.imdbId))),
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
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: SizedBox(
                width: double.infinity,
                child: movie.poster.isNotEmpty && movie.poster != 'N/A'
                    ? CachedNetworkImage(
                        imageUrl: movie.poster,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.secondarySurface,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2,),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.secondarySurface,
                          child: Icon(Icons.movie, size: 50, color: Colors.grey[500]),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.movie,
                          size: 50,
                          color: Colors.grey[500],
                        ),
                      ),
              ),
            ),
          ),
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
                  GestureDetector(
                    onTap: () => _removeFromWatchlist(movie),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 34,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        color: Colors.transparent,
                        border: Border.all(color: AppColors.accent, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'Remove',
                          style: GoogleFonts.aBeeZee(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
