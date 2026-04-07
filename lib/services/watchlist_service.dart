import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class WatchlistService {
  static const String _watchlistKey = 'movie_watchlist';

  static final WatchlistService _instance = WatchlistService._internal();
  factory WatchlistService() => _instance;
  WatchlistService._internal();

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get all movies from the watchlist
  Future<List<Movie>> getWatchlist() async {
    await _initPrefs();

    final String? watchlistJson = _prefs!.getString(_watchlistKey);
    if (watchlistJson == null || watchlistJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(watchlistJson);
      return decoded.map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a movie to the watchlist
  Future<bool> addToWatchlist(Movie movie) async {
    await _initPrefs();

    final List<Movie> currentWatchlist = await getWatchlist();

    // Check if movie already exists
    if (currentWatchlist.any((m) => m.imdbId == movie.imdbId)) {
      return false; // Movie already in watchlist
    }

    currentWatchlist.add(movie);

    final String encoded = json.encode(
      currentWatchlist.map((m) => m.toJson()).toList(),
    );

    return await _prefs!.setString(_watchlistKey, encoded);
  }

  /// Remove a movie from the watchlist by IMDb ID
  Future<bool> removeFromWatchlist(String imdbId) async {
    await _initPrefs();

    final List<Movie> currentWatchlist = await getWatchlist();
    currentWatchlist.removeWhere((m) => m.imdbId == imdbId);

    final String encoded = json.encode(
      currentWatchlist.map((m) => m.toJson()).toList(),
    );

    return await _prefs!.setString(_watchlistKey, encoded);
  }

  /// Check if a movie is in the watchlist
  Future<bool> isInWatchlist(String imdbId) async {
    await _initPrefs();

    final List<Movie> currentWatchlist = await getWatchlist();
    return currentWatchlist.any((m) => m.imdbId == imdbId);
  }

  /// Clear all movies from the watchlist
  Future<bool> clearWatchlist() async {
    await _initPrefs();
    return await _prefs!.remove(_watchlistKey);
  }

  /// Get the count of movies in watchlist
  Future<int> getWatchlistCount() async {
    final List<Movie> watchlist = await getWatchlist();
    return watchlist.length;
  }
}
