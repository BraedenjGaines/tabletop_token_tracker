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
  bool turnTrackerEnabled = false;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

late SharedPreferences _prefs;

Future<void> _loadPreferences() async {
  _prefs = await SharedPreferences.getInstance();
  setState(() {
    selectedFont = _prefs.getString('selectedFont') ?? 'Sedan';
    selectedGame = _prefs.getString('selectedGame') ?? '';
    skipGameSelect = _prefs.getBool('skipGameSelect') ?? false;
    turnTrackerEnabled = _prefs.getBool('turnTrackerEnabled') ?? false;
    isLoaded = true;
  });
}

Future<void> _saveFont() async {
  await _prefs.setString('selectedFont', selectedFont);
}

Future<void> _saveGamePreferences() async {
  await _prefs.setString('selectedGame', selectedGame);
  await _prefs.setBool('skipGameSelect', skipGameSelect);
}

Future<void> _saveTurnTracker() async {
  await _prefs.setBool('turnTrackerEnabled', turnTrackerEnabled);
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

  void updateTurnTracker(bool enabled) {
    setState(() {
      turnTrackerEnabled = enabled;
    });
    _saveTurnTracker();
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
        turnTrackerEnabled: turnTrackerEnabled,
        onTurnTrackerChanged: updateTurnTracker,
      ),
    );
  }
}