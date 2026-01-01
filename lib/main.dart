import 'package:flutter/material.dart';
import 'package:gooble_goblin/features/home/home_screen.dart';

void main() {
  runApp(const StackedCardsApp());
}

class StackedCardsApp extends StatefulWidget {
  const StackedCardsApp({super.key});

  @override
  State<StackedCardsApp> createState() => _StackedCardsAppState();
}

class _StackedCardsAppState extends State<StackedCardsApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stacked Cards Chain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213e),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

