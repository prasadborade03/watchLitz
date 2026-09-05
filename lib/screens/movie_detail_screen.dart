import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';

class MovieDetailScreen extends StatefulWidget {
  final String imdbId;
  const MovieDetailScreen({super.key, required this.imdbId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final OmdbService _omdbService = OmdbService();
  final WatchlistService _watchlistService = WatchlistService();
  
  Movie? _movie;
  bool _isLoading = true;
  String? _error;
  bool _isInWatchlist = false;

  @override
  void initState() {
    super.initState();
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final movie = await _omdbService.getMovieDetails(widget.imdbId);
      final inWatchlist = await _watchlistService.isInWatchlist(widget.imdbId);
      if (mounted) {
        setState(() {
          _movie = movie;
          _isInWatchlist = inWatchlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Content requires a connection. Please check your network and try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleWatchlist() async {
    if (_movie == null) return;
    
    if (_isInWatchlist) {
      await _watchlistService.removeFromWatchlist(widget.imdbId);
    } else {
      await _watchlistService.addToWatchlist(_movie!);
    }
    
    if (mounted) {
      setState(() {
        _isInWatchlist = !_isInWatchlist;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('  watchlist'),
          backgroundColor: AppColors.secondarySurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('Details', style: AppTextStyles.heading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_connected_no_internet_4, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadMovieDetails();
                },
                child: Text('Retry', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_movie == null) {
      return const SizedBox();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPoster(),
          const SizedBox(height: 24),
          _buildTitleAndRating(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildInfoPill('Genre', _movie!.genre),
          const SizedBox(height: 8),
          _buildInfoPill('Director', _movie!.director),
          const SizedBox(height: 8),
          _buildInfoPill('Actors', _movie!.actors),
          const SizedBox(height: 24),
          Text('Plot', style: AppTextStyles.heading.copyWith(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            _movie!.plot ?? 'Plot details not available from source.',
            style: AppTextStyles.bodySecondary.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPoster() {
    return Center(
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.neumorphic(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: _movie!.poster,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.secondarySurface,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.secondarySurface,
              child: const Center(
                child: Icon(Icons.broken_image, size: 64, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndRating() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _movie!.title,
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                '${_movie!.year} • ${_movie!.runtime ?? 'Unknown'}',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
        if (_movie!.imdbRating != null && _movie!.imdbRating != 'N/A')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text(
                  _movie!.imdbRating!,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return InkWell(
      onTap: _toggleWatchlist,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isInWatchlist ? AppColors.secondarySurface : AppColors.accent,
          borderRadius: BorderRadius.circular(24),
          border: _isInWatchlist ? Border.all(color: AppColors.accent) : null,
          boxShadow: _isInWatchlist ? [] : AppShadows.neumorphic(offset: 2, blur: 8),
        ),
        child: Center(
          child: Text(
            _isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: _isInWatchlist ? AppColors.accent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPill(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTextStyles.bodySecondary,
          ),
        ),
        Expanded(
          child: Text(
            (value == null || value == 'N/A') ? 'Not available' : value,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }
}
