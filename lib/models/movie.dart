class Movie {
  final String imdbId;
  final String title;
  final String year;
  final String poster;
  final String? type;
  final String? plot;
  final String? genre;
  final String? director;
  final String? actors;
  final String? imdbRating;
  final String? runtime;

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
    this.imdbRating,
    this.runtime,
  });

  factory Movie.fromSearchJson(Map<String, dynamic> json) {
    return Movie(
      imdbId: json['imdbID'] ?? '',
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      poster: json['Poster'] ?? '',
      type: json['Type'],
    );
  }

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
      imdbRating: json['imdbRating'],
      runtime: json['Runtime'],
    );
  }

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
      'imdbRating': imdbRating,
      'Runtime': runtime,
    };
  }

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
      imdbRating: json['imdbRating'],
      runtime: json['Runtime'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.imdbId == imdbId;
  }

  @override
  int get hashCode => imdbId.hashCode;
}
