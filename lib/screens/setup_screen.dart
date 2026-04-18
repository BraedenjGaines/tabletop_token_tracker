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
  final int startingLife;
  final Function(int) onStartingLifeChanged;
  final int firstTurnSetting;
  final Function(int) onFirstTurnSettingChanged;
  final int resourceTrackerSetting;
  final Function(int) onResourceTrackerChanged;

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
    required this.startingLife,
    required this.onStartingLifeChanged,
    required this.firstTurnSetting,
    required this.onFirstTurnSettingChanged,
    required this.resourceTrackerSetting,
    required this.onResourceTrackerChanged,
  });

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int selectedPlayers = 2;
  late int selectedLife;
  final TextEditingController customLifeController = TextEditingController();
  late int matchTimerMinutes;
  late TextEditingController timerController;

  static const List<String> heroArchetypes = [
    'Wizard', 'Knight', 'Warlock', 'Rogue',
    'Mage', 'Druid', 'Runeknight', 'Paladin',
  ];

  late List<String> playerHeroes;

  @override
  void initState() {
    super.initState();
    playerHeroes = List.generate(6, (i) => heroArchetypes[i % heroArchetypes.length]);
    selectedLife = widget.startingLife;
    customLifeController.text = selectedLife.toString();
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
      appBar: AppBar(title: Text('Game Setup'), centerTitle: true),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Starting Life', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Life: ', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: customLifeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() { selectedLife = parsed; });
                            widget.onStartingLifeChanged(parsed);
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
                    for (int life in [20, 25, 30, 40])
                      ChoiceChip(
                        label: Text('$life'),
                        selected: selectedLife == life,
                        onSelected: (_) {
                          setState(() { selectedLife = life; customLifeController.text = life.toString(); });
                          widget.onStartingLifeChanged(life);
                        },
                      ),
                  ],
                ),
                SizedBox(height: 30),
                Text('Choose Heroes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                for (int p = 0; p < selectedPlayers; p++)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 90, child: Text('Player ${p + 1}', style: TextStyle(fontSize: 16))),
                        SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/${playerHeroes[p]}.jpg',
                            width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(width: 40, height: 40, color: Colors.grey[300], child: Icon(Icons.person, size: 24)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          width: 160,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                          child: DropdownButton<String>(
                            value: playerHeroes[p], isExpanded: true, underline: SizedBox(),
                            items: heroArchetypes.map((hero) => DropdownMenuItem(value: hero, child: Text(hero))).toList(),
                            onChanged: (value) { if (value != null) setState(() { playerHeroes[p] = value; }); },
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 30),
                Text('Match Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && parsed > 0) {
                            setState(() { matchTimerMinutes = parsed; });
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
                    for (int preset in [30, 35, 55, 60])
                      ChoiceChip(
                        label: Text('$preset'),
                        selected: matchTimerMinutes == preset,
                        onSelected: (_) {
                          setState(() { matchTimerMinutes = preset; timerController.text = preset.toString(); });
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
                                firstTurnSetting: widget.firstTurnSetting,
                                onFirstTurnSettingChanged: widget.onFirstTurnSettingChanged,
                                resourceTrackerSetting: widget.resourceTrackerSetting,
                                onResourceTrackerChanged: widget.onResourceTrackerChanged,
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
