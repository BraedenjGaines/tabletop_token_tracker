import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String selectedFont = 'Sedan';
  String selectedGame = 'fab';
  bool turnTrackerEnabled = false;
  bool isLoaded = false;
  bool frostedGlass = false;
  ThemeMode themeMode = ThemeMode.system;
  int matchTimerMinutes = 50;
  int firstTurnSetting = 2; // 0=Player1, 1=Player2, 2=Random

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
      selectedGame = _prefs.getString('selectedGame') ?? 'fab';
      turnTrackerEnabled = _prefs.getBool('turnTrackerEnabled') ?? false;
      frostedGlass = _prefs.getBool('frostedGlass') ?? false;
      themeMode = ThemeMode.values[_prefs.getInt('themeMode') ?? 0];
      matchTimerMinutes = _prefs.getInt('matchTimerMinutes') ?? 50;
      firstTurnSetting = _prefs.getInt('firstTurnSetting') ?? 2;
      isLoaded = true;
    });
  }

  Future<void> _saveFont() async {
    await _prefs.setString('selectedFont', selectedFont);
  }

  Future<void> _saveTurnTracker() async {
    await _prefs.setBool('turnTrackerEnabled', turnTrackerEnabled);
  }

  Future<void> _saveFrostedGlass() async {
    await _prefs.setBool('frostedGlass', frostedGlass);
  }

  Future<void> _saveThemeMode() async {
    await _prefs.setInt('themeMode', themeMode.index);
  }

  Future<void> _saveMatchTimer() async {
    await _prefs.setInt('matchTimerMinutes', matchTimerMinutes);
  }

  Future<void> _saveFirstTurnSetting() async {
    await _prefs.setInt('firstTurnSetting', firstTurnSetting);
  }

  void updateFont(String newFont) {
    setState(() { selectedFont = newFont; });
    _saveFont();
  }

  void updateFrostedGlass(bool enabled) {
    setState(() { frostedGlass = enabled; });
    _saveFrostedGlass();
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() { themeMode = mode; });
    _saveThemeMode();
  }

  void updateTurnTracker(bool enabled) {
    setState(() { turnTrackerEnabled = enabled; });
    _saveTurnTracker();
  }

  void updateMatchTimer(int minutes) {
    setState(() { matchTimerMinutes = minutes; });
    _saveMatchTimer();
  }

  void updateFirstTurnSetting(int value) {
    setState(() { firstTurnSetting = value; });
    _saveFirstTurnSetting();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'TableTop Token Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        fontFamily: selectedFont,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      darkTheme: ThemeData(
        fontFamily: selectedFont,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: HomeScreen(
        selectedFont: selectedFont,
        onFontChanged: updateFont,
        selectedGame: selectedGame,
        turnTrackerEnabled: turnTrackerEnabled,
        onTurnTrackerChanged: updateTurnTracker,
        frostedGlass: frostedGlass,
        onFrostedGlassChanged: updateFrostedGlass,
        themeMode: themeMode,
        onThemeModeChanged: updateThemeMode,
        matchTimerMinutes: matchTimerMinutes,
        onMatchTimerChanged: updateMatchTimer,
        firstTurnSetting: firstTurnSetting,
        onFirstTurnSettingChanged: updateFirstTurnSetting,
      ),
    );
  }
}
