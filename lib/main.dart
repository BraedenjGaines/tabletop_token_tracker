import "package:flutter/material.dart";
import "dart:math";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TableTop Token Tracker',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SetupScreen()),
            );
          },
          child: Text('Play'),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int selectedPlayers = 2;
  int selectedLife = 20;

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
                        backgroundColor: selectedPlayers == i ? Colors.blue : Colors.grey,
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
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedLife == life ? Colors.blue : Colors.grey,
                      ),
                      child: Text('$life'),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CounterScreen(
                      playerCount: selectedPlayers,
                      startingLife: selectedLife,
                    ),
                  ),
                );
              },
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
  CounterScreen({required this.playerCount, required this.startingLife});
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

  bool isPlayerOnMiddleRow(int playerIndex) {
    final int rowCount = (playerHealth.length + 1) ~/ 2;
    if (rowCount < 3) return false;
    final int playerRow = playerIndex ~/ 2;
    final int middleRow = rowCount ~/ 2;
    return playerRow == middleRow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resource Tracker'),
        centerTitle: true,
      ),
      body: playerHealth.length == 2
  ? Column(
      children: [
        Expanded(
          child: Transform.rotate(
            angle: pi,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: () {
                    setState(() { playerHealth[0]++; });
                  }, child: Text('+')),
                  Text('Player 1 Life: ${playerHealth[0]}'),
                  ElevatedButton(onPressed: () {
                    setState(() { playerHealth[0]--; });
                  }, child: Text('-')),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: () {
                  setState(() { playerHealth[1]++; });
                }, child: Text('+')),
                Text('Player 2 Life: ${playerHealth[1]}'),
                ElevatedButton(onPressed: () {
                  setState(() { playerHealth[1]--; });
                }, child: Text('-')),
              ],
            ),
          ),
        ),
      ],
    )
      :Column(
        children: [
          for (int i = 0; i < playerHealth.length; i += 2)
            Expanded(
              child: Builder(
                builder: (context) {
                final int rowCount = (playerHealth.length + 1) ~/ 2;
                final int currentRow = i ~/ 2;
                final bool isMiddleRow = isPlayerOnMiddleRow(i);
                final bool isTopRow = currentRow < (rowCount / 2).floor() && !isMiddleRow;

                Widget playerWidget(int index, double? rotationAngle) {
                  Widget content = Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(onPressed: () {
                          setState(() { playerHealth[index]++; });
                        }, child: Text('+')),
                        Text('Player ${index + 1} Life: ${playerHealth[index]}'),
                        ElevatedButton(onPressed: () {
                          setState(() { playerHealth[index]--; });
                        }, child: Text('-')),
                      ],
                    ),
                  );
                  if (rotationAngle != null) {
                    content = Transform.rotate(angle: rotationAngle, child: content);
                  }
                  return content;
                }
                Widget row = Row(
                  children: [
                    Expanded(
                      child: playerWidget(
                        i,
                        isTopRow ? pi : isMiddleRow ? pi / 2 : null,
                      ),
                    ),
                    if (i + 1 < playerHealth.length)
                      Expanded(
                        child: playerWidget(
                          i + 1,
                          isTopRow ? pi : isMiddleRow ? -pi / 2 : null,
                      ),
                    ),
                  ],
                );
                return row;
              },
            ),
          ),
        ],
      ),
    );
  }
}