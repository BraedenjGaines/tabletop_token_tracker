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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resource Tracker'),
        centerTitle: true, // Center the title in the app bar
      ),
      body: Column(
  children: [
    for (int i = 0; i < playerHealth.length; i++)
      Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: () {
                setState(() {
                  playerHealth[i]++;
                });
              }, child: Text('+')),
              Text('Player ${i + 1} Life: ${playerHealth[i]}'),
              ElevatedButton(onPressed: () {
                setState(() {
                  playerHealth[i]--;
                });
              }, child: Text('-')),
            ],
          ),
        ),
      ),
  ],
),
    );
  }
}