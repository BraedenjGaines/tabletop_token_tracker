import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';
import '../data/hero_library.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'counter_screen.dart';
import 'hero_selector_screen.dart';
import 'widgets/hero_image.dart';
import '../data/setup_backgrounds.dart';
import 'widgets/custom_image.dart';
import 'package:flutter/services.dart';

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
  List<HeroData> _customHeroes = [];

  HeroData? _findHero(String? id) {
    if (id == null) return null;
    final allHeroes = [...heroLibrary, ..._customHeroes];
    return allHeroes.cast<HeroData?>().firstWhere((h) => h?.id == id, orElse: () => null);
  }

  @override
  void initState() {
    super.initState();
    final settings = context.read<GameSettingsProvider>();
    _loadCustomHeroesSync();
    selectedLife = settings.startingLife;
    customLifeController.text = selectedLife.toString();
    matchTimerMinutes = settings.matchTimerMinutes;
    timerController = TextEditingController(text: matchTimerMinutes.toString());

    final random = Random();
    if (settings.player1HeroId != null) {
      playerHeroes = [
        _findHero(settings.player1HeroId),
        _findHero(settings.player2HeroId),
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

  void _loadCustomHeroesSync() {
    // Load synchronously from shared prefs cache if available
    SharedPreferences.getInstance().then((prefs) {
      final jsonStr = prefs.getString('custom_heroes') ?? '[]';
      final List<dynamic> list = jsonDecode(jsonStr);
      final customs = list.map((map) {
        return HeroData(
          id: map['id'] ?? 'custom_unknown',
          name: map['name'] ?? 'Unknown',
          heroClass: HeroClass.values[map['heroClass'] ?? 0],
          talents: [HeroTalent.values[map['talent'] ?? 0]],
          isYoung: false,
          intellect: 0,
          health: 0,
          customImagePath: map['imagePath'],
        );
      }).toList();
      if (mounted) {
        setState(() {
          _customHeroes = customs;
          // Re-resolve heroes if they were custom
          final settings = context.read<GameSettingsProvider>();
          if (settings.player1HeroId != null) {
            final h1 = _findHero(settings.player1HeroId);
            final h2 = _findHero(settings.player2HeroId);
            if (h1 != null && playerHeroes[0] == null) playerHeroes[0] = h1;
            if (h2 != null && playerHeroes[1] == null) playerHeroes[1] = h2;
          }
        });
      }
    });
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
    final TextStyle headingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, shadows: [Shadow(color: Colors.white70, blurRadius: 10), Shadow(color: Colors.white54, blurRadius: 20)]);
    final TextStyle labelStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black, shadows: [Shadow(color: Colors.white70, blurRadius: 10), Shadow(color: Colors.white54, blurRadius: 20)]);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _backgroundPath != null
                ? Image.asset(
                    _backgroundPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Theme.of(context).scaffoldBackgroundColor),
                  )
                : Container(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.45)),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- Starting Life ---
                        Text('Starting Life', style: headingStyle),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Life: ', style: labelStyle),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: customLifeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                                maxLength: 2,
                                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[400],
                                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
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
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (int life in [20, 25, 30, 40])
                              ChoiceChip(
                                label: Text('$life', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                                selected: selectedLife == life,
                                backgroundColor: Colors.grey[400],
                                selectedColor: Colors.grey[500],
                                onSelected: (_) {
                                  setState(() { selectedLife = life; customLifeController.text = life.toString(); });
                                  settings.updateStartingLife(life);
                                },
                              ),
                          ],
                        ),

                        // --- Choose Heroes ---
                        SizedBox(height: 36),
                        Text('Choose Heroes', style: headingStyle),
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
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
                                    maxLength: 50,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      filled: true,
                                      fillColor: Colors.grey[400],
                                      counterText: '',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.black)),
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
                                            child: _customHeroes.any((h) => h.id == playerHeroes[p]!.id)
                                                ? CustomImage(path: playerHeroes[p]!.customImagePath, fit: BoxFit.cover)
                                                : HeroImage(hero: playerHeroes[p]!, fit: BoxFit.cover),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: playerHeroes[p] != null ? Colors.black : Colors.grey[600],
                                      shadows: [Shadow(color: Colors.white54, blurRadius: 8)],
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // --- Match Timer ---
                        if (settings.clockEnabled) ...[
                        SizedBox(height: 36),
                        Text('Match Timer', style: headingStyle),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Minutes: ', style: labelStyle),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: timerController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                                maxLength: 2,
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[400],
                                  border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
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
                        SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (int preset in [30, 35, 55, 60])
                              ChoiceChip(
                                label: Text('$preset', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                                selected: matchTimerMinutes == preset,
                                backgroundColor: Colors.grey[400],
                                selectedColor: Colors.grey[500],
                                onSelected: (_) {
                                  setState(() { matchTimerMinutes = preset; timerController.text = preset.toString(); });
                                  settings.updateMatchTimer(preset);
                                },
                              ),
                          ],
                        ),

                        // --- Start Game ---
                        ],
                        SizedBox(height: 48),
                        GestureDetector(
                          onTap: selectedLife >= 1
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        final p1 = player1NameController.text.isEmpty ? 'Player 1' : player1NameController.text;
                                        final p2 = player2NameController.text.isEmpty ? 'Player 2' : player2NameController.text;
                                        settings.player1Name = p1;
                                        settings.player2Name = p2;
                                        // Empty field at match start = use the minimum value. Avoids
                                        // a stale state-var value from a previous keystroke leaking
                                        // through after the user clears the input.
                                        final lifeToUse = customLifeController.text.trim().isEmpty
                                            ? 20
                                            : selectedLife;
                                        final timerToUse = timerController.text.trim().isEmpty
                                            ? 30
                                            : matchTimerMinutes;
                                        return CounterScreen(
                                          startingLife: lifeToUse,
                                          playerHeroes: [
                                            playerHeroes[0]?.id ?? 'default',
                                            playerHeroes[1]?.id ?? 'default',
                                          ],
                                          playerNames: [p1, p2],
                                          matchTimerMinutes: timerToUse,
                                        );
                                      },
                                    ),
                                  );
                                }
                              : null,
                          child: SizedBox(
                            width: 300,
                            height: 55,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/ui/play_button.png',
                                  width: 300,
                                  height: 45,
                                  fit: BoxFit.fill,
                                ),
                                Text(
                                  'Start Game',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                  ),
                                ),
                              ],
                            ),
                          ),
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