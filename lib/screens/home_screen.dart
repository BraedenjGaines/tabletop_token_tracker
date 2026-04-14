import 'package:flutter/material.dart';
import 'game_select_screen.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String selectedFont;
  final Function(String) onFontChanged;
  final String selectedGame;
  final bool skipGameSelect;
  final Function(String, bool) onGameChanged;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final bool frostedGlass;
  final Function(bool) onFrostedGlassChanged;

  HomeScreen({
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
    required this.skipGameSelect,
    required this.onGameChanged,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.frostedGlass,
    required this.onFrostedGlassChanged,
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
                if (skipGameSelect && selectedGame.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetupScreen(
                        selectedFont: selectedFont,
                        onFontChanged: onFontChanged,
                        selectedGame: selectedGame,
                        turnTrackerEnabled: turnTrackerEnabled,
                        onTurnTrackerChanged: onTurnTrackerChanged,
                        skipGameSelect: skipGameSelect,
                        onGameChanged: onGameChanged,
                        frostedGlass: frostedGlass,
                        onFrostedGlassChanged: onFrostedGlassChanged,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameSelectScreen(
                        selectedFont: selectedFont,
                        onFontChanged: onFontChanged,
                        onGameChanged: onGameChanged,
                        turnTrackerEnabled: turnTrackerEnabled,
                        onTurnTrackerChanged: onTurnTrackerChanged,
                        skipGameSelect: skipGameSelect,
                        frostedGlass: frostedGlass,
                        onFrostedGlassChanged: onFrostedGlassChanged,
                      ),
                    ),
                  );
                }
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
                      currentGame: selectedGame,
                      skipGameSelect: skipGameSelect,
                      onGameChanged: onGameChanged,
                      frostedGlass: frostedGlass,
                      onFrostedGlassChanged: onFrostedGlassChanged,
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