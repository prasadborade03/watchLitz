# WatchLitz

A modern, clean movie watchlist application designed for film lovers to manage their interests. Built with Flutter, it features a custom dark neumorphic UI and leverages the **OMDb API** to fetch real-time movie details like title, year, genre, director, actors, runtime, and IMDb ratings.

## Features
- Search movies with real-time results (powered by OMDb API).
- Save movies to a persistent local watchlist.
- View detailed movie information.
- Smooth offline viewing of cached movie posters and watchlist data.

## Setup Instructions

### 1. Obtain an OMDb API Key
This app requires a free OMDb API key to fetch movie data.
1. Go to [omdbapi.com/apikey.aspx](http://www.omdbapi.com/apikey.aspx)
2. Select "FREE!" and enter your email address.
3. Check your email for the activation link and your new API key.

### 2. Configure Environment Variables
1. Clone the repository.
2. In the root directory, create a file named .env (you can copy .env.example).
3. Add your OMDb API key to the .env file:
   `env
   OMDB_API_KEY=your_actual_api_key_here
   `

### 3. Run the App
`ash
flutter pub get
flutter run
`

## Screenshots
<!-- screenshot here -->

## Tech Stack
- Flutter
- lutter_dotenv for environment variables
