import 'package:flutter/material.dart';
import 'custom_token_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentFont;
  final Function(String) onFontChanged;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final String currentGame;
  final bool skipGameSelect;
  final Function(String, bool) onGameChanged;

  SettingsScreen({
    required this.currentFont,
    required this.onFontChanged,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.currentGame,
    required this.skipGameSelect,
    required this.onGameChanged,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedFont;
  late bool turnTracker;
  late String selectedGame;
  late bool promptGameSelect;

  final List<String> availableFonts = [
    'Sedan',
    'EagleLake',
    'Jacquard12',
    'MedievalSharp',
  ];

  final List<Map<String, String>> availableGames = [
    {'id': 'fab', 'name': 'Flesh and Blood'},
    {'id': 'mtg', 'name': 'Magic: The Gathering'},
  ];

  @override
  void initState() {
    super.initState();
    selectedFont = widget.currentFont;
    turnTracker = widget.turnTrackerEnabled;
    selectedGame = widget.currentGame.isEmpty ? 'fab' : widget.currentGame;
    promptGameSelect = !widget.skipGameSelect;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedFont,
                  isExpanded: true,
                  underline: SizedBox(),
                  items: availableFonts.map((font) {
                    return DropdownMenuItem(
                      value: font,
                      child: Text(
                        font,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newFont) {
                    if (newFont != null) {
                      setState(() {
                        selectedFont = newFont;
                      });
                      widget.onFontChanged(newFont);
                    }
                  },
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Game',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: selectedGame,
                  isExpanded: true,
                  underline: SizedBox(),
                  items: availableGames.map((game) {
                    return DropdownMenuItem(
                      value: game['id'],
                      child: Text(
                        game['name']!,
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newGame) {
                    if (newGame != null) {
                      setState(() {
                        selectedGame = newGame;
                      });
                      widget.onGameChanged(selectedGame, !promptGameSelect);
                    }
                  },
                ),
              ),
              SizedBox(height: 8),
              CheckboxListTile(
                title: Text('Ask which game before each session'),
                value: promptGameSelect,
                onChanged: (bool? value) {
                  setState(() {
                    promptGameSelect = value ?? true;
                  });
                  widget.onGameChanged(selectedGame, !promptGameSelect);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: 32),
              Text(
                'Turn Tracker',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Shows phase tracking between players (Flesh and Blood, 2 players only)',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Enable Turn Tracker'),
                value: turnTracker,
                onChanged: (bool value) {
                  setState(() {
                    turnTracker = value;
                  });
                  widget.onTurnTrackerChanged(value);
                },
              ),
              SizedBox(height: 32),
                Text(
                  'Tokens',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomTokenScreen(
                            currentGame: selectedGame,
                          ),
                        ),
                      );
                    },
                  child: Text('Manage Custom Tokens'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}