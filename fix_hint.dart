import 'dart:io';

void main() {
  final path = 'lib/screens/home_screen.dart';
  final file = File(path);
  String content = file.readAsStringSync();
  
  content = content.replaceFirst("hintText: 'Search kr for a Content.',", "hintText: 'Search for movies...',");
  
  file.writeAsStringSync(content);
}
