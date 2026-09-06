import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movie.dart';

// ── Custom Exceptions ──────────────────────────────────────────────────────────

class OmdbException implements Exception {
  final String message;
  final int? statusCode;
  OmdbException(this.message, {this.statusCode});

  @override
  String toString() => 'OmdbException: $message';
}

class MovieNotFoundException extends OmdbException {
  MovieNotFoundException([String message = 'Movie not found']) : super(message);
}

class ApiKeyInvalidException extends OmdbException {
  ApiKeyInvalidException([String message = 'Invalid API key. Check your .env file.']) : super(message);
}

class RateLimitExceededException extends OmdbException {
  RateLimitExceededException([String message = 'API rate limit exceeded. Try again later.']) : super(message);
}

class NetworkException extends OmdbException {
  NetworkException([String message = 'Network error. Please check your internet connection.']) : super(message);
}

class ServerErrorException extends OmdbException {
  ServerErrorException([String message = 'Server error. Please try again in a moment.', int? statusCode]) : super(message, statusCode: statusCode);
}

// ── Search Response Model ──────────────────────────────────────────────────────

class OmdbSearchResponse {
  final List<Movie> movies;
  final int totalResults;
  final int currentPage;
  int get totalPages => (totalResults / 10).ceil();
  bool get hasMorePages => currentPage < totalPages;

  const OmdbSearchResponse({
    required this.movies,
    required this.totalResults,
    required this.currentPage,
  });

  OmdbSearchResponse merge(OmdbSearchResponse next) {
    return OmdbSearchResponse(
      movies: [...movies, ...next.movies],
      totalResults: totalResults,
      currentPage: next.currentPage,
    );
  }
}

// ── OMDb Service ───────────────────────────────────────────────────────────────

class OmdbService {
  static const String _baseUrl = 'https://www.omdbapi.com';

  /// Get the API key from environment, supporting both key names
  String get _apiKey {
    final key = dotenv.env['OMDB_API_KEY'] ?? dotenv.env['OMDb_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw ApiKeyInvalidException(
        'OMDb API key not found. Create a .env file with:\n'
        'OMDB_API_KEY=your_key_here\n\n'
        'Get a free key at: https://www.omdbapi.com/apikey.aspx',
      );
    }
    return key;
  }

  /// Search for movies by title with pagination support
  Future<OmdbSearchResponse> searchMovies(
    String query, {
    int page = 1,
    String? type,
    String? year,
  }) async {
    if (query.trim().isEmpty) {
      return const OmdbSearchResponse(
        movies: [],
        totalResults: 0,
        currentPage: 1,
      );
    }

    final uri = Uri.parse('$_baseUrl/').replace(
      queryParameters: {
        'apikey': _apiKey,
        's': query.trim(),
        'page': page.toString(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (year != null && year.isNotEmpty) 'y': year,
      },
    );

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw NetworkException(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True' && data['Search'] != null) {
          final List<dynamic> searchResults = data['Search'];
          final movies = searchResults
              .map((json) => Movie.fromSearchJson(json))
              .where((movie) => movie.hasValidPoster)
              .toList();

          final totalResults = int.tryParse(data['totalResults'] ?? '0') ?? 0;

          return OmdbSearchResponse(
            movies: movies,
            totalResults: totalResults,
            currentPage: page,
          );
        } else if (data['Error'] != null) {
          final error = data['Error'] as String;
          if (error.toLowerCase().contains('movie not found') ||
              error.toLowerCase().contains('no results')) {
            return const OmdbSearchResponse(
              movies: [],
              totalResults: 0,
              currentPage: 1,
            );
          }
          throw OmdbException(error);
        } else {
          return const OmdbSearchResponse(
            movies: [],
            totalResults: 0,
            currentPage: 1,
          );
        }
      } else if (response.statusCode == 401) {
        throw ApiKeyInvalidException();
      } else if (response.statusCode == 429) {
        throw RateLimitExceededException();
      } else if (response.statusCode >= 500) {
        throw ServerErrorException('Server error', response.statusCode);
      } else {
        throw OmdbException(
          'Failed to search movies',
          statusCode: response.statusCode,
        );
      }
    } on OmdbException {
      rethrow;
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException();
    }
  }

  /// Get detailed information about a specific movie by IMDb ID
  Future<Movie> getMovieDetails(String imdbId) async {
    if (imdbId.trim().isEmpty) {
      throw MovieNotFoundException('Invalid IMDb ID');
    }

    final uri = Uri.parse('$_baseUrl/').replace(
      queryParameters: {
        'apikey': _apiKey,
        'i': imdbId.trim(),
        'plot': 'full',
      },
    );

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw NetworkException(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          return Movie.fromDetailJson(data);
        } else if (data['Error'] != null) {
          final error = data['Error'] as String;
          if (error.toLowerCase().contains('movie not found') ||
              error.toLowerCase().contains('incorrect imdbid')) {
            throw MovieNotFoundException();
          }
          throw OmdbException(error);
        } else {
          throw MovieNotFoundException();
        }
      } else if (response.statusCode == 401) {
        throw ApiKeyInvalidException();
      } else if (response.statusCode == 429) {
        throw RateLimitExceededException();
      } else if (response.statusCode >= 500) {
        throw ServerErrorException('Server error', response.statusCode);
      } else {
        throw OmdbException(
          'Failed to get movie details',
          statusCode: response.statusCode,
        );
      }
    } on OmdbException {
      rethrow;
    } catch (e) {
      if (e is NetworkException) rethrow;
      throw NetworkException();
    }
  }
}
