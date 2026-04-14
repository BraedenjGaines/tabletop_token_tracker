import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String lifeTotalFont = 'Default';
  String appFont = 'Default';

  void updateFonts(String newLifeFont, String newAppFont) {
    setState(() {
      lifeTotalFont = newLifeFont;
      appFont = newAppFont;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TableTop Token Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: appFont == 'Default' ? null : appFont,
      ),
      home: HomeScreen(
        lifeTotalFont: lifeTotalFont,
        appFont: appFont,
        onFontsChanged: updateFonts,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String lifeTotalFont;
  final String appFont;
  final Function(String, String) onFontsChanged;

  HomeScreen({
    required this.lifeTotalFont,
    required this.appFont,
    required this.onFontsChanged,
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
                      lifeTotalFont: lifeTotalFont,
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
                      currentLifeFont: lifeTotalFont,
                      currentAppFont: appFont,
                      onFontsChanged: onFontsChanged,
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

class SettingsScreen extends StatefulWidget {
  final String currentLifeFont;
  final String currentAppFont;
  final Function(String, String) onFontsChanged;

  SettingsScreen({
    required this.currentLifeFont,
    required this.currentAppFont,
    required this.onFontsChanged,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedLifeFont;
  late String selectedAppFont;
  late String fontScope;

  final List<String> availableFonts = [
    'Default',
    'EagleLake',
    'Jacquard12',
    'MedievalSharp',
    'Sedan',
  ];

  @override
  void initState() {
    super.initState();
    selectedLifeFont = widget.currentLifeFont;
    selectedAppFont = widget.currentAppFont;
    fontScope = selectedAppFont != 'Default' ? 'all' : 'life';
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
              'Font Settings',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text('Apply font to:'),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'life',
                    label: Text('Life Totals Only'),
                  ),
                  ButtonSegment(
                    value: 'all',
                    label: Text('Entire App'),
                  ),
                ],
                selected: {fontScope},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    fontScope = selection.first;
                    if (fontScope == 'all') {
                      selectedAppFont = selectedLifeFont;
                    } else {
                      selectedAppFont = 'Default';
                    }
                  });
                },
              ),
            ),
            SizedBox(height: 24),
            Text('Choose font:'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedLifeFont,
                isExpanded: true,
                underline: SizedBox(),
                items: availableFonts.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(
                      font == 'Default' ? 'Default' : font,
                      style: TextStyle(
                        fontFamily: font == 'Default' ? null : font,
                        fontSize: 18,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newFont) {
                  if (newFont != null) {
                    setState(() {
                      selectedLifeFont = newFont;
                      if (fontScope == 'all') {
                        selectedAppFont = newFont;
                      }
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 32),
            Text('Preview:'),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '42',
                    style: TextStyle(
                      fontFamily: selectedLifeFont == 'Default'
                          ? null
                          : selectedLifeFont,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Player 1 Life',
                    style: TextStyle(
                      fontFamily: fontScope == 'all' && selectedLifeFont != 'Default'
                          ? selectedLifeFont
                          : null,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFontsChanged(selectedLifeFont, selectedAppFont);
                  Navigator.pop(context);
                },
                child: Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  final String lifeTotalFont;

  SetupScreen({required this.lifeTotalFont});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int selectedPlayers = 2;
  int selectedLife = 20;
  bool isCustomLife = false;
  final TextEditingController customLifeController = TextEditingController();

  @override
  void dispose() {
    customLifeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Setup'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Number of Players'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 2; i <= 6; i++)
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedPlayers = i;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedPlayers == i ? Colors.blue : Colors.grey,
                      ),
                      child: Text('$i'),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 30),
            Text('Starting Life'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int life in [20, 25, 30, 40])
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLife = life;
                          isCustomLife = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isCustomLife && selectedLife == life
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      child: Text('$life'),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isCustomLife = true;
                        selectedLife =
                            int.tryParse(customLifeController.text) ?? 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCustomLife ? Colors.blue : Colors.grey,
                    ),
                    child: Text('Custom'),
                  ),
                ),
              ],
            ),
            if (isCustomLife)
              Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: customLifeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter life',
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedLife = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: selectedLife >= 1
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CounterScreen(
                            playerCount: selectedPlayers,
                            startingLife: selectedLife,
                            lifeTotalFont: widget.lifeTotalFont,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}

class CounterScreen extends StatefulWidget {
  final int playerCount;
  final int startingLife;
  final String lifeTotalFont;

  CounterScreen({
    required this.playerCount,
    required this.startingLife,
    required this.lifeTotalFont,
  });

  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late List<int> playerHealth;

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(widget.playerCount, widget.startingLife);
  }

  bool _isMiddleRow(int playerIndex) {
    final int rowCount = (playerHealth.length + 1) ~/ 2;
    if (rowCount < 3) return false;
    final int playerRow = playerIndex ~/ 2;
    final int middleRow = rowCount ~/ 2;
    return playerRow == middleRow;
  }

  double? _getRotationAngle(int index) {
    if (playerHealth.length == 2) return index == 0 ? pi : null;

    final int rowCount = (playerHealth.length + 1) ~/ 2;
    final int currentRow = index ~/ 2;
    final bool isMiddle = _isMiddleRow(index);
    final bool isTop = currentRow < (rowCount / 2).floor() && !isMiddle;

    if (isTop) return pi;
    if (isMiddle) return (index % 2 == 0) ? pi / 2 : -pi / 2;
    return null;
  }

  Widget _buildPlayerWidget(int index) {
    Widget content = Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              setState(() { playerHealth[index]--; });
            },
            child: Text('-'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${playerHealth[index]}',
              style: TextStyle(
                fontFamily: widget.lifeTotalFont == 'Default'
                    ? null
                    : widget.lifeTotalFont,
                fontSize: 32,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() { playerHealth[index]++; });
            },
            child: Text('+'),
          ),
        ],
      ),
    );

    final double? angle = _getRotationAngle(index);
    if (angle != null) {
      content = Transform.rotate(angle: angle, child: content);
    }
    return content;
  }

  Widget _buildPlayerGrid() {
    if (playerHealth.length == 2) {
      return Column(
        children: [
          Expanded(child: _buildPlayerWidget(0)),
          Expanded(child: _buildPlayerWidget(1)),
        ],
      );
    }
    return Column(
      children: [
        for (int i = 0; i < playerHealth.length; i += 2)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPlayerWidget(i)),
                if (i + 1 < playerHealth.length)
                  Expanded(child: _buildPlayerWidget(i + 1)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Player grid takes full screen
          _buildPlayerGrid(),

          // Back button - top left
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Reset button - top right
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  playerHealth = List.filled(
                    widget.playerCount,
                    widget.startingLife,
                  );
                });
              },
            ),
          ),

          // Settings button - bottom right
          Positioned(
            bottom: 24,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                // TODO: navigate to settings
              },
            ),
          ),

          // Placeholder - bottom left
          Positioned(
            bottom: 24,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () {
                // TODO: future feature
              },
            ),
          ),
        ],
      ),
    );
  }
}