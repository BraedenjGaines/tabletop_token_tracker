import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String currentFont;
  final Function(String) onFontChanged;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;

  SettingsScreen({
    required this.currentFont,
    required this.onFontChanged,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedFont;
  late bool turnTracker;

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
          ],
        ),
      ),
    );
  }
}