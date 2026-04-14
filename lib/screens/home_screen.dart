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

  HomeScreen({
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
    required this.skipGameSelect,
    required this.onGameChanged,
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