import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String selectedFont = 'Sedan';
  String selectedGame = '';
  bool skipGameSelect = false;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFont = prefs.getString('selectedFont') ?? 'Sedan';
      selectedGame = prefs.getString('selectedGame') ?? '';
      skipGameSelect = prefs.getBool('skipGameSelect') ?? false;
      isLoaded = true;
    });
  }

  Future<void> _saveFont() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', selectedFont);
  }

  Future<void> _saveGamePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedGame', selectedGame);
    await prefs.setBool('skipGameSelect', skipGameSelect);
  }

  void updateFont(String newFont) {
    setState(() {
      selectedFont = newFont;
    });
    _saveFont();
  }

  void updateGame(String newGame, bool skip) {
    setState(() {
      selectedGame = newGame;
      skipGameSelect = skip;
    });
    _saveGamePreferences();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      title: 'TableTop Token Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: selectedFont,
      ),
      home: HomeScreen(
        selectedFont: selectedFont,
        onFontChanged: updateFont,
        selectedGame: selectedGame,
        skipGameSelect: skipGameSelect,
        onGameChanged: updateGame,
      ),
    );
  }
}