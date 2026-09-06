import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import 'watchlist_screen.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OmdbService _omdbService = OmdbService();
  final WatchlistService _watchlistService = WatchlistService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  Set<String> _watchlistIds = {};

  // Search state
  String _currentQuery = '';
  int _currentPage = 1;
  bool _hasMore = false;

  // Search history
  List<String> _searchHistory = [];
  static const int _maxHistoryItems = 10;

  // Filters
  String? _selectedType;
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    _loadWatchlistIds();
    _loadSearchHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasMore && !_isLoading && !_isLoadingMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadWatchlistIds() async {
    final watchlist = await _watchlistService.getWatchlist();
    if (mounted) {
      setState(() {
        _watchlistIds = watchlist.map((m) => m.imdbId).toSet();
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    if (mounted) setState(() => _searchHistory = history);
  }

  Future<void> _saveSearchToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query.trim());
    _searchHistory.insert(0, query.trim());
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
    }
    await prefs.setStringList('search_history', _searchHistory);
    if (mounted) setState(() {});
  }

  Future<void> _deleteHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(item);
    await prefs.setStringList('search_history', _searchHistory);
    if (mounted) setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.clear();
    await prefs.remove('search_history');
    if (mounted) setState(() {});
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
        _currentQuery = '';
        _currentPage = 1;
        _hasMore = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query, resetPage: true);
    });
  }

  Future<void> _performSearch(String query, {bool resetPage = true}) async {
    if (query.trim().isEmpty) return;

    if (resetPage) {
      _currentPage = 1;
      _searchResults = [];
    }

    setState(() {
      _isLoading = resetPage;
      _isLoadingMore = !resetPage;
      _errorMessage = null;
      _currentQuery = query.trim();
    });

    try {
      final response = await _omdbService.searchMovies(
        query.trim(),
        page: _currentPage,
        type: _selectedType,
        year: _selectedYear,
      );

      if (mounted) {
        setState(() {
          _searchResults = resetPage ? response.movies : [..._searchResults, ...response.movies];
          _hasMore = response.hasMorePages;
          _isLoading = false;
          _isLoadingMore = false;
        });
        if (resetPage) _saveSearchToHistory(query.trim());
        _loadWatchlistIds();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isLoadingMore = false;
          if (resetPage) _searchResults = [];
        });
      }
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    await _performSearch(_currentQuery, resetPage: false);
  }

  Future<void> _addToWatchlist(Movie movie) async {
    final success = await _watchlistService.addToWatchlist(movie);
    if (success) {
      setState(() => _watchlistIds.add(movie.imdbId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${movie.title}" added to watchlist', style: GoogleFonts.aBeeZee()),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeFromWatchlist(Movie movie) async {
    await _watchlistService.removeFromWatchlist(movie.imdbId);
    setState(() => _watchlistIds.remove(movie.imdbId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${movie.title}" removed from watchlist', style: GoogleFonts.aBeeZee()),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleWatched(Movie movie) async {
    await _watchlistService.toggleWatched(movie.imdbId);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            movie.isWatched ? '"${movie.title}" marked as unwatched' : '"${movie.title}" marked as watched',
            style: GoogleFonts.aBeeZee(),
          ),
          backgroundColor: AppColors.secondarySurface,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Filters', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                  const SizedBox(height: 20),
                  Text('Type', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('All', _selectedType == null, () => setModalState(() => _selectedType = null)),
                      _buildFilterChip('Movie', _selectedType == 'movie', () => setModalState(() => _selectedType = 'movie')),
                      _buildFilterChip('Series', _selectedType == 'series', () => setModalState(() => _selectedType = 'series')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Year', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2024',
                      hintStyle: AppTextStyles.bodySecondary.copyWith(color: Colors.grey[600]),
                      filled: true, fillColor: AppColors.primaryBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.3))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
                    ),
                    onChanged: (val) => setModalState(() => _selectedYear = val.isEmpty ? null : val),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (_currentQuery.isNotEmpty) {
                        _performSearch(_currentQuery, resetPage: true);
                      }
                    },
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text('Apply Filters', style: GoogleFonts.aBeeZee(color: Colors.white, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accent : Colors.grey[600]!),
        ),
        child: Text(label, style: GoogleFonts.aBeeZee(
          color: isSelected ? Colors.white : Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w600,
        )),
      ),
    );
  }

  void _navigateToWatchlist() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistScreen()))
        .then((_) => _loadWatchlistIds());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildTopPanel()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarDelegate(child: _buildSearchSection(), height: 140),
                ),
                ..._buildContentSlivers(),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomCTA()),
        ],
      ),
    );
  }

  Widget _buildTopPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 75, 16, 0),
      child: Container(
        width: double.infinity, height: 195.2,
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          image: const DecorationImage(fit: BoxFit.fill, image: AssetImage('assets/images/Frame2.png')),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25), topRight: Radius.circular(65),
            bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Align(
                  alignment: const AlignmentDirectional(-1, -1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Image.asset('assets/images/Logo_wf.png', width: 200, height: 105.2, fit: BoxFit.fitWidth, alignment: const Alignment(-1, 1)),
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToWatchlist,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset('assets/images/buttonWatchList.png', width: 40, height: 56.6, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: 0.8,
              child: SizedBox(
                width: 150,
                child: Divider(thickness: 1, indent: 45, color: Colors.white.withValues(alpha: 0.5)),
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(-1, 0),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(45, 0, 0, 0),
                child: SizedBox(
                  width: 252.13, height: 59.2,
                  child: Align(
                    alignment: const AlignmentDirectional(-1, -1),
                    child: Text(
                      'Your personal movie watchlist. Track the films you want to watch.',
                      style: GoogleFonts.aBeeZee(fontWeight: FontWeight.w400, color: Colors.grey[600], fontSize: 13, letterSpacing: 0.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 1.5, height: 44, margin: const EdgeInsets.only(right: 10), color: Colors.white.withValues(alpha: 0.4)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search for Your Fav Movie', style: GoogleFonts.aBeeZee(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('Type movie title below', style: GoogleFonts.aBeeZee(color: AppColors.textSecondary, fontSize: 12)),
                        if (_selectedType != null || _selectedYear != null) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() { _selectedType = null; _selectedYear = null; });
                              if (_currentQuery.isNotEmpty) _performSearch(_currentQuery, resetPage: true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(8)),
                              child: Text('Filtered', style: GoogleFonts.aBeeZee(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30), color: AppColors.secondarySurface,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(4, 4), blurRadius: 10),
                  BoxShadow(color: Colors.white.withValues(alpha: 0.05), offset: const Offset(-3, -3), blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)])),
                      child: const Icon(Icons.tune, color: Colors.white, size: 14),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.aBeeZee(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search for movies...',
                        hintStyle: GoogleFonts.aBeeZee(color: Colors.grey[600], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
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

  List<Widget> _buildContentSlivers() {
    if (_isLoading) {
      return [const SliverToBoxAdapter(child: LoadingShimmer())];
    }

    if (_errorMessage != null) {
      return [SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorStateWidget(
          message: _errorMessage!,
          icon: Icons.error_outline,
          onRetry: () => _performSearch(_currentQuery, resetPage: true),
        ),
      )];
    }

    if (_searchController.text.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())];
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return [SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No movies found',
          subtitle: 'No movies found for "${_currentQuery}". Try a different search term.',
        ),
      )];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.58, crossAxisSpacing: 14, mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final movie = _searchResults[index];
            final isInWatchlist = _watchlistIds.contains(movie.imdbId);
            return MovieCard(
              movie: movie,
              isInWatchlist: isInWatchlist,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MovieDetailScreen(imdbId: movie.imdbId, heroTag: 'poster_${movie.imdbId}')),
              ).then((_) => _loadWatchlistIds()),
              onAdd: () => _addToWatchlist(movie),
              onRemove: () => _removeFromWatchlist(movie),
              onToggleWatched: () => _toggleWatched(movie),
            );
          }, childCount: _searchResults.length),
        ),
      ),
      // Load More indicator
      if (_isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
          ),
        ),
      if (_hasMore && !_isLoadingMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: GestureDetector(
                onTap: _loadMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: Text('Load More', style: GoogleFonts.aBeeZee(color: AppColors.accent, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Search history when available
          if (_searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Recent Searches', style: GoogleFonts.aBeeZee(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearSearchHistory,
                    child: Text('Clear All', style: GoogleFonts.aBeeZee(color: AppColors.accent, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _searchHistory.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _searchHistory[index];
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = item;
                      _onSearchChanged(item);
                    },
                    onLongPress: () => _deleteHistoryItem(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, color: Colors.grey[500], size: 14),
                          const SizedBox(width: 6),
                          Text(item, style: GoogleFonts.aBeeZee(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
          // Empty state icon
          Container(
            width: 125, height: 125,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: AppColors.primaryBg,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), offset: const Offset(6, 6), blurRadius: 14),
                BoxShadow(color: Colors.white.withValues(alpha: 0.05), offset: const Offset(-4, -4), blurRadius: 8),
              ],
            ),
            child: Center(child: Image.asset('assets/images/search_icon.png', width: 90, height: 90, color: Colors.white.withValues(alpha: 0.5))),
          ),
          const SizedBox(height: 16),
          Text('Search for any movie to get started', style: GoogleFonts.aBeeZee(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomCTA() {
    return GestureDetector(
      onTap: _navigateToWatchlist,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(80, 8, 80, 24),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)]),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.6), offset: const Offset(6, 6), blurRadius: 16),
              BoxShadow(color: Colors.white.withValues(alpha: 0.05), offset: const Offset(-4, -4), blurRadius: 8),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(2, 2), blurRadius: 4)],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: const Icon(Icons.movie, color: Colors.white, size: 26),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)]),
                  ),
                  child: Text('Your Saved List', style: GoogleFonts.aBeeZee(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _SearchBarDelegate({required this.child, required this.height});

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0A), Color(0xCC0A0A0A), Color(0x800A0A0A), Color(0x000A0A0A)],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) => true;
}
