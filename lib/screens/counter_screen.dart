import 'package:flutter/material.dart';
import 'dart:math';
import 'settings_screen.dart';
import '../data/token_library.dart';

class CounterScreen extends StatefulWidget {
  final int playerCount;
  final int startingLife;
  final String selectedFont;
  final Function(String) onFontChanged;
  final String selectedGame;

  CounterScreen({
    required this.playerCount,
    required this.startingLife,
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
  });

  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late List<int> playerHealth;
  late List<List<Map<String, int>>> playerTokens;
  late String currentFont;

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(widget.playerCount, widget.startingLife);
    playerTokens = List.generate(widget.playerCount, (_) => []);
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

  void _showTokenPicker(int playerIndex) {
    final List<String> availableTokens = tokenLibrary[widget.selectedGame] ?? [];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Token - Player ${playerIndex + 1}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Expanded(
                child: availableTokens.isEmpty
                    ? Center(child: Text('No tokens available for this game'))
                    : ListView.builder(
                        itemCount: availableTokens.length,
                        itemBuilder: (context, index) {
                          final tokenName = availableTokens[index];
                          final bool alreadyAdded = playerTokens[playerIndex]
                              .any((t) => t.keys.first == tokenName);

                          return ListTile(
                            title: Text(tokenName),
                            trailing: alreadyAdded
                                ? Icon(Icons.check, color: Colors.green)
                                : Icon(Icons.add_circle_outline),
                            onTap: () {
                              if (!alreadyAdded) {
                                setState(() {
                                  playerTokens[playerIndex]
                                      .add({tokenName: 1});
                                });
                              }
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTokenList(int index) {
    if (playerTokens[index].isEmpty) return SizedBox();

    return Column(
      children: [
        for (int t = 0; t < playerTokens[index].length; t++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final name = playerTokens[index][t].keys.first;
                      final value = playerTokens[index][t][name]!;
                      if (value <= 1) {
                        playerTokens[index].removeAt(t);
                      } else {
                        playerTokens[index][t] = {name: value - 1};
                      }
                    });
                  },
                  child: Icon(Icons.remove_circle, size: 20),
                ),
                SizedBox(width: 4),
                Text(
                  '${playerTokens[index][t].values.first}',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      final name = playerTokens[index][t].keys.first;
                      final value = playerTokens[index][t][name]!;
                      playerTokens[index][t] = {name: value + 1};
                    });
                  },
                  child: Icon(Icons.add_circle, size: 20),
                ),
                SizedBox(width: 8),
                Text(
                  playerTokens[index][t].keys.first,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerWidget(int index) {
    Widget content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
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
          SizedBox(height: 8),
          _buildTokenList(index),
          SizedBox(height: 4),
          GestureDetector(
            onTap: () => _showTokenPicker(index),
            child: Icon(Icons.add_box, size: 24),
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
          _buildPlayerGrid(),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),

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
                  playerTokens = List.generate(widget.playerCount, (_) => []);
                });
              },
            ),
          ),

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