import 'package:flutter/material.dart';
import 'package:gooble_goblin/features/auth/auth_gaurd.dart';
import 'package:gooble_goblin/features/experiment/exp1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const StackedCardsApp());
}

class StackedCardsApp extends StatefulWidget {
  const StackedCardsApp({super.key});

  @override
  State<StackedCardsApp> createState() => _StackedCardsAppState();
}

class _StackedCardsAppState extends State<StackedCardsApp> {
  SharedPreferences? prefs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ToastificationWrapper(
      child: MaterialApp(
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
        home: const AuthScreen(),
      ),
    );
  }
}
