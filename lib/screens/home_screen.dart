import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final String selectedFont;
  final Function(String) onFontChanged;

  HomeScreen({
    required this.selectedFont,
    required this.onFontChanged,
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