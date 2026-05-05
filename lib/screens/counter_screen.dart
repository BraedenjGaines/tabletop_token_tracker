import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';
import '../state/match_state.dart';
import '../data/fab_phases.dart';
import '../state/floating_damage_controller.dart';
import '../state/match_timer_controller.dart';
import '../state/player_overlay.dart';
import 'widgets/match_chrome_buttons.dart';
import 'widgets/match_overlays.dart';
import 'widgets/player_panel.dart';
import 'widgets/turn_tracker_panel.dart';
import 'settings_screen.dart';
import 'log_screen.dart';
import '../data/token_library.dart';
import '../data/token_preferences.dart';
import '../data/game_log.dart';
import '../data/active_token.dart';
import 'widgets/armor_slot_widget.dart';
import 'widgets/timer_display.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/custom_hero_repository.dart';
import '../data/app_assets.dart';
import '../data/hero_library.dart';

class CounterScreen extends StatefulWidget {
  final int startingLife;
  final List<String> playerHeroes;
  final List<String> playerNames;
  final int matchTimerMinutes;

  const CounterScreen({
    super.key,
    required this.startingLife,
    required this.playerHeroes,
    required this.playerNames,
    required this.matchTimerMinutes,
  });

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> with TickerProviderStateMixin {

  late final MatchState matchState;

  // Read-through alias to MatchState's tokens. Mutations must go through
  // MatchState; raw access here is only for read paths and legacy mutations
  // that haven't been migrated yet.
  List<List<ActiveToken>> get playerTokens => List.generate(
        MatchState.playerCount,
        (i) => matchState.rawTokensOf(i),
      );

  // activePlayer, currentPhase, turnCount, _playerPitch, _playerAP all live on
  // matchState now. Convenience getters preserve call-site readability.
  int get activePlayer => matchState.activePlayer;
  int get currentPhase => matchState.currentPhase;
  int get turnCount => matchState.turnCount;

  late final FloatingDamageController _damageController;

  List<TokenData> customTokens = [];
  List<String> favoriteTokens = [];

  GameLog get gameLog => matchState.gameLog;

  // Match timer
  late final MatchTimerController _timerController;

  // First-turn chooser shown at game start. Dice overlay flow is handled
  // internally by MatchStartOverlays.
  bool _showFirstTurnChooser = true;

  // Per-player overlay state — what (if anything) is currently shown over each panel.
  late List<PlayerOverlay> _playerOverlay;

  final Map<TokenDisplayBucket, String> _categoryNames = {
    TokenDisplayBucket.ally: 'Allies',
    TokenDisplayBucket.item: 'Items',
    TokenDisplayBucket.buffAura: 'Buffs',
    TokenDisplayBucket.debuffAura: 'Debuffs',
    TokenDisplayBucket.genericToken: 'Tokens',
    TokenDisplayBucket.landmark: 'Landmarks',
  };

  final Map<TokenDisplayBucket, Color> _categoryColors = {
    TokenDisplayBucket.ally: const Color.fromARGB(255, 160, 106, 25),
    TokenDisplayBucket.buffAura: const Color.fromARGB(255, 41, 134, 177),
    TokenDisplayBucket.debuffAura: const Color.fromARGB(255, 120, 32, 136),
    TokenDisplayBucket.item: const Color(0xFFD2A679),
    TokenDisplayBucket.genericToken: const Color.fromARGB(255, 80, 80, 80),
    TokenDisplayBucket.landmark: const Color.fromARGB(255, 56, 142, 60),
  };

  bool get _showTurnTracker {
    return context.read<GameSettingsProvider>().turnTrackerEnabled;
  }

  bool get _showMiddleBar {
    final settings = context.read<GameSettingsProvider>();
    if (_showTurnTracker) return true;
    return settings.resourceTrackerSetting != 3;
  }

  String? get _currentPhaseName =>
      _showTurnTracker ? fabPhases[currentPhase] : null;

  List<HeroData> _getCustomHeroes() {
    try {
      final prefs = _customHeroesCache;
      if (prefs != null) return prefs;
      return [];
    } catch (_) {
      return [];
    }
  }
  List<HeroData>? _customHeroesCache;

  Future<void> _loadCustomHeroesCache() async {
    final heroes = await CustomHeroRepository.loadAll();
    if (mounted) setState(() { _customHeroesCache = heroes; });
  }

  void _log(int playerIndex, LogEventType type, String description, {int value = 0, Map<String, dynamic>? undoData}) {
    final int minutes = _timerController.secondsRemaining ~/ 60;
    final int seconds = _timerController.secondsRemaining % 60;
    final String timerStamp = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    matchState.addLogEntry(LogEntry(
      playerIndex: playerIndex, type: type, description: description,
      value: value, timestamp: timerStamp,
      turn: _showTurnTracker ? turnCount : null, phase: _currentPhaseName,
      undoData: undoData,
    ));
  }

  void _undoLastEntry() {
    if (gameLog.entries.isEmpty) return;

    int targetIndex = -1;
    for (int i = gameLog.entries.length - 1; i >= 0; i--) {
      final e = gameLog.entries[i];
      if (e.type != LogEventType.phaseChange && e.type != LogEventType.tokenActivated) {
        targetIndex = i;
        break;
      }
    }
    if (targetIndex < 0) return;

    final entry = gameLog.entries[targetIndex];

    switch (entry.type) {
      case LogEventType.healthChange:
        matchState.reverseHealthDelta(entry.playerIndex, entry.value);
        break;
      case LogEventType.tokenAdded:
        if (entry.undoData != null) {
          final name = entry.undoData!['name'] as String;
          matchState.removeLastTokenByName(entry.playerIndex, name);
        }
        break;
      case LogEventType.tokenDestroyed:
        if (entry.undoData != null) {
          final d = entry.undoData!;
          final token = ActiveToken(
            name: d['name'],
            category: TokenCategory.values[d['category']],
            auraType: d['auraType'] != null ? AuraType.values[d['auraType']] : null,
            destroyTrigger: d['destroyTrigger'] != null ? DestroyTrigger.values[d['destroyTrigger']] : null,
            count: d['count'] ?? 1,
            health: d['health'],
            maxHealth: d['maxHealth'],
            turnPlayed: d['turnPlayed'] ?? 0,
            playerPlayed: d['playerPlayed'] ?? 0,
            phasePlayed: d['phasePlayed'] ?? 0,
          );
          final insertIdx = d['index'] as int? ?? matchState.tokensOf(entry.playerIndex).length;
          matchState.insertToken(entry.playerIndex, insertIdx, token);
        }
        break;
      case LogEventType.tokenCountChange:
        if (entry.undoData != null) {
          final name = entry.undoData!['name'] as String;
          matchState.mutateTokenCount(entry.playerIndex, name, -entry.value);
        }
        break;
      case LogEventType.allyHealthChange:
        if (entry.undoData != null) {
          final name = entry.undoData!['name'] as String;
          matchState.mutateAllyHealth(entry.playerIndex, name, -entry.value);
        }
        break;
      default:
        break;
    }
    matchState.removeLogEntryAt(targetIndex);
  }

  @override
  void initState() {
    super.initState();
    matchState = MatchState(
      startingLife: widget.startingLife,
      phaseCount: fabPhases.length,
      armorSlotsPerPlayer: 4,
    );
    _playerOverlay = List.filled(2, const NoOverlay());
    _timerController = MatchTimerController(
      initialSeconds: widget.matchTimerMinutes * 60,
    );
    _damageController = FloatingDamageController(vsync: this);

    _loadTokenPreferences();
    _loadCustomHeroesCache();
    WakelockPlus.enable();
    // Precache pitch icons
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(AssetImage(AppAssets.pitchValueZero), context);
      precacheImage(AssetImage(AppAssets.pitchValueOne), context);
      precacheImage(AssetImage(AppAssets.pitchValueTwo), context);
      precacheImage(AssetImage(AppAssets.pitchValueThree), context);
    });
    // First turn chooser shows automatically — no _handleFirstTurn needed
  }

  void _onFirstPlayerChosen(int playerIndex) {
    matchState.setInitialActivePlayer(playerIndex);
    setState(() {
      _showFirstTurnChooser = false;
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _timerController.dispose();
    _damageController.dispose();
    super.dispose();
  }

  void _spawnFloatingNumber(int playerIndex, int delta) {
    final settings = context.read<GameSettingsProvider>();
    final mode = settings.damageDisplayMode == 0
        ? DamageDisplayMode.cascading
        : DamageDisplayMode.totals;
    _damageController.spawnDelta(playerIndex, delta, mode);
  }

  // --- Token prefs ---
  Future<void> _loadTokenPreferences() async {
    final customs = await TokenPreferences.getCustomTokens();
    final favs = await TokenPreferences.getFavorites();
    if (mounted) setState(() { customTokens = customs; favoriteTokens = favs; });
  }

  int? _getQuarterTurns(int index) {
    return index == 0 ? 2 : null;
  }

  // --- Phase / turn ---
  void _advancePhase() {
    final result = matchState.advancePhase(autoDestroyEnabled: _showTurnTracker);
    for (final r in result.destroyedTokens) {
      _log(r.playerIndex, LogEventType.tokenDestroyed, '${r.token.name} destroyed', undoData: {
        'name': r.token.name,
        'category': r.token.category.index,
        'destroyTrigger': r.token.destroyTrigger?.index,
        'count': r.token.count,
        'health': r.token.health,
        'maxHealth': r.token.maxHealth,
        'turnPlayed': r.token.turnPlayed,
        'playerPlayed': r.token.playerPlayed,
        'phasePlayed': r.token.phasePlayed,
        'index': r.formerIndex,
      });
    }
  }

  void _retreatPhase() {
    matchState.retreatPhase();
  }

  /// A token is "activated" when current state matches its trigger phase
  /// AND that trigger phase comes strictly after the moment it was played.
  bool _isTokenTriggering(ActiveToken t, int pi) {
    if (!_showTurnTracker) return false;
    return MatchState.isActivatedAt(t, pi, turnCount, currentPhase, activePlayer);
  }

  // --- Category management overlay ---
  Widget _buildCategoryOverlay(int playerIndex, TokenDisplayBucket cat) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: Consumer<MatchState>(
            builder: (context, state, _) {
              final tokens = <int>[];
              final list = state.rawTokensOf(playerIndex);
              for (int i = 0; i < list.length; i++) {
                if (list[i].displayBucket == cat) tokens.add(i);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_categoryNames[cat] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      GestureDetector(onTap: () { setState(() { _playerOverlay[playerIndex] = const NoOverlay(); }); }, child: Icon(Icons.close, color: Colors.white, size: 22)),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (tokens.isEmpty)
                    Padding(padding: EdgeInsets.all(16), child: Text('No ${_categoryNames[cat]?.toLowerCase()} in play', style: TextStyle(color: Colors.grey)))
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (int ti in tokens)
                              _buildTokenTile(list[ti], playerIndex, ti, MediaQuery.of(context).size.width * 0.8),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTokenTile(ActiveToken token, int pi, int ti, double containerWidth) {
    final bool triggering = _isTokenTriggering(token, pi);
    final bool isAlly = token.category == TokenCategory.ally;
    final int displayValue = isAlly ? (token.health ?? 0) : token.count;
    final double tileWidth = (containerWidth - 32) / 3; // 3 per row, 8px spacing x2, minus padding

    return SizedBox(
      width: tileWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name above tile — fixed height so tiles align
              SizedBox(
                height: 18,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    token.name,
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: 2),
              // Tile
              Container(
                height: tileWidth * 1.2,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _categoryColors[token.displayBucket]!.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: triggering
                      ? Border.all(color: Colors.amber, width: 2)
                      : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  boxShadow: triggering
                      ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                      : [],
                ),
                child: Stack(
                  children: [
                    // Token card art background — cropped to art region
                    Positioned.fill(
                      child: _TokenArtBackground(tokenName: token.name, customImagePath: token.customImagePath),
                    ),
                    // Dark overlay for readability
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.4)),
                    ),
                    // Controls
                    Row(
                  children: [
                    // Left half: subtract
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isAlly) {
                            final int newHealth = token.health! - 1;
                            if (newHealth <= 0) {
                              final undoData = {'name': token.name, 'category': token.category.index, 'auraType': token.auraType?.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};
                              matchState.removeTokenAt(pi, ti);
                              _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                              if (!matchState.hasTokensInCategory(pi, token.category)) {
                                setState(() { _playerOverlay[pi] = const NoOverlay(); });
                              }
                            } else {
                              matchState.setTokenHealth(pi, token, newHealth);
                              _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: -1, undoData: {'name': token.name});
                            }
                          } else {
                            final int newCount = token.count - 1;
                            if (newCount <= 0) {
                              final undoData = {'name': token.name, 'category': token.category.index, 'auraType': token.auraType?.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};                              matchState.removeTokenAt(pi, ti);
                              _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                              if (!matchState.hasTokensInCategory(pi, token.category)) {
                                setState(() { _playerOverlay[pi] = const NoOverlay(); });
                              }
                            } else {
                              matchState.setTokenCount(pi, token, newCount);
                              _log(pi, LogEventType.tokenCountChange, token.name, value: -1, undoData: {'name': token.name, 'category': token.category.index});
                            }
                          }
                        },
                        child: Center(child: Stack(children: [
                          Text('-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter', foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black)),
                          Text('-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                        ])),
                      ),
                    ),
                    // Center: count/health
                    IgnorePointer(
                      child: Stack(
                        children: [
                          Text('$displayValue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Inter', foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black)),
                          Text('$displayValue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                    // Right half: add
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (isAlly) {
                            if (token.health! < 99) {
                              matchState.setTokenHealth(pi, token, token.health! + 1);
                              _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: 1, undoData: {'name': token.name});
                            }
                          } else {
                            if (token.count < 99) {
                              matchState.setTokenCount(pi, token, token.count + 1);
                              _log(pi, LogEventType.tokenCountChange, token.name, value: 1, undoData: {'name': token.name, 'category': token.category.index});
                            }
                          }
                        },
                        child: Center(child: Stack(children: [
                          Text('+', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter', foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black)),
                          Text('+', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                        ])),
                      ),
                    ),
                  ],
                  ),
                  ],
                ),
              ),
              // Trash icon below-right
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    final undoData = {'name': token.name, 'category': token.category.index, 'auraType': token.auraType?.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};                    matchState.removeTokenAt(pi, ti);
                    _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                    if (!matchState.hasTokensInCategory(pi, token.category)) {
                      setState(() { _playerOverlay[pi] = const NoOverlay(); });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, right: 2),
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  // --- Add token picker overlay ---
  Widget _buildAddTokenOverlay(int playerIndex) {
    final List<TokenData> allTokens = [...tokenLibrary, ...customTokens];

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: _InlineTokenPicker(
            allTokens: allTokens,
            favoriteTokens: favoriteTokens,
            playerTokens: playerTokens[playerIndex],
            onTokenAdded: (TokenData td) {
              if (td.destroyTrigger != null && td.category != TokenCategory.ally) {
                final merged = matchState.incrementCountOfDormantToken(
                  playerIndex,
                  td.name,
                  isTriggering: (t, pi) => _isTokenTriggering(t, pi),
                );
                if (merged) {
                  _log(playerIndex, LogEventType.tokenCountChange, td.name, value: 1, undoData: {'name': td.name, 'category': td.category.index});
                  setState(() { _playerOverlay[playerIndex] = const NoOverlay(); });
                  return;
                }
              }
              matchState.addToken(playerIndex, ActiveToken(
                name: td.name, category: td.category, auraType: td.auraType, destroyTrigger: td.destroyTrigger,
                customImagePath: td.customImagePath,
                health: td.category == TokenCategory.ally ? td.health : null,
                maxHealth: td.category == TokenCategory.ally ? td.health : null,
                turnPlayed: turnCount, playerPlayed: playerIndex, phasePlayed: currentPhase,
              ));
              _log(playerIndex, LogEventType.tokenAdded, '${td.name} added', undoData: {'name': td.name, 'category': td.category.index});
              setState(() { _playerOverlay[playerIndex] = const NoOverlay(); });
            },
            onCustomTokenAdded: (TokenData td) { setState(() { customTokens.add(td); }); },
            onFavoriteToggled: (name, faves) { setState(() { favoriteTokens = faves; }); },
            onClose: () { setState(() { _playerOverlay[playerIndex] = const NoOverlay(); }); },
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerOverlayPositioned(int index, Widget overlay) {
    final double halfHeight = MediaQuery.of(context).size.height / 2;
    final int? qt = _getQuarterTurns(index);
    return Positioned(
      top: index == 0 ? 0 : halfHeight,
      left: 0, right: 0, height: halfHeight,
      child: qt != null ? RotatedBox(quarterTurns: qt, child: overlay) : overlay,
    );
  }

  Widget _buildPlayerWidget(int index) {
    Widget content = PlayerPanel(
      playerIndex: index,
      heroId: widget.playerHeroes[index],
      customHeroes: _getCustomHeroes(),
      showTurnTracker: _showTurnTracker,
      onHealthChanged: (actualDelta) {
        _log(index, LogEventType.healthChange, 'Health', value: actualDelta);
        _spawnFloatingNumber(index, actualDelta);
      },
      onAddTokenTap: () {
        setState(() { _playerOverlay[index] = const AddTokenOverlay(); });
      },
      onCategoryTap: (cat) {
        setState(() { _playerOverlay[index] = CategoryOverlay(cat); });
      },
      isTokenTriggering: _isTokenTriggering,
      floatingNumbersBuilder: ({required negative}) => FloatingNumbersSide(
        controller: _damageController,
        playerIndex: index,
        negative: negative,
      ),
      totalsDisplayBuilder: ({required negative}) => TotalsDisplaySide(
        controller: _damageController,
        playerIndex: index,
        negative: negative,
      ),
    );
    final int? qt = _getQuarterTurns(index);
    if (qt != null) content = RotatedBox(quarterTurns: qt, child: content);
    return content;
  }

  // --- Grid ---
  Widget _buildPlayerGrid() {
    if (!_showMiddleBar) {
      return Column(children: [
        Expanded(child: _buildPlayerWidget(0)),
        Expanded(child: _buildPlayerWidget(1)),
      ]);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(children: [
          Expanded(child: _buildPlayerWidget(0)),
          const SizedBox(height: 55),
          Expanded(child: _buildPlayerWidget(1)),
        ]),
        if (_showTurnTracker)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                const Spacer(),
                TurnTrackerPanel(
                  playerNames: widget.playerNames,
                  onAdvancePhase: _advancePhase,
                  onRetreatPhase: _retreatPhase,
                ),
                const Spacer(),
              ],
            ),
          ),
      ],
    );
  }

  // --- Chrome button handlers ---
  void _onHomePressed() {
    if (gameLog.entries.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave Game', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'A game is in progress. Are you sure you want to return to the home screen?',
            style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 16),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                _timerController.pause();
                Navigator.pop(ctx);
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      _timerController.pause();
      Navigator.popUntil(context, (r) => r.isFirst);
    }
  }

  void _onResetPressed() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Game', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Reset all health, tokens, timer, and log?',
          style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                matchState.resetAll();
                _playerOverlay = List.filled(2, const NoOverlay());
                _showFirstTurnChooser = true;
              });
              _timerController.reset();
              _damageController.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onSettingsPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _onShowLogPressed() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: LogScreen(
          gameLog: gameLog,
          onUndo: _undoLastEntry,
          playerNames: widget.playerNames,
        ),
      ),
    );
  }

  // --- Main build ---
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GameSettingsProvider>();

    return ChangeNotifierProvider<MatchState>.value(
      value: matchState,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
          _buildPlayerGrid(),
          // Timer top (rotated for P1)
          if (settings.clockEnabled) Positioned(top: 35, left: 0, right: 0, child: Center(child: RotatedBox(quarterTurns: 2, child: ListenableBuilder(
            listenable: _timerController,
            builder: (context, _) => TimerDisplay(
              secondsRemaining: _timerController.secondsRemaining,
              isRunning: _timerController.isRunning,
              onReset: _timerController.reset,
              onToggle: _timerController.toggle,
            ),
          )))),
          if (settings.clockEnabled) Positioned(bottom: 35, left: 0, right: 0, child: Center(child: ListenableBuilder(
            listenable: _timerController,
            builder: (context, _) => TimerDisplay(
              secondsRemaining: _timerController.secondsRemaining,
              isRunning: _timerController.isRunning,
              onReset: _timerController.reset,
              onToggle: _timerController.toggle,
            ),
          ))),
          // Player 1 armor
          if (settings.armorTrackingEnabled)
            Positioned(
              top: 90, left: 8,
              child: RotatedBox(quarterTurns: 2, child: Consumer<MatchState>(
                builder: (context, state, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                  ArmorSlotWidget(state: state.armorSlot(0, 0), slotIndex: 0, onIncrement: () => matchState.incrementArmor(0, 0), onDecrement: () => matchState.decrementArmor(0, 0), onDestroy: () => matchState.destroyArmor(0, 0)),
                  ArmorSlotWidget(state: state.armorSlot(0, 1), slotIndex: 1, onIncrement: () => matchState.incrementArmor(0, 1), onDecrement: () => matchState.decrementArmor(0, 1), onDestroy: () => matchState.destroyArmor(0, 1)),
                ]),
              )),
            ),
          if (settings.armorTrackingEnabled)
            Positioned(
              top: 90, right: 8,
              child: RotatedBox(quarterTurns: 2, child: Consumer<MatchState>(
                builder: (context, state, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                  ArmorSlotWidget(state: state.armorSlot(0, 2), slotIndex: 2, onIncrement: () => matchState.incrementArmor(0, 2), onDecrement: () => matchState.decrementArmor(0, 2), onDestroy: () => matchState.destroyArmor(0, 2)),
                  ArmorSlotWidget(state: state.armorSlot(0, 3), slotIndex: 3, onIncrement: () => matchState.incrementArmor(0, 3), onDecrement: () => matchState.decrementArmor(0, 3), onDestroy: () => matchState.destroyArmor(0, 3)),
                ]),
              )),
            ),
          // Player 2 armor
          if (settings.armorTrackingEnabled)
            Positioned(
              bottom: 90, left: 8,
              child: Consumer<MatchState>(
                builder: (context, state, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                  ArmorSlotWidget(state: state.armorSlot(1, 0), slotIndex: 0, onIncrement: () => matchState.incrementArmor(1, 0), onDecrement: () => matchState.decrementArmor(1, 0), onDestroy: () => matchState.destroyArmor(1, 0)),
                  ArmorSlotWidget(state: state.armorSlot(1, 1), slotIndex: 1, onIncrement: () => matchState.incrementArmor(1, 1), onDecrement: () => matchState.decrementArmor(1, 1), onDestroy: () => matchState.destroyArmor(1, 1)),
                ]),
              ),
            ),
          if (settings.armorTrackingEnabled)
            Positioned(
              bottom: 90, right: 8,
              child: Consumer<MatchState>(
                builder: (context, state, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                  ArmorSlotWidget(state: state.armorSlot(1, 2), slotIndex: 2, onIncrement: () => matchState.incrementArmor(1, 2), onDecrement: () => matchState.decrementArmor(1, 2), onDestroy: () => matchState.destroyArmor(1, 2)),
                  ArmorSlotWidget(state: state.armorSlot(1, 3), slotIndex: 3, onIncrement: () => matchState.incrementArmor(1, 3), onDecrement: () => matchState.decrementArmor(1, 3), onDestroy: () => matchState.destroyArmor(1, 3)),
                ]),
              ),
            ),
          MatchChromeButtons(
            onHome: _onHomePressed,
            onReset: _onResetPressed,
            onSettings: _onSettingsPressed,
            onShowLog: _onShowLogPressed,
          ),
          // First-turn chooser and dice overlay are coordinated together.
          Positioned.fill(child: MatchStartOverlays(
            playerNames: widget.playerNames,
            show: _showFirstTurnChooser,
            onFirstPlayerChosen: _onFirstPlayerChosen,
          )),
          // Player overlays
          for (int i = 0; i < 2; i++)
            if (_playerOverlay[i] case CategoryOverlay(bucket: final cat))
              _buildPlayerOverlayPositioned(i, _buildCategoryOverlay(i, cat)),
          for (int i = 0; i < 2; i++)
            if (_playerOverlay[i] is AddTokenOverlay)
              _buildPlayerOverlayPositioned(i, _buildAddTokenOverlay(i)),
        ]),
        ),
      ),
    );
  }
}

