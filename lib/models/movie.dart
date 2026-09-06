/// Enum representing the state of a movie in the watchlist context
enum MovieWatchState {
  /// Movie is not in any list (shown in search results with "ADD" button)
  notInList,

  /// Movie is saved but not watched (red minus icon, "Mark as Watched" button)
  toWatch,

  /// Movie has been watched (green checkmark, "Unmark" button)
  watched,
}

class Movie {
  final String imdbId;
  final String title;
  final String year;
  final String poster;
  final String? type;

  // OMDb detail fields
  final String? plot;
  final String? genre;
  final String? director;
  final String? actors;
  final String? writer;
  final String? runtime;
  final String? released;
  final String? imdbRating;
  final String? metascore;
  final String? language;
  final String? country;
  final String? awards;
  final String? rated;

  // Watchlist-specific fields
  bool isWatched;
  DateTime? dateAdded;

  Movie({
    required this.imdbId,
    required this.title,
    required this.year,
    required this.poster,
    this.type,
    this.plot,
    this.genre,
    this.director,
    this.actors,
    this.writer,
    this.runtime,
    this.released,
    this.imdbRating,
    this.metascore,
    this.language,
    this.country,
    this.awards,
    this.rated,
    this.isWatched = false,
    DateTime? dateAdded,
  }) : dateAdded = dateAdded ?? DateTime.now();

  /// Factory constructor for OMDb search results (limited fields)
  factory Movie.fromSearchJson(Map<String, dynamic> json) {
    return Movie(
      imdbId: json['imdbID'] ?? '',
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      poster: json['Poster'] ?? '',
      type: json['Type'],
    );
  }

  /// Factory constructor for OMDb detail responses (all fields)
  factory Movie.fromDetailJson(Map<String, dynamic> json) {
    return Movie(
      imdbId: json['imdbID'] ?? '',
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      poster: json['Poster'] ?? '',
      type: json['Type'],
      plot: json['Plot'],
      genre: json['Genre'],
      director: json['Director'],
      actors: json['Actors'],
      writer: json['Writer'],
      runtime: json['Runtime'],
      released: json['Released'],
      imdbRating: json['imdbRating'],
      metascore: json['Metascore'],
      language: json['Language'],
      country: json['Country'],
      awards: json['Awards'],
      rated: json['Rated'],
    );
  }

  /// Factory constructor for loading from SharedPreferences JSON
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      imdbId: json['imdbID'] ?? '',
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      poster: json['Poster'] ?? '',
      type: json['Type'],
      plot: json['Plot'],
      genre: json['Genre'],
      director: json['Director'],
      actors: json['Actors'],
      writer: json['Writer'],
      runtime: json['Runtime'],
      released: json['Released'],
      imdbRating: json['imdbRating'],
      metascore: json['Metascore'],
      language: json['Language'],
      country: json['Country'],
      awards: json['Awards'],
      rated: json['Rated'],
      isWatched: json['isWatched'] ?? false,
      dateAdded: json['dateAdded'] != null
          ? DateTime.tryParse(json['dateAdded'])
          : null,
    );
  }

  /// Serialize to JSON for SharedPreferences persistence
  Map<String, dynamic> toJson() {
    return {
      'imdbID': imdbId,
      'Title': title,
      'Year': year,
      'Poster': poster,
      'Type': type,
      'Plot': plot,
      'Genre': genre,
      'Director': director,
      'Actors': actors,
      'Writer': writer,
      'Runtime': runtime,
      'Released': released,
      'imdbRating': imdbRating,
      'Metascore': metascore,
      'Language': language,
      'Country': country,
      'Awards': awards,
      'Rated': rated,
      'isWatched': isWatched,
      'dateAdded': dateAdded?.toIso8601String(),
    };
  }

  /// Create a copy with optional field overrides
  Movie copyWith({
    String? imdbId,
    String? title,
    String? year,
    String? poster,
    String? type,
    String? plot,
    String? genre,
    String? director,
    String? actors,
    String? writer,
    String? runtime,
    String? released,
    String? imdbRating,
    String? metascore,
    String? language,
    String? country,
    String? awards,
    String? rated,
    bool? isWatched,
    DateTime? dateAdded,
  }) {
    return Movie(
      imdbId: imdbId ?? this.imdbId,
      title: title ?? this.title,
      year: year ?? this.year,
      poster: poster ?? this.poster,
      type: type ?? this.type,
      plot: plot ?? this.plot,
      genre: genre ?? this.genre,
      director: director ?? this.director,
      actors: actors ?? this.actors,
      writer: writer ?? this.writer,
      runtime: runtime ?? this.runtime,
      released: released ?? this.released,
      imdbRating: imdbRating ?? this.imdbRating,
      metascore: metascore ?? this.metascore,
      language: language ?? this.language,
      country: country ?? this.country,
      awards: awards ?? this.awards,
      rated: rated ?? this.rated,
      isWatched: isWatched ?? this.isWatched,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  /// Convenience getter for clean poster URL
  String get posterUrl => poster;

  /// Check if poster is valid and loadable
  bool get hasValidPoster => poster.isNotEmpty && poster != 'N/A';

  /// Parse IMDb rating as double, returns null if unavailable
  double? get imdbRatingDouble {
    if (imdbRating == null || imdbRating == 'N/A') return null;
    return double.tryParse(imdbRating!);
  }

  /// Check if poster is in watchlist context (used by the card)
  /// This is determined externally by checking against the watchlist, not stored on the model.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.imdbId == imdbId;
  }

  @override
  int get hashCode => imdbId.hashCode;
}
