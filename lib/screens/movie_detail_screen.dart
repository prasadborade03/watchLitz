import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart'; // Share API
import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_poster.dart';
import '../widgets/rating_badge.dart';
import '../widgets/star_rating.dart';
import '../widgets/neumorphic_container.dart';
import '../widgets/error_state_widget.dart';

class MovieDetailScreen extends StatefulWidget {
  final String imdbId;
  final String? heroTag;

  const MovieDetailScreen({super.key, required this.imdbId, this.heroTag});

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
  bool _isPlotExpanded = false;
  bool _isSavingNotes = false;

  @override
  void initState() { super.initState(); _loadMovieDetails(); }

  Future<void> _loadMovieDetails() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final movie = await _omdbService.getMovieDetails(widget.imdbId);
      final inWatchlist = await _watchlistService.isInWatchlist(widget.imdbId);
      if (mounted) setState(() { _movie = movie; _isInWatchlist = inWatchlist; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Unable to connect. Please check your internet connection and try again.'; _isLoading = false; });
    }
  }

  Future<void> _toggleWatchlist() async {
    if (_movie == null) return;
    if (_isInWatchlist) await _watchlistService.removeFromWatchlist(widget.imdbId);
    else await _watchlistService.addToWatchlist(_movie!);
    if (mounted) {
      setState(() { _isInWatchlist = !_isInWatchlist; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text((_isInWatchlist ? '\x22' + _movie!.title + '\x22 added to' : '\x22' + _movie!.title + '\x22 removed from') + ' watchlist', style: GoogleFonts.aBeeZee()),
        backgroundColor: _isInWatchlist ? AppColors.accent : Colors.grey[800],
        behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _toggleWatched() async {
    if (_movie == null) return;
    final updated = _movie!.copyWith(isWatched: !_movie!.isWatched);
    await _watchlistService.updateMovie(updated);
    if (mounted) {
      setState(() { _movie = updated; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(updated.isWatched ? 'Marked as watched' : 'Marked as unwatched', style: GoogleFonts.aBeeZee()),
        backgroundColor: AppColors.secondarySurface, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _updatePersonalRating(double? rating) async {
    if (_movie == null) return;
    final updated = _movie!.copyWith(personalRating: rating);
    await _watchlistService.updateMovie(updated);
    if (mounted) setState(() { _movie = updated; });
  }

  Future<void> _updatePersonalNotes(String notes) async {
    if (_movie == null) return;
    setState(() => _isSavingNotes = true);
    final updated = _movie!.copyWith(personalNotes: notes.isEmpty ? null : notes);
    await _watchlistService.updateMovie(updated);
    if (mounted) setState(() { _movie = updated; _isSavingNotes = false; });
  }

  void _shareMovie() {
    if (_movie == null) return;
    final m = _movie!;
    final buf = StringBuffer()..writeln(m.title + ' (' + m.year + ')')..writeln();
    if (m.imdbRating != null && m.imdbRating != 'N/A') buf.writeln('IMDb: ' + m.imdbRating!);
    if (m.genre != null) buf.writeln(m.genre);
    if (m.director != null && m.director != 'N/A') buf.writeln('Director: ' + m.director!);
    if (m.plot != null && m.plot != 'N/A') { buf.writeln(); buf.writeln(m.plot); }
    buf.writeln(); buf.writeln('https://www.imdb.com/title/' + m.imdbId + '/');
    Share.share(buf.toString());
  }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.primaryBg, body: _buildBody());

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    if (_error != null) return ErrorStateWidget(message: _error!, icon: Icons.signal_wifi_connected_no_internet_4, onRetry: _loadMovieDetails);
    if (_movie == null) return const SizedBox();
    return CustomScrollView(slivers: [
      SliverAppBar(backgroundColor: AppColors.primaryBg, pinned: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.share, color: AppColors.textPrimary), onPressed: _shareMovie, tooltip: 'Share movie')]),
      SliverPadding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        sliver: SliverList(delegate: SliverChildListDelegate([
          _buildPoster(), const SizedBox(height: 24), _buildTitleAndRating(), const SizedBox(height: 16),
          _buildGenreChips(), const SizedBox(height: 24), _buildInfoSection(), const SizedBox(height: 24),
          _buildPlotSection(), const SizedBox(height: 24), _buildPersonalRatingSection(), const SizedBox(height: 16),
          _buildNotesSection(), const SizedBox(height: 32), _buildActionButtons(), const SizedBox(height: 40),
        ]))),
    ]);
  }

  Widget _buildPoster() => Center(child: Container(
    height: 380, width: 250,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.neumorphic(offset: 6, blur: 16)),
    child: MoviePoster(posterUrl: _movie!.poster, heroTag: widget.heroTag ?? 'poster_' + _movie!.imdbId, useHero: true, borderRadius: 16, width: 250, height: 380)));

  Widget _buildTitleAndRating() => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_movie!.title, style: AppTextStyles.heading.copyWith(fontSize: 24)),
      const SizedBox(height: 6),
      Row(children: [Text(_movie!.year, style: AppTextStyles.bodySecondary),
        if (_movie!.runtime != null && _movie!.runtime != 'N/A') Text(' \u2022 ' + _movie!.runtime!, style: AppTextStyles.bodySecondary)]),
    ])),
    if (_movie!.imdbRating != null && _movie!.imdbRating != 'N/A') RatingBadge(rating: _movie!.imdbRating),
  ]);

  Widget _buildGenreChips() {
    if (_movie!.genre == null || _movie!.genre == 'N/A') return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: _movie!.genre!.split(', ').map((g) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: AppColors.secondarySurface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1)),
      child: Text(g, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)))).toList());
  }

  Widget _buildInfoSection() {
    final items = <MapEntry<String, String?>>[];
    if (_movie!.director != null && _movie!.director != 'N/A') items.add(MapEntry('Director', _movie!.director));
    if (_movie!.actors != null && _movie!.actors != 'N/A') items.add(MapEntry('Stars', _movie!.actors));
    if (_movie!.writer != null && _movie!.writer != 'N/A') items.add(MapEntry('Writer', _movie!.writer));
    if (_movie!.language != null && _movie!.language != 'N/A') items.add(MapEntry('Language', _movie!.language));
    if (_movie!.country != null && _movie!.country != 'N/A') items.add(MapEntry('Country', _movie!.country));
    if (_movie!.awards != null && _movie!.awards != 'N/A') items.add(MapEntry('Awards', _movie!.awards));
    if (_movie!.rated != null && _movie!.rated != 'N/A') items.add(MapEntry('Rated', _movie!.rated));
    if (items.isEmpty) return const SizedBox.shrink();
    return NeumorphicContainer(padding: const EdgeInsets.all(16),
      child: Column(children: items.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 80, child: Text(e.key, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13))),
          Expanded(child: Text(e.value!, style: AppTextStyles.body.copyWith(fontSize: 13)))]))).toList()));
  }

  Widget _buildPlotSection() {
    if (_movie!.plot == null || _movie!.plot == 'N/A') return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Plot', style: AppTextStyles.heading.copyWith(fontSize: 20)), const SizedBox(height: 10),
      GestureDetector(onTap: () => setState(() => _isPlotExpanded = !_isPlotExpanded),
        child: Text(_movie!.plot!, maxLines: _isPlotExpanded ? null : 3,
          overflow: _isPlotExpanded ? null : TextOverflow.ellipsis, style: AppTextStyles.bodySecondary.copyWith(height: 1.6))),
      if (_movie!.plot!.length > 150) Padding(padding: const EdgeInsets.only(top: 6),
        child: Text(_isPlotExpanded ? 'Show less' : 'Read more', style: AppTextStyles.body.copyWith(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _buildPersonalRatingSection() => NeumorphicContainer(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.star_rounded, color: AppColors.accent, size: 20), const SizedBox(width: 8),
        Text('Your Rating', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)), const Spacer(),
        if (_movie!.personalRating != null) Text(_movie!.personalRating!.toStringAsFixed(1) + '/10', style: AppTextStyles.bodySecondary.copyWith(fontSize: 14))]),
      const SizedBox(height: 12),
      StarRating(rating: _movie!.personalRating, onRatingChanged: _updatePersonalRating, starSize: 30),
    ]));

  Widget _buildNotesSection() => NeumorphicContainer(padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.notes_rounded, color: AppColors.accent, size: 20), const SizedBox(width: 8),
        Text('Personal Notes', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        if (_isSavingNotes) ...[const Spacer(), const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))]]),
      const SizedBox(height: 12),
      TextField(maxLines: 4, maxLength: 500, onChanged: _updatePersonalNotes, style: AppTextStyles.bodySecondary.copyWith(fontSize: 14),
        decoration: InputDecoration(hintText: 'Add your thoughts about this movie...',
          hintStyle: AppTextStyles.bodySecondary.copyWith(fontSize: 14, color: Colors.grey[600]),
          filled: true, fillColor: AppColors.primaryBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.2))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.2))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
          contentPadding: const EdgeInsets.all(12))),
    ]));

  Widget _buildActionButtons() => Column(children: [
    GestureDetector(onTap: _toggleWatchlist, child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: _isInWatchlist ? AppColors.secondarySurface : AppColors.accent,
        borderRadius: BorderRadius.circular(24), border: _isInWatchlist ? Border.all(color: AppColors.accent) : null,
        boxShadow: _isInWatchlist ? [] : AppShadows.neumorphic(offset: 2, blur: 8)),
      child: Center(child: Text(_isInWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: _isInWatchlist ? AppColors.accent : Colors.white))))),
    const SizedBox(height: 12),
    GestureDetector(onTap: _isInWatchlist ? _toggleWatched : null, child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: _movie!.isWatched ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(24), border: Border.all(color: _movie!.isWatched ? const Color(0xFF4CAF50) : Colors.grey[700]!, width: 1.5)),
      child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_movie!.isWatched ? Icons.check_circle : Icons.check_circle_outline,
          color: _movie!.isWatched ? const Color(0xFF4CAF50) : Colors.grey[500], size: 20),
        const SizedBox(width: 8),
        Text(_movie!.isWatched ? 'Watched' : 'Mark as Watched',
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: _movie!.isWatched ? const Color(0xFF4CAF50) : Colors.grey[500])),
      ])))),
  ]);
}