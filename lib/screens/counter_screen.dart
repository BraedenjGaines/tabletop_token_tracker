import 'package:flutter/material.dart';
import 'dart:math';
import 'settings_screen.dart';

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
          _buildPlayerGrid(),

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