class _TokenArtBackground extends StatelessWidget {
  final String tokenName;
  final String? customImagePath;

  const _TokenArtBackground({required this.tokenName, this.customImagePath});

  String _getTokenId(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    if (customImagePath != null) {
      return Image.file(
        File(customImagePath!),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const SizedBox.shrink(),
      );
    }

    final id = _getTokenId(tokenName);
    final path = AppAssets.tokenArtFor(id);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Crop values for token card art region
        const double cropLeft = 0.10;
        const double cropTop = 0.14;
        const double cropRight = 0.90;
        const double cropBottom = 0.56;
        const double cropW = cropRight - cropLeft;
        const double cropH = cropBottom - cropTop;

        final double viewW = constraints.maxWidth;
        final double viewH = constraints.maxHeight;

        final double scaleByWidth = viewW / cropW;
        final double scaleByHeight = viewH / cropH;
        final double scale = scaleByWidth > scaleByHeight ? scaleByWidth : scaleByHeight;

        // Source card aspect ratio (standard card is roughly 5:7)
        const double cardAspect = 5.0 / 7.0;
        final double imgW = scale * cardAspect;
        final double imgH = scale;
        final double artWPx = cropW * imgW;
        final double artHPx = cropH * imgH;
        final double adjustedOffsetX = -cropLeft * imgW + (viewW - artWPx) / 2;
        final double adjustedOffsetY = -cropTop * imgH + (viewH - artHPx) / 2;

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: adjustedOffsetX,
              top: adjustedOffsetY,
              width: imgW,
              height: imgH,
              child: Image.asset(
                path,
                fit: BoxFit.fill,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- Inline token picker ---
class _InlineTokenPicker extends StatefulWidget {
  final List<TokenData> allTokens;
  final List<String> favoriteTokens;
  final List<ActiveToken> playerTokens;
  final Function(TokenData) onTokenAdded;
  final Function(TokenData) onCustomTokenAdded;
  final Function(String, List<String>) onFavoriteToggled;
  final VoidCallback onClose;

  const _InlineTokenPicker({required this.allTokens, required this.favoriteTokens, required this.playerTokens, required this.onTokenAdded, required this.onCustomTokenAdded, required this.onFavoriteToggled, required this.onClose});

  @override
  State<_InlineTokenPicker> createState() => _InlineTokenPickerState();
}

class _InlineTokenPickerState extends State<_InlineTokenPicker> {
  String searchQuery = '';
  final Set<TokenDisplayBucket> selectedCategories = {};
  final searchController = TextEditingController();
  late List<String> currentFavorites;
  final Map<TokenDisplayBucket, String> catNames = {
    TokenDisplayBucket.buffAura: 'Buffs',
    TokenDisplayBucket.debuffAura: 'Debuffs',
    TokenDisplayBucket.item: 'Items',
    TokenDisplayBucket.ally: 'Allies',
    TokenDisplayBucket.genericToken: 'Tokens',
    TokenDisplayBucket.landmark: 'Landmarks',
  };

  @override
  void initState() { super.initState(); currentFavorites = List.from(widget.favoriteTokens); }
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  List<TokenData> _getFiltered() {
    var tokens = List<TokenData>.from(widget.allTokens);
    if (selectedCategories.isNotEmpty) tokens = tokens.where((t) => selectedCategories.contains(t.displayBucket)).toList();
    if (searchQuery.isNotEmpty) tokens = tokens.where((t) => t.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    final favs = tokens.where((t) => currentFavorites.contains(t.name)).toList()..sort((a, b) => a.name.compareTo(b.name));
    final rest = tokens.where((t) => !currentFavorites.contains(t.name)).toList()..sort((a, b) => a.name.compareTo(b.name));
    return [...favs, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Add Token', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          GestureDetector(onTap: widget.onClose, child: Icon(Icons.close, color: Colors.white, size: 22)),
        ]),
        SizedBox(height: 1),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (var c in [
              TokenDisplayBucket.buffAura,
              TokenDisplayBucket.debuffAura,
              TokenDisplayBucket.item,
              TokenDisplayBucket.ally,
            ])
              Padding(padding: EdgeInsets.only(right: 4), child: FilterChip(label: Text(catNames[c] ?? '', style: TextStyle(fontSize: 14)), selected: selectedCategories.contains(c), showCheckmark: false, onSelected: (_) { setState(() { selectedCategories.contains(c) ? selectedCategories.remove(c) : selectedCategories.add(c); }); }, visualDensity: VisualDensity.compact)),
          ]),
        ),
        SizedBox(height: 6),
        Flexible(
          child: filtered.isEmpty
              ? Center(child: Text('No tokens found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final td = filtered[index];
                    final fav = currentFavorites.contains(td.name);
                    final inPlayCount = widget.playerTokens.where((t) => t.name == td.name).fold<int>(0, (sum, t) => sum + t.count);
                    return ListTile(
                      dense: true, visualDensity: VisualDensity.compact,
                      leading: GestureDetector(
                        onTap: () async {
                          await TokenPreferences.toggleFavorite(td.name);
                          if (!mounted) return;
                          setState(() { fav ? currentFavorites.remove(td.name) : currentFavorites.add(td.name); });
                          widget.onFavoriteToggled(td.name, List.from(currentFavorites));
                        },
                        child: Icon(fav ? Icons.star : Icons.star_border, color: fav ? Colors.amber : Colors.grey, size: 20),
                      ),
                      title: Text(td.name, style: TextStyle(fontSize: 13, color: Colors.white)),
                      subtitle: Text(catNames[td.displayBucket] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (inPlayCount > 0) Padding(padding: EdgeInsets.only(right: 6), child: Text('x$inPlayCount', style: TextStyle(fontSize: 11, color: Colors.grey))),
                          Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
                        ],
                      ),
                      onTap: () { widget.onTokenAdded(td); },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
