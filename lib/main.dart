import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String selectedFont = 'Sedan';
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFont();
  }

  Future<void> _loadFont() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFont = prefs.getString('selectedFont') ?? 'Sedan';
      isLoaded = true;
    });
  }

  Future<void> _saveFont() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', selectedFont);
  }

  void updateFont(String newFont) {
    setState(() {
      selectedFont = newFont;
    });
    _saveFont();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      title: 'TableTop Token Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: selectedFont,
      ),
      home: HomeScreen(
        selectedFont: selectedFont,
        onFontChanged: updateFont,
      ),
    );
  }
}

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

class SettingsScreen extends StatefulWidget {
  final String currentFont;
  final Function(String) onFontChanged;

  SettingsScreen({
    required this.currentFont,
    required this.onFontChanged,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedFont;

  final List<String> availableFonts = [
    'EagleLake',
    'Jacquard12',
    'MedievalSharp',
    'Sedan',
  ];

  @override
  void initState() {
    super.initState();
    selectedFont = widget.currentFont;
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
                  }
                },
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFontChanged(selectedFont);
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
  final String selectedFont;
  final Function(String) onFontChanged;

  SetupScreen({
    required this.selectedFont,
    required this.onFontChanged,
  });

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
                            selectedFont: widget.selectedFont,
                            onFontChanged: widget.onFontChanged,
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
  final String selectedFont;
  final Function(String) onFontChanged;

  CounterScreen({
    required this.playerCount,
    required this.startingLife,
    required this.selectedFont,
    required this.onFontChanged,
  });

  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late List<int> playerHealth;
  late String currentFont;

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(widget.playerCount, widget.startingLife);
    currentFont = widget.selectedFont;
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      currentFont: currentFont,
                      onFontChanged: (String newFont) {
                        widget.onFontChanged(newFont);
                        setState(() {
                          currentFont = newFont;
                        });
                      },
                    ),
                  ),
                );
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