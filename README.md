# WatchLitz

**Track the movies you want to watch.**

WatchLitz is a beautifully designed Flutter app for managing your personal movie watchlist. Search for movies, save them to your list, mark them as watched, and keep track of your personal ratings and notes.

## Features

- **Movie Search** - Search the entire OMDb database with debounced real-time results
- **Detailed Information** - View plot, cast, director, ratings, genre, runtime, awards, and more
- **Personal Watchlist** - Save movies you want to watch with persistent local storage
- **Track Progress** - Mark movies as watched or unwatched with visual indicators
- **Your Ratings** - Rate movies on a 1-10 star scale
- **Personal Notes** - Add your thoughts, reminders, and observations
- **Smart Sorting** - Sort by date added, title, year, IMDb rating, or personal rating
- **Tab Filtering** - Filter between All, To Watch, and Watched movies
- **Batch Actions** - Select multiple movies and perform bulk operations
- **Swipe Gestures** - Swipe to toggle watched status or delete with undo
- **Search History** - Quickly re-run past searches from history chips
- **Type Filters** - Filter search results by Movies or Series
- **Image Caching** - Movie posters load faster with offline caching
- **Share** - Share movie details with friends via the share button
- **Dark Theme** - Stunning dark neumorphic design with orange accent

## Screenshots

<!-- Add screenshots here -->

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **OMDb API** - Movie data source
- **flutter_dotenv** - Environment variable management
- **cached_network_image** - Image caching and loading
- **shimmer** - Skeleton loading animations
- **share_plus** - Native sharing functionality
- **connectivity_plus** - Network status detection
- **google_fonts** - Custom typography
- **shared_preferences** - Local data persistence

## Setup Instructions

### 1. Obtain an OMDb API Key

This app requires a free OMDb API key to fetch movie data.

1. Go to https://www.omdbapi.com/apikey.aspx
2. Select "FREE!" and enter your email address
3. Check your email for the activation link and your API key
4. Free tier allows 1,000 requests per day

### 2. Configure Environment Variables

1. Clone the repository
2. In the root directory, create a file named `.env`:
   ```
   cp .env.example .env
   ```
3. Add your OMDb API key to the `.env` file:
   ```
   OMDB_API_KEY=your_actual_api_key_here
   ```

**Never commit your `.env` file to version control!**

### 3. Run the App

```
flutter pub get
flutter run
```

## Architecture

```
lib/
  main.dart                 # App entry point
  models/
    movie.dart              # Movie data model with serialization
  screens/
    home_screen.dart        # Search screen with pagination
    movie_detail_screen.dart # Full movie details
    watchlist_screen.dart   # Watchlist with tabs and sorting
  services/
    omdb_service.dart       # OMDb API client with error handling
    watchlist_service.dart  # Local storage (ChangeNotifier)
  theme/
    app_theme.dart          # Colors, shadows, text styles
  widgets/
    movie_card.dart         # Reusable movie card
    movie_poster.dart       # Cached poster with Hero support
    rating_badge.dart       # Color-coded IMDb rating pill
    star_rating.dart        # Interactive 1-10 star rating
    neumorphic_container.dart # Neumorphic card container
    loading_shimmer.dart    # Skeleton loading animation
    empty_state_widget.dart # Empty state display
    error_state_widget.dart # Error state with retry
```

## Design Language

- **Theme**: Dark neumorphic design
- **Primary BG**: #0A0A0A
- **Secondary Surface**: #121212
- **Accent**: #FF5A1F (vibrant orange)
- **Typography**: ABeeZee (Google Fonts)
- **Shadows**: Soft neumorphic offsets with light/dark pairs

## License

This project is for personal use. All movie data is provided by the OMDb API.
