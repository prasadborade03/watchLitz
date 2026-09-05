import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/omdb_service.dart';
import '../services/watchlist_service.dart';
import 'watchlist_screen.dart';

// Design system constants
class AppColors {
  static const Color primaryBg = Color(0xFF0A0A0A);
  static const Color secondarySurface = Color(0xFF121212);
  static const Color accent = Color(0xFFFF5A1F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A0A0);
  static const Color cardSurface = Color(0xFFEDEDED);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OmdbService _omdbService = OmdbService();
  final WatchlistService _watchlistService = WatchlistService();
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  Set<String> _watchlistIds = {};

  @override
  void initState() {
    super.initState();
    _loadWatchlistIds();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWatchlistIds() async {
    final watchlist = await _watchlistService.getWatchlist();
    setState(() {
      _watchlistIds = watchlist.map((m) => m.imdbId).toSet();
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await _omdbService.searchMovies(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
      _loadWatchlistIds();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _addToWatchlist(Movie movie) async {
    final success = await _watchlistService.addToWatchlist(movie);
    if (success) {
      setState(() {
        _watchlistIds.add(movie.imdbId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${movie.title}" added to watchlist',
              style: GoogleFonts.aBeeZee(),
            ),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeFromWatchlist(Movie movie) async {
    await _watchlistService.removeFromWatchlist(movie.imdbId);
    setState(() {
      _watchlistIds.remove(movie.imdbId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${movie.title}" removed from watchlist',
            style: GoogleFonts.aBeeZee(),
          ),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToWatchlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WatchlistScreen()),
    ).then((_) {
      _loadWatchlistIds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildTopPanel()),
                SliverToBoxAdapter(child: const SizedBox(height: 20)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarDelegate(
                    child: _buildSearchSection(),
                    height: 140,
                  ),
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
        width: double.infinity,
        height: 195.2,
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          image: const DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage('assets/images/Frame2.png'),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(65),
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
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
                    child: Image.asset(
                      'assets/images/Logo_wf.png',
                      width: 200,
                      height: 105.2,
                      fit: BoxFit.fitWidth,
                      alignment: const Alignment(-1, 1),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _navigateToWatchlist,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/buttonWatchList.png',
                      width: 40,
                      height: 56.6,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            Opacity(
              opacity: 0.8,
              child: SizedBox(
                width: 150,
                child: Divider(
                  thickness: 1,
                  indent: 45,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            Align(
              alignment: const AlignmentDirectional(-1, 0),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(45, 0, 0, 0),
                child: SizedBox(
                  width: 252.13,
                  height: 59.2,
                  child: Align(
                    alignment: const AlignmentDirectional(-1, -1),
                    child: Text(
                      'SavE your Watch list ~ale hi janaa he nazar churaake yun phir thami thi saajan tumne meri kalai kyon kisi ko apana bana ke chhod de aisa koyi nahin karthaa sha, sha, sha, sha bahon main ch',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: 10,
                        letterSpacing: 0.0,
                      ),
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
                Container(
                  width: 1.5,
                  height: 44,
                  margin: const EdgeInsets.only(right: 10),
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search for Your Fav Movie',
                      style: GoogleFonts.aBeeZee(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type Movie title below',
                      style: GoogleFonts.aBeeZee(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
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
                borderRadius: BorderRadius.circular(30),
                color: AppColors.secondarySurface,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: GoogleFonts.aBeeZee(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for movies...',
                        hintStyle: GoogleFonts.aBeeZee(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[500],
                                  size: 18,
                                ),
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
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.accent.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.aBeeZee(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (_searchController.text.isEmpty) {
      return [
        SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState()),
      ];
    }

    if (_searchResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 80, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'No movies found',
                  style: GoogleFonts.aBeeZee(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: GoogleFonts.aBeeZee(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.58,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final movie = _searchResults[index];
            final isInWatchlist = _watchlistIds.contains(movie.imdbId);
            return _buildMovieCard(movie, isInWatchlist);
          }, childCount: _searchResults.length),
        ),
      ),
    ];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 125,
            height: 125,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBg,
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
            child: Center(
              child: Image.asset(
                'assets/images/search_icon.png',
                width: 90,
                height: 90,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Movie movie, bool isInWatchlist) {
    return Container(
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
                    ? Image.network(
                        movie.poster,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.movie,
                              size: 50,
                              color: Colors.grey[500],
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
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
                  isInWatchlist
                      ? _buildRemoveButton(movie)
                      : _buildAddButton(movie),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Movie movie) {
    return GestureDetector(
      onTap: () => _addToWatchlist(movie),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 34,
        width: 100,
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveButton(Movie movie) {
    return GestureDetector(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Image.asset(
                      'assets/images/cine_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sliver delegate that pins the search section as a sticky header
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _SearchBarDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xCC0A0A0A),
            Color(0x800A0A0A),
            Color(0x000A0A0A),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate oldDelegate) => true;
}
