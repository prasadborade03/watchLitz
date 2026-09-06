import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

/// Reactive watchlist service using ChangeNotifier for state management
/// Persists to SharedPreferences on every mutation
class WatchlistService extends ChangeNotifier {
  static const String _watchlistKey = 'movie_watchlist';

  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal();

  SharedPreferences? _prefs;
  List<Movie> _watchlist = [];
  bool _isLoading = false;
  String? _error;

  /// Current watchlist
  List<Movie> get watchlist => List.unmodifiable(_watchlist);

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Watch count (movies not yet watched)
  int get toWatchCount => _watchlist.where((m) => !m.isWatched).length;

  /// Watched count
  int get watchedCount => _watchlist.where((m) => m.isWatched).length;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load watchlist from SharedPreferences
  Future<void> loadWatchlist() async {
    await _initPrefs();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String? watchlistJson = _prefs!.getString(_watchlistKey);
      if (watchlistJson == null || watchlistJson.isEmpty) {
        _watchlist = [];
      } else {
        final List<dynamic> decoded = json.decode(watchlistJson);
        _watchlist = decoded.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      _watchlist = [];
      _error = 'Failed to load watchlist';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get all movies from the watchlist (legacy async method)
  Future<List<Movie>> getWatchlist() async {
    await _initPrefs();

    final String? watchlistJson = _prefs!.getString(_watchlistKey);
    if (watchlistJson == null || watchlistJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(watchlistJson);
      final list = decoded.map((json) => Movie.fromJson(json)).toList();
      _watchlist = list;
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Add a movie to the watchlist
  Future<bool> addToWatchlist(Movie movie) async {
    await _initPrefs();

    if (_watchlist.any((m) => m.imdbId == movie.imdbId)) {
      return false;
    }

    _watchlist.add(movie);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Remove a movie from the watchlist by IMDb ID
  Future<bool> removeFromWatchlist(String imdbId) async {
    await _initPrefs();

    _watchlist.removeWhere((m) => m.imdbId == imdbId);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Update a movie in the watchlist (for personal rating, notes, watched status)
  Future<void> updateMovie(Movie updatedMovie) async {
    await _initPrefs();

    final index = _watchlist.indexWhere((m) => m.imdbId == updatedMovie.imdbId);
    if (index != -1) {
      _watchlist[index] = updatedMovie;
      await _persist();
      notifyListeners();
    }
  }

  /// Toggle watched status
  Future<void> toggleWatched(String imdbId) async {
    await _initPrefs();

    final index = _watchlist.indexWhere((m) => m.imdbId == imdbId);
    if (index != -1) {
      _watchlist[index].isWatched = !_watchlist[index].isWatched;
      await _persist();
      notifyListeners();
    }
  }

  /// Update personal rating for a movie
  Future<void> updatePersonalRating(String imdbId, double? rating) async {
    final index = _watchlist.indexWhere((m) => m.imdbId == imdbId);
    if (index != -1) {
      _watchlist[index].personalRating = rating;
      await _persist();
      notifyListeners();
    }
  }

  /// Update personal notes for a movie
  Future<void> updatePersonalNotes(String imdbId, String? notes) async {
    final index = _watchlist.indexWhere((m) => m.imdbId == imdbId);
    if (index != -1) {
      _watchlist[index].personalNotes = notes;
      await _persist();
      notifyListeners();
    }
  }

  /// Batch: set watched status for multiple movies
  Future<void> setWatchedBatch(List<String> imdbIds, bool isWatched) async {
    for (final id in imdbIds) {
      final index = _watchlist.indexWhere((m) => m.imdbId == id);
      if (index != -1) _watchlist[index].isWatched = isWatched;
    }
    await _persist();
    notifyListeners();
  }

  /// Batch: delete multiple movies
  Future<void> deleteBatch(List<String> imdbIds) async {
    _watchlist.removeWhere((m) => imdbIds.contains(m.imdbId));
    await _persist();
    notifyListeners();
  }

  /// Check if a movie is in the watchlist
  Future<bool> isInWatchlist(String imdbId) async {
    await _initPrefs();
    final list = await getWatchlist();
    return list.any((m) => m.imdbId == imdbId);
  }

  /// Clear all movies from the watchlist
  Future<bool> clearWatchlist() async {
    await _initPrefs();
    _watchlist.clear();
    final success = await _prefs!.remove(_watchlistKey);
    notifyListeners();
    return success;
  }

  /// Get the count of movies in watchlist
  Future<int> getWatchlistCount() async {
    final list = await getWatchlist();
    return list.length;
  }

  /// Persist current watchlist to SharedPreferences
  Future<void> _persist() async {
    await _initPrefs();
    final String encoded = json.encode(
      _watchlist.map((m) => m.toJson()).toList(),
    );
    await _prefs!.setString(_watchlistKey, encoded);
  }
}
