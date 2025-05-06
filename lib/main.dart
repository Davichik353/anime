import 'package:anime/home/home_scrin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(AnimeExplorerApp());
}

class AnimeExplorerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
