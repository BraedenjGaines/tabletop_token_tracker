import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatelessWidget {
  final String selectedFont;
  final Function(String) onFontChanged;
  final String selectedGame;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final bool frostedGlass;
  final Function(bool) onFrostedGlassChanged;
  final ThemeMode themeMode;
  final Function(ThemeMode) onThemeModeChanged;
  final int matchTimerMinutes;
  final Function(int) onMatchTimerChanged;
  final int startingLife;
  final Function(int) onStartingLifeChanged;
  final int firstTurnSetting;
  final Function(int) onFirstTurnSettingChanged;
  final int resourceTrackerSetting;
  final Function(int) onResourceTrackerChanged;
  final bool armorTrackingEnabled;
  final Function(bool) onArmorTrackingChanged;

  const HomeScreen({
    super.key,
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.frostedGlass,
    required this.onFrostedGlassChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.matchTimerMinutes,
    required this.onMatchTimerChanged,
    required this.startingLife,
    required this.onStartingLifeChanged,
    required this.firstTurnSetting,
    required this.onFirstTurnSettingChanged,
    required this.resourceTrackerSetting,
    required this.onResourceTrackerChanged,
    required this.armorTrackingEnabled,
    required this.onArmorTrackingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'TableTop\nToken Tracker',
          style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetupScreen(
                      selectedFont: selectedFont,
                      onFontChanged: onFontChanged,
                      selectedGame: selectedGame,
                      turnTrackerEnabled: turnTrackerEnabled,
                      onTurnTrackerChanged: onTurnTrackerChanged,
                      frostedGlass: frostedGlass,
                      onFrostedGlassChanged: onFrostedGlassChanged,
                      themeMode: themeMode,
                      onThemeModeChanged: onThemeModeChanged,
                      matchTimerMinutes: matchTimerMinutes,
                      onMatchTimerChanged: onMatchTimerChanged,
                      startingLife: startingLife,
                      onStartingLifeChanged: onStartingLifeChanged,
                      firstTurnSetting: firstTurnSetting,
                      onFirstTurnSettingChanged: onFirstTurnSettingChanged,
                      resourceTrackerSetting: resourceTrackerSetting,
                      onResourceTrackerChanged: onResourceTrackerChanged,
                      armorTrackingEnabled: armorTrackingEnabled,
                      onArmorTrackingChanged: onArmorTrackingChanged,
                    ),
                  ),
                );
              },
              child: Text('Play', style: TextStyle(fontSize: 22)),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 220,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      currentFont: selectedFont,
                      onFontChanged: onFontChanged,
                      turnTrackerEnabled: turnTrackerEnabled,
                      onTurnTrackerChanged: onTurnTrackerChanged,
                      frostedGlass: frostedGlass,
                      onFrostedGlassChanged: onFrostedGlassChanged,
                      themeMode: themeMode,
                      onThemeModeChanged: onThemeModeChanged,
                      matchTimerMinutes: matchTimerMinutes,
                      onMatchTimerChanged: onMatchTimerChanged,
                      firstTurnSetting: firstTurnSetting,
                      onFirstTurnSettingChanged: onFirstTurnSettingChanged,
                      resourceTrackerSetting: resourceTrackerSetting,
                      onResourceTrackerChanged: onResourceTrackerChanged,
                      armorTrackingEnabled: armorTrackingEnabled,
                      onArmorTrackingChanged: onArmorTrackingChanged,
                    ),
                  ),
                );
              },
              child: Text('Settings', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.info_outline, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
