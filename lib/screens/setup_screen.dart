import 'package:flutter/material.dart';
import 'counter_screen.dart';

class SetupScreen extends StatefulWidget {
  final String selectedFont;
  final Function(String) onFontChanged;
  final String selectedGame;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final bool frostedGlass;
  final Function(bool) onFrostedGlassChanged;
  final ThemeMode themeMode;
  final Function(ThemeMode) onThemeModeChanged;
  final int matchTimerMinutes;
  final Function(int) onMatchTimerChanged;
  final bool showPlayerCount;

  const SetupScreen({
    super.key,
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.frostedGlass,
    required this.onFrostedGlassChanged,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.matchTimerMinutes,
    required this.onMatchTimerChanged,
    required this.showPlayerCount,
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
  late int matchTimerMinutes;
  late TextEditingController timerController;

  @override
  void initState() {
    super.initState();
    playerHeroes = List.generate(
      6,
      (i) => heroArchetypes[i % heroArchetypes.length],
    );
    matchTimerMinutes = widget.matchTimerMinutes;
    timerController = TextEditingController(text: matchTimerMinutes.toString());
  }

  @override
  void dispose() {
    customLifeController.dispose();
    timerController.dispose();
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
                if (widget.showPlayerCount) ...[
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
                ],
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
                Text(
                  'Match Timer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Minutes: ', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: timerController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() {
                              matchTimerMinutes = parsed;
                            });
                            widget.onMatchTimerChanged(parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (int preset in [30, 50, 60, 90])
                      ChoiceChip(
                        label: Text('$preset'),
                        selected: matchTimerMinutes == preset,
                        onSelected: (_) {
                          setState(() {
                            matchTimerMinutes = preset;
                            timerController.text = preset.toString();
                          });
                          widget.onMatchTimerChanged(preset);
                        },
                      ),
                  ],
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
                                frostedGlass: widget.frostedGlass,
                                onFrostedGlassChanged: widget.onFrostedGlassChanged,
                                themeMode: widget.themeMode,
                                onThemeModeChanged: widget.onThemeModeChanged,
                                matchTimerMinutes: matchTimerMinutes,
                                onMatchTimerChanged: widget.onMatchTimerChanged,
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
