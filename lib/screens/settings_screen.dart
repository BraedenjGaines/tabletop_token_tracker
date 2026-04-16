import 'package:flutter/material.dart';
import 'custom_token_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String currentFont;
  final Function(String) onFontChanged;
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

  const SettingsScreen({
    super.key,
    required this.currentFont,
    required this.onFontChanged,
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
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedFont;
  late bool turnTracker;
  late bool frostedGlass;
  late ThemeMode currentThemeMode;
  late bool showPlayerCount;

  final List<String> availableFonts = [
    'Sedan',
    'EagleLake',
    'Jacquard12',
    'MedievalSharp',
  ];

  @override
  void initState() {
    super.initState();
    selectedFont = widget.currentFont;
    turnTracker = widget.turnTrackerEnabled;
    frostedGlass = widget.frostedGlass;
    currentThemeMode = widget.themeMode;
    showPlayerCount = widget.showPlayerCount;
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
              // --- Font ---
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

              // --- Turn Tracker ---
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

              // --- Game Setup ---
              SizedBox(height: 32),
              Text(
                'Game Setup',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Show Player Count Selection'),
                subtitle: Text('Toggle player count chooser on the setup screen'),
                value: showPlayerCount,
                onChanged: (bool value) {
                  setState(() {
                    showPlayerCount = value;
                  });
                  widget.onShowPlayerCountChanged(value);
                },
              ),

              // --- Visual ---
              SizedBox(height: 32),
              Text(
                'Visual',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Applies a frosted glass blur effect to the player panels on the counter screen',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Frosted Glass Effect'),
                value: frostedGlass,
                onChanged: (bool value) {
                  setState(() {
                    frostedGlass = value;
                  });
                  widget.onFrostedGlassChanged(value);
                },
              ),
              SizedBox(height: 16),
              Text(
                'Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings_brightness),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {currentThemeMode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  setState(() {
                    currentThemeMode = selection.first;
                  });
                  widget.onThemeModeChanged(selection.first);
                },
              ),

              // --- Tokens ---
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
                          currentGame: 'fab',
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
