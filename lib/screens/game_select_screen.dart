import 'package:flutter/material.dart';
import 'setup_screen.dart';

class GameSelectScreen extends StatefulWidget {
  final String selectedFont;
  final Function(String) onFontChanged;
  final Function(String, bool) onGameChanged;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final bool skipGameSelect;
  final bool frostedGlass;
  final Function(bool) onFrostedGlassChanged;

  GameSelectScreen({
    required this.selectedFont,
    required this.onFontChanged,
    required this.onGameChanged,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.skipGameSelect,
    required this.frostedGlass,
    required this.onFrostedGlassChanged,
  });

  @override
  _GameSelectScreenState createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  String selectedGame = '';
  bool dontAskAgain = false;

  final List<Map<String, String>> availableGames = [
    {'id': 'fab', 'name': 'Flesh and Blood'},
    {'id': 'mtg', 'name': 'Magic: The Gathering'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Game'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What are you playing?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            for (var game in availableGames)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 250,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedGame = game['id']!;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedGame == game['id'] ? Colors.blue : Colors.grey,
                      alignment: Alignment.center,
                    ),
                    child: Center(
                      child: Text(
                        game['name']!,
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: dontAskAgain,
                  onChanged: (bool? value) {
                    setState(() {
                      dontAskAgain = value ?? false;
                    });
                  },
                ),
                Text("Don't ask again"),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedGame.isNotEmpty
                  ? () {
                      widget.onGameChanged(selectedGame, dontAskAgain);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SetupScreen(
                            selectedFont: widget.selectedFont,
                            onFontChanged: widget.onFontChanged,
                            selectedGame: selectedGame,
                            turnTrackerEnabled: widget.turnTrackerEnabled,
                            onTurnTrackerChanged: widget.onTurnTrackerChanged,
                            skipGameSelect: dontAskAgain,
                            onGameChanged: widget.onGameChanged,
                            frostedGlass: widget.frostedGlass,
                            onFrostedGlassChanged: widget.onFrostedGlassChanged,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}