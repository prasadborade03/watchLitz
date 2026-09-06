import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/watchlist_service.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/empty_state_widget.dart';
import 'movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistService _watchlistService = WatchlistService();
  List<Movie> _watchlist = [];
  bool _isLoading = true;

  // Tab state
  int _selectedTab = 0; // 0: All, 1: To Watch, 2: Watched

  // Sort state
  int _sortBy = 0; // 0: Date Added, 1: Title A-Z, 2: Year, 3: IMDb Rating

  // Batch selection
  bool _isBatchMode = false;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    setState(() => _isLoading = true);
    final w = await _watchlistService.getWatchlist();
    setState(() {
      _watchlist = w;
      _isLoading = false;
    });
  }

  List<Movie> get _filteredWatchlist {
    List<Movie> f;
    switch (_selectedTab) {
      case 1:
        f = _watchlist.where((m) => !m.isWatched).toList();
        break;
      case 2:
        f = _watchlist.where((m) => m.isWatched).toList();
        break;
      default:
        f = List.from(_watchlist);
    }
    switch (_sortBy) {
      case 0:
        f.sort((a, b) => (b.dateAdded ?? DateTime(0))
            .compareTo(a.dateAdded ?? DateTime(0)));
        break;
      case 1:
        f.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 2:
        f.sort((a, b) => b.year.compareTo(a.year));
        break;
      case 3:
        f.sort((a, b) =>
            (double.tryParse(b.imdbRating ?? '0') ?? 0)
                .compareTo(double.tryParse(a.imdbRating ?? '0') ?? 0));
        break;
    }
    return f;
  }

  void _showSortSheet() {
    final labels = [
      'Date Added (Newest)',
      'Title (A-Z)',
      'Year (Newest)',
      'IMDb Rating',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondarySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Sort By',
                  style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              ...List.generate(labels.length, (i) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortBy = i);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _sortBy == i
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(
                        _sortBy == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            _sortBy == i ? AppColors.accent : Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(labels[i],
                          style: AppTextStyles.body.copyWith(
                              color: _sortBy == i
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontWeight: _sortBy == i
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ]),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _toggleBatchMode() {
    setState(() {
      _isBatchMode = !_isBatchMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _batchMarkWatched() async {
    await _watchlistService.setWatchedBatch(_selectedIds.toList(), true);
    setState(() {
      _isBatchMode = false;
      _selectedIds.clear();
    });
    _loadWatchlist();
  }

  void _batchMarkUnwatched() async {
    await _watchlistService.setWatchedBatch(_selectedIds.toList(), false);
    setState(() {
      _isBatchMode = false;
      _selectedIds.clear();
    });
    _loadWatchlist();
  }

  void _batchDelete() async {
    await _watchlistService.deleteBatch(_selectedIds.toList());
    setState(() {
      _isBatchMode = false;
      _selectedIds.clear();
    });
    _loadWatchlist();
  }

  void _toggleWatched(Movie movie) async {
    await _watchlistService.toggleWatched(movie.imdbId);
    _loadWatchlist();
  }

  Future<void> _removeFromWatchlist(Movie movie) async {
    await _watchlistService.removeFromWatchlist(movie.imdbId);
    _loadWatchlist();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(movie.title + ' removed from watchlist',
            style: GoogleFonts.aBeeZee()),
        backgroundColor: const Color(0xFFFF6B35),
        duration: const Duration(seconds: 2),
      ));
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
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 12),
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
                child: const Icon(Icons.movie_filter,
                    color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)],
                  ),
                ),
                child: Text('Your Saved List',
                    style: GoogleFonts.aBeeZee(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab bar with centered text and proper padding
  Widget _buildTabBar() {
    final tabs = ['All', 'To Watch', 'Watched'];
    final counts = [
      _watchlist.length,
      _watchlistService.toWatchCount,
      _watchlistService.watchedCount,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF5A1F)]) : null,
                  color: sel ? null : AppColors.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    tabs[i] + ' (' + counts[i].toString() + ')',
                    style: GoogleFonts.aBeeZee(
                      color: sel ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.accent));
    }
    final filtered = _filteredWatchlist;
    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.bookmark_border,
        title: _selectedTab == 2
            ? 'No watched movies'
            : _selectedTab == 1
                ? 'All caught up!'
                : 'Your watchlist is empty',
        subtitle: 'Search for movies and add them here',
        actionLabel: _selectedTab == 0 ? 'Search Movies' : null,
        onAction: _selectedTab == 0 ? () => Navigator.pop(context) : null,
      );
    }

    return Column(
      children: [
        // Sort bar + multi-select toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showSortSheet,
                child: Row(
                  children: [
                    Icon(Icons.sort, color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 4),
                    Text('Sort',
                        style: GoogleFonts.aBeeZee(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Spacer(),
              if (_isBatchMode) ...[
                GestureDetector(
                  onTap: _batchMarkWatched,
                  child: Icon(Icons.check_circle,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _batchMarkUnwatched,
                  child: Icon(Icons.unpublished,
                      color: Colors.grey[500], size: 20),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _batchDelete,
                  child: Icon(Icons.delete, color: Colors.red[400], size: 20),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _toggleBatchMode,
                  child: Icon(Icons.close,
                      color: AppColors.textSecondary, size: 20),
                ),
              ],
              // TAP to enter multi-select mode (not long press)
              if (!_isBatchMode)
                GestureDetector(
                  onTap: _toggleBatchMode,
                  child: Icon(Icons.select_all,
                      color: AppColors.textSecondary, size: 20),
                ),
            ],
          ),
        ),
        // Movie grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, index) {
              final movie = filtered[index];
              return Dismissible(
                key: Key(movie.imdbId),
                confirmDismiss: (dir) async {
                  if (dir == DismissDirection.startToEnd) {
                    // Swipe right: toggle watched status
                    await _watchlistService.toggleWatched(movie.imdbId);
                    _loadWatchlist();
                    return false;
                  } else {
                    // Swipe left: remove from watchlist
                    _removeFromWatchlist(movie);
                    return true;
                  }
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: movie.isWatched
                        ? Colors.blue[900]
                        : const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    movie.isWatched ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                  ),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red[900],
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Stack(
                  children: [
                    MovieCard(
                      movie: movie,
                      isInWatchlist: true,
                      onTap: () {
                        if (_isBatchMode) {
                          _toggleSelect(movie.imdbId);
                        } else {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailScreen(
                                imdbId: movie.imdbId,
                                heroTag: 'poster_${movie.imdbId}',
                              ),
                            ),
                          ).then((_) => _loadWatchlist());
                        }
                      },
                      onRemove: () => _removeFromWatchlist(movie),
                      onToggleWatched: () => _toggleWatched(movie),
                    ),
                    // Batch selection checkbox overlay
                    if (_isBatchMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _toggleSelect(movie.imdbId),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _selectedIds.contains(movie.imdbId)
                                  ? AppColors.accent
                                  : Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: _selectedIds.contains(movie.imdbId)
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
