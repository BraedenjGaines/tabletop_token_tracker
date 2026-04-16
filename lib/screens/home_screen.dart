import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';

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
  final bool showPlayerCount;
  final Function(bool) onShowPlayerCountChanged;

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
    required this.showPlayerCount,
    required this.onShowPlayerCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TableTop Token Tracker'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
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
                      showPlayerCount: showPlayerCount,
                    ),
                  ),
                );
              },
              child: Text('Play'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
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
                      showPlayerCount: showPlayerCount,
                      onShowPlayerCountChanged: onShowPlayerCountChanged,
                    ),
                  ),
                );
              },
              child: Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
