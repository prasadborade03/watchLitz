import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_watchlist_app/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    dotenv.testLoad(fileInput: '''OMDB_API_KEY=test''');
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MovieWatchlistApp());
    await tester.pumpAndSettle();

    expect(find.text('Search for movies...'), findsOneWidget);
  });
}
