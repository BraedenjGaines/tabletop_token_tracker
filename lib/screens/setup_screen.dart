import 'package:flutter/material.dart';
import 'counter_screen.dart';

class SetupScreen extends StatefulWidget {
  final String selectedFont;
  final Function(String) onFontChanged;
  final String selectedGame;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final bool skipGameSelect;
  final Function(String, bool) onGameChanged;
  final bool frostedGlass;
  final Function(bool) onFrostedGlassChanged;

  SetupScreen({
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.skipGameSelect,
    required this.onGameChanged,
    required this.frostedGlass,
    required this.onFrostedGlassChanged,
  });

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int selectedPlayers = 2;
  int selectedLife = 20;
  bool isCustomLife = false;
  final TextEditingController customLifeController = TextEditingController();

  static const List<String> heroArchetypes = [
    'Wizard',
    'Knight',
    'Warlock',
    'Rogue',
    'Mage',
    'Druid',
    'Runeknight',
    'Paladin',
  ];

  late List<String> playerHeroes;

  @override
  void initState() {
    super.initState();
    playerHeroes = List.generate(
      6,
      (i) => heroArchetypes[i % heroArchetypes.length],
    );
  }

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
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                Text(
                  'Choose Heroes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                for (int p = 0; p < selectedPlayers; p++)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Player ${p + 1}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/${playerHeroes[p]}.jpg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                color: Colors.grey[300],
                                child: Icon(Icons.person, size: 24),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          width: 160,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: playerHeroes[p],
                            isExpanded: true,
                            underline: SizedBox(),
                            items: heroArchetypes.map((hero) {
                              return DropdownMenuItem(
                                value: hero,
                                child: Text(hero),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  playerHeroes[p] = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
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
                                playerHeroes: playerHeroes.sublist(0, selectedPlayers),
                                selectedFont: widget.selectedFont,
                                onFontChanged: widget.onFontChanged,
                                selectedGame: widget.selectedGame,
                                turnTrackerEnabled: widget.turnTrackerEnabled,
                                onTurnTrackerChanged: widget.onTurnTrackerChanged,
                                skipGameSelect: widget.skipGameSelect,
                                onGameChanged: widget.onGameChanged,
                                frostedGlass: widget.frostedGlass,
                                onFrostedGlassChanged: widget.onFrostedGlassChanged,
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
        ),
      ),
    );
  }
}