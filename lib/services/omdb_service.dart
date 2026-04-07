import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';

class OmdbService {
  // Note: Users should replace this with their own API key from http://www.omdbapi.com/apikey.aspx
  // Free tier allows 1000 daily requests
  static const String _apiKey = '26800e73';
  static const String _baseUrl = 'https://www.omdbapi.com';

  /// Search for movies by title
  /// Returns a list of movies matching the search query
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/?apikey=$_apiKey&s=${Uri.encodeComponent(query.trim())}&type=movie',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True' && data['Search'] != null) {
          final List<dynamic> searchResults = data['Search'];
          return searchResults
              .map((json) => Movie.fromSearchJson(json))
              .where((movie) => movie.poster != 'N/A')
              .toList();
        } else if (data['Error'] != null) {
          throw Exception(data['Error']);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to search movies: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get detailed information about a specific movie by IMDb ID
  Future<Movie> getMovieDetails(String imdbId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/?apikey=$_apiKey&i=$imdbId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          return Movie.fromDetailJson(data);
        } else if (data['Error'] != null) {
          throw Exception(data['Error']);
        } else {
          throw Exception('Movie not found');
        }
      } else {
        throw Exception(
          'Failed to get movie details: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
