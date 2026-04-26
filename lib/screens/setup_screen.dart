import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';
import '../data/hero_library.dart';
import 'counter_screen.dart';
import 'hero_selector_screen.dart';
import 'widgets/hero_image.dart';
import '../data/setup_backgrounds.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late int selectedLife;
  final TextEditingController customLifeController = TextEditingController();
  late int matchTimerMinutes;
  late TextEditingController timerController;
  late TextEditingController player1NameController;
  late TextEditingController player2NameController;

  late List<HeroData?> playerHeroes;
  String? _backgroundPath;

  @override
  void initState() {
    super.initState();
    final settings = context.read<GameSettingsProvider>();
    selectedLife = settings.startingLife;
    customLifeController.text = selectedLife.toString();
    matchTimerMinutes = settings.matchTimerMinutes;
    timerController = TextEditingController(text: matchTimerMinutes.toString());

    final random = Random();
    if (settings.player1HeroId != null) {
      playerHeroes = [
        heroLibrary.cast<HeroData?>().firstWhere((h) => h?.id == settings.player1HeroId, orElse: () => null),
        heroLibrary.cast<HeroData?>().firstWhere((h) => h?.id == settings.player2HeroId, orElse: () => null),
      ];
      player1NameController = TextEditingController(text: settings.player1Name);
      player2NameController = TextEditingController(text: settings.player2Name);
    } else if (heroLibrary.length >= 2) {
      final shuffled = List<HeroData>.from(heroLibrary)..shuffle(random);
      playerHeroes = [shuffled[0], shuffled[1]];
      settings.player1HeroId = playerHeroes[0]?.id;
      settings.player2HeroId = playerHeroes[1]?.id;
      player1NameController = TextEditingController(text: playerHeroes[0]?.name ?? 'Player 1');
      player2NameController = TextEditingController(text: playerHeroes[1]?.name ?? 'Player 2');
      settings.player1Name = player1NameController.text;
      settings.player2Name = player2NameController.text;
    } else {
      playerHeroes = List.filled(2, null);
      player1NameController = TextEditingController(text: settings.player1Name);
      player2NameController = TextEditingController(text: settings.player2Name);
    }
    _loadBackground();
  }

  void _loadBackground() async {
    final path = await SetupBackgrounds.sessionPick();
    if (mounted) setState(() { _backgroundPath = path; });
  }

  @override
  void dispose() {
    customLifeController.dispose();
    timerController.dispose();
    player1NameController.dispose();
    player2NameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<GameSettingsProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text('Game Setup'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _backgroundPath != null
              ? Image.asset(
                  _backgroundPath!,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Container(color: Theme.of(context).scaffoldBackgroundColor),
                )
              : Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                      16,
                      24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Starting Life',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Life: ', style: TextStyle(fontSize: 16, color: Colors.white)),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: customLifeController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 2,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[850],
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null && parsed > 0 && parsed <= 99) {
                                    setState(() { selectedLife = parsed; });
                                    settings.updateStartingLife(parsed);
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
                                label: Text('$life', style: TextStyle(color: Colors.white)),
                                selected: selectedLife == life,
                                backgroundColor: Colors.grey[850],
                                selectedColor: Colors.grey[700],
                                onSelected: (_) {
                                  setState(() { selectedLife = life; customLifeController.text = life.toString(); });
                                  settings.updateStartingLife(life);
                                },
                              ),
                          ],
                        ),
                        SizedBox(height: 30),
                        Text('Choose Heroes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 12),
                        for (int p = 0; p < 2; p++)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: p == 0 ? player1NameController : player2NameController,
                                    style: TextStyle(fontSize: 14, color: Colors.white),
                                    maxLength: 50,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.grey[850],
                                      counterText: '',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                    onChanged: (value) {
                                      if (p == 0) {
                                        settings.player1Name = value.isEmpty ? 'Player 1' : value;
                                      } else {
                                        settings.player2Name = value.isEmpty ? 'Player 2' : value;
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () async {
                                    final selected = await Navigator.push<HeroData>(
                                      context,
                                      MaterialPageRoute(builder: (context) => HeroSelectorScreen(currentHeroId: playerHeroes[p]?.id)),
                                    );
                                    if (selected != null) {
                                      setState(() {
                                        playerHeroes[p] = selected;
                                        final nameController = p == 0 ? player1NameController : player2NameController;
                                        nameController.text = selected.name;
                                        if (p == 0) {
                                          settings.player1HeroId = selected.id;
                                          settings.player1Name = selected.name;
                                        } else {
                                          settings.player2HeroId = selected.id;
                                          settings.player2Name = selected.name;
                                        }
                                      });
                                    }
                                  },
                                  child: Container(
                                    width: 60,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: playerHeroes[p] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(7),
                                          child: HeroImage(hero: playerHeroes[p]!, fit: BoxFit.cover),
                                        )
                                      : Center(child: Icon(Icons.add, size: 28, color: Colors.grey)),
                                  ),
                                ),
                                SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    playerHeroes[p]?.displayName ?? 'Select Hero',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: playerHeroes[p] != null ? Colors.white : Colors.grey[400],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 30),
                        Text('Match Timer',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Minutes: ', style: TextStyle(fontSize: 16, color: Colors.white)),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: timerController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 2,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[850],
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onChanged: (value) {
                                  final parsed = int.tryParse(value);
                                  if (parsed != null && parsed > 0 && parsed <= 99) {
                                    setState(() { matchTimerMinutes = parsed; });
                                    settings.updateMatchTimer(parsed);
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
                                label: Text('$preset', style: TextStyle(color: Colors.white)),
                                selected: matchTimerMinutes == preset,
                                backgroundColor: Colors.grey[850],
                                selectedColor: Colors.grey[700],
                                onSelected: (_) {
                                  setState(() { matchTimerMinutes = preset; timerController.text = preset.toString(); });
                                  settings.updateMatchTimer(preset);
                                },
                              ),
                          ],
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                          ),
                          onPressed: selectedLife >= 1
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        final p1 = player1NameController.text.isEmpty ? 'Player 1' : player1NameController.text;
                                        final p2 = player2NameController.text.isEmpty ? 'Player 2' : player2NameController.text;
                                        settings.player1Name = p1;
                                        settings.player2Name = p2;
                                        return CounterScreen(
                                          startingLife: selectedLife,
                                          playerHeroes: [
                                            playerHeroes[0]?.id ?? 'default',
                                            playerHeroes[1]?.id ?? 'default',
                                          ],
                                          playerNames: [p1, p2],
                                          matchTimerMinutes: matchTimerMinutes,
                                        );
                                      },
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
            ),
          ),
        ],
      ),
    );
  }
}