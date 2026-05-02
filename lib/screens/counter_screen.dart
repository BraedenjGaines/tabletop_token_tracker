import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';
import '../state/match_state.dart';
import 'settings_screen.dart';
import 'log_screen.dart';
import '../data/token_library.dart';
import '../data/token_preferences.dart';
import '../data/game_log.dart';
import '../data/active_token.dart';
import 'widgets/armor_slot_widget.dart';
import 'widgets/timer_display.dart';
import 'widgets/dice_overlay.dart';
import 'dart:ui';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../data/custom_hero_repository.dart';
import '../data/app_assets.dart';
import '../data/hero_library.dart';
import 'widgets/hero_image.dart';

class _FloatingNumber {
  final int value;
  final AnimationController controller;
  final int playerIndex;
  final double arcDirection;
  final double spawnOffset; // horizontal offset for staggered spawns

  _FloatingNumber({
    required this.value,
    required this.controller,
    required this.playerIndex,
    required this.arcDirection,
    required this.spawnOffset,
  });
}

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
  // --- Layout constants (fractions of screen width) ---
  // These position the add-token button and the pitch counter inside each
  // player panel. The "WithResource" variants are tighter to make room for an
  // adjacent resource counter; the "NoResource" variants spread out when no
  // resource counter is shown.
  static const double _panelButtonWidth = 0.26;
  static const double _panelButtonHeight = 0.13;
  static const double _panelInsetWithResource = 0.22;
  static const double _panelInsetNoResource = 0.365;

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

  final List<_FloatingNumber> _floatingNumbers = [];
  int _floatSpawnIndex = 0; // cycles 0,1,2 for staggered spawn points

  // Accumulator tracking: running total per player per sign direction
  // Key = "playerIndex_neg" or "playerIndex_pos"
  final Map<String, int> _accumulatorValues = {};
  final Map<String, Timer> _accumulatorTimers = {};

  // Totals mode: stationary display per player per sign direction
  final Map<String, int> _totalsValues = {};
  final Map<String, AnimationController> _totalsControllers = {};
  final Map<String, Timer> _totalsTimers = {};

  List<TokenData> customTokens = [];
  List<String> favoriteTokens = [];

  GameLog get gameLog => matchState.gameLog;

  // Match timer
  late int _timerSecondsRemaining;
  Timer? _timer;
  bool _timerRunning = false;
  bool _timerFlashOn = true;
  Timer? _flashTimer;
  bool _hasExpiredBuzzStarted = false;

  // First turn chooser — always shown at game start
  bool _showFirstTurnChooser = true;
  bool _showDiceOverlay = false;

  // Per-player overlay state: -1 = none, -2 = add token picker, 0-3 = category index
  late List<int> _playerOverlay;

  final List<String> fabPhases = ['Start Phase', 'Action Phase', 'End Phase'];

  final Map<TokenCategory, String> _categoryNames = {
    TokenCategory.ally: 'Allies',
    TokenCategory.item: 'Items',
    TokenCategory.boonAura: 'Buffs',
    TokenCategory.debuffAura: 'Debuffs',
  };

  final Map<TokenCategory, Color> _categoryColors = {
    TokenCategory.ally: const Color.fromARGB(255, 160, 106, 25),
    TokenCategory.boonAura: const Color.fromARGB(255, 41, 134, 177),
    TokenCategory.debuffAura: const Color.fromARGB(255, 120, 32, 136),
    TokenCategory.item: Color(0xFFD2A679),
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
    final int minutes = _timerSecondsRemaining ~/ 60;
    final int seconds = _timerSecondsRemaining % 60;
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
    _playerOverlay = List.filled(2, -1);
    _timerSecondsRemaining = widget.matchTimerMinutes * 60;

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

  void _onFirstTurnDirectChoice(int player) {
    matchState.setInitialActivePlayer(player);
    setState(() {
      _showFirstTurnChooser = false;
    });
  }

  void _onDiceChoice(int winner, bool goFirst) {
    final int chosen = goFirst ? winner : (winner == 0 ? 1 : 0);
    matchState.setInitialActivePlayer(chosen);
    setState(() {
      _showDiceOverlay = false;
      _showFirstTurnChooser = false;
    });
  }

  void _showDiceRoll() {
    setState(() { _showDiceOverlay = true; });
  }

  Widget _buildFirstTurnChooser() {
  return Container(
    color: Colors.black.withValues(alpha: 0.85),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player 1 "Go First" — rotated 180°
          RotatedBox(
            quarterTurns: 2,
            child: SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () => _onFirstTurnDirectChoice(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 60, 143, 63),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${widget.playerNames[0]}\n'),
                    TextSpan(text: 'Goes First'),
                  ]),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 32),

          // Dice button — center
          SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: _showDiceRoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Roll Dice',
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 32),

          // Player 2 "Go First" — normal orientation
          SizedBox(
            width: 300,
            child: ElevatedButton(
              onPressed: () => _onFirstTurnDirectChoice(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 60, 143, 63),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '${widget.playerNames[1]}\n'),
                  TextSpan(text: 'Goes First'),
                ]),
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  void dispose() {
    WakelockPlus.disable();
    _timer?.cancel();
    _flashTimer?.cancel();
    for (final f in _floatingNumbers) { f.controller.dispose(); }
    for (final t in _accumulatorTimers.values) { t.cancel(); }
    for (final c in _totalsControllers.values) { c.dispose(); }
    for (final t in _totalsTimers.values) { t.cancel(); }
    super.dispose();
  }

  void _startTimer() {
    if (_timerRunning) return;
    if (_timerSecondsRemaining <= 0) {
      _resetTimer();
      return;
    }
    _flashTimer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSecondsRemaining > 0) {
          _timerSecondsRemaining--;
        } else {
          _timer?.cancel();
          _timerRunning = false;
          // Start expired buzz and flash
          if (!_hasExpiredBuzzStarted) {
            _hasExpiredBuzzStarted = true;
            _timerFlashOn = false;
            _flashTimer = Timer.periodic(Duration(milliseconds: 500), (t) {
              if (mounted) setState(() { _timerFlashOn = !_timerFlashOn; });
            });
          }
        }
      });
    });
    setState(() {
      _timerRunning = true;
      _hasExpiredBuzzStarted = false;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerFlashOn = true;
      _hasExpiredBuzzStarted = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _flashTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerSecondsRemaining = widget.matchTimerMinutes * 60;
      _timerFlashOn = true;
      _hasExpiredBuzzStarted = false;
    });
  }

  void _spawnFloatingNumber(int playerIndex, int delta) {
    final settings = context.read<GameSettingsProvider>();
    final bool isNeg = delta < 0;
    final String key = '${playerIndex}_${isNeg ? 'neg' : 'pos'}';

    // Update running accumulator
    _accumulatorValues[key] = (_accumulatorValues[key] ?? 0) + delta;
    final resetDuration = 2; // seconds to wait after last change before resetting accumulator
    _accumulatorTimers[key]?.cancel();
    _accumulatorTimers[key] = Timer(Duration(seconds: resetDuration), () {
      _accumulatorValues.remove(key);
      _accumulatorTimers.remove(key);
    });

    final int currentTotal = _accumulatorValues[key]!;

    if (settings.damageDisplayMode == 0) {
      // Floating mode: spawn a new floater with the accumulated value
      // Stagger across 3 spawn points
      final spawnPoints = [-10.0, 0.0, 10.0];
      final spawnOffset = spawnPoints[_floatSpawnIndex % 3];
      _floatSpawnIndex++;

      // Alternate arc direction: even = outward, odd = inward
      final baseDir = isNeg ? -1.0 : 1.0;
      final arcDir = (_floatSpawnIndex % 2 == 0) ? baseDir : -baseDir;

      final controller = AnimationController(
        duration: Duration(milliseconds: 2000),
        vsync: this,
      );

      final floater = _FloatingNumber(
        value: currentTotal,
        controller: controller,
        playerIndex: playerIndex,
        arcDirection: arcDir,
        spawnOffset: spawnOffset,
      );

      setState(() { _floatingNumbers.add(floater); });

      controller.forward().then((_) {
        controller.dispose();
        if (mounted) {
          setState(() { _floatingNumbers.remove(floater); });
        }
      });
    } else {
      // Totals mode: update stationary display
      _totalsValues[key] = currentTotal;
      _totalsControllers[key]?.dispose();
      final controller = AnimationController(
        duration: Duration(seconds: 4),
        vsync: this,
      );
      _totalsControllers[key] = controller;
      controller.forward();
      _totalsTimers[key]?.cancel();
      _totalsTimers[key] = Timer(Duration(seconds: 3), () {
        _totalsValues.remove(key);
        _totalsControllers[key]?.dispose();
        _totalsControllers.remove(key);
        _totalsTimers.remove(key);
        if (mounted) setState(() {});
      });
      setState(() {});
    }
  }

  Widget _buildFloatingNumbersSide(int playerIndex, {required bool negative}) {
    final playerFloaters = _floatingNumbers.where((f) =>
      f.playerIndex == playerIndex && (negative ? f.value < 0 : f.value > 0)
    ).toList();
    if (playerFloaters.isEmpty) return SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final f in playerFloaters)
            AnimatedBuilder(
              animation: f.controller,
              builder: (context, child) {
                final t = f.controller.value;
                final opacity = (1.0 - t).clamp(0.0, 1.0);
                final yOffset = -80 * t;
                final xOffset = f.spawnOffset + (25 * sin(t * pi) * f.arcDirection);

                return Transform.translate(
                  offset: Offset(xOffset, yOffset),
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      f.value > 0 ? '+${f.value}' : '${f.value}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Inter', color: Colors.black, height: 1.0),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTotalsDisplaySide(int playerIndex, {required bool negative}) {
    final key = '${playerIndex}_${negative ? 'neg' : 'pos'}';
    final val = _totalsValues[key];
    final ctrl = _totalsControllers[key];

    if (val == null || ctrl == null) return SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (context, child) {
          final t = ctrl.value;
          final opacity = t < 0.5 ? 1.0 : (1.0 - ((t - 0.5) * 2.0)).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Text(
              negative ? '$val' : '+$val',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Inter', color: Colors.black, height: 1.0),
            ),
          );
        },
      ),
    );
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

  // --- Token category chips ---
  Map<TokenCategory, List<int>> _getTokensByCategory(int playerIndex) {
    final result = <TokenCategory, List<int>>{};
    for (int i = 0; i < playerTokens[playerIndex].length; i++) {
      final cat = playerTokens[playerIndex][i].category;
      result.putIfAbsent(cat, () => []);
      result[cat]!.add(i);
    }
    return result;
  }

  Widget _buildCategoryChip(TokenCategory cat, int count, int playerIndex, double chipWidth, double chipHeight) {
    final bool hasTriggering = playerTokens[playerIndex]
        .where((t) => t.category == cat)
        .any((t) => _isTokenTriggering(t, playerIndex));

    return GestureDetector(
      onTap: () { setState(() { _playerOverlay[playerIndex] = cat.index; }); },
      child: Container(
        width: chipWidth,
        height: chipHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: hasTriggering
              ? Border.all(color: Colors.amber, width: 2)
              : Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -5,
              right: -5,
              top: -5,
              bottom: -5,
              child: Image.asset(
                AppAssets.addTokenButton,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _categoryColors[cat]!.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                if (hasTriggering) Icon(Icons.flash_on, size: 12, color: Colors.amber),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Stack(
                    children: [
                      Text(_categoryNames[cat] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.black), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(_categoryNames[cat] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Stack(
                      children: [
                        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black)),
                        Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenChips(int playerIndex) {
    final byCategory = _getTokensByCategory(playerIndex);
    final List<TokenCategory> order = [TokenCategory.boonAura, TokenCategory.debuffAura, TokenCategory.item, TokenCategory.ally];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth * 0.8;
        final double chipWidth = totalWidth / 4;
        final double chipHeight = chipWidth * 1.2;

        return SizedBox(
          height: chipHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var cat in order)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: byCategory.containsKey(cat)
? _buildCategoryChip(cat, playerTokens[playerIndex].where((t) => t.category == cat).fold<int>(0, (sum, t) => sum + t.count), playerIndex, chipWidth, chipHeight)                    : SizedBox(width: chipWidth, height: chipHeight),
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Category management overlay ---
  Widget _buildCategoryOverlay(int playerIndex, TokenCategory cat) {
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
                if (list[i].category == cat) tokens.add(i);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_categoryNames[cat] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      GestureDetector(onTap: () { setState(() { _playerOverlay[playerIndex] = -1; }); }, child: Icon(Icons.close, color: Colors.white, size: 22)),
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
                  color: _categoryColors[token.category]!.withValues(alpha: 0.6),
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
                              final undoData = {'name': token.name, 'category': token.category.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};
                              matchState.removeTokenAt(pi, ti);
                              _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                              if (!matchState.hasTokensInCategory(pi, token.category)) {
                                setState(() { _playerOverlay[pi] = -1; });
                              }
                            } else {
                              matchState.setTokenHealth(pi, token, newHealth);
                              _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: -1, undoData: {'name': token.name});
                            }
                          } else {
                            final int newCount = token.count - 1;
                            if (newCount <= 0) {
                              final undoData = {'name': token.name, 'category': token.category.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};
                              matchState.removeTokenAt(pi, ti);
                              _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                              if (!matchState.hasTokensInCategory(pi, token.category)) {
                                setState(() { _playerOverlay[pi] = -1; });
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
                    final undoData = {'name': token.name, 'category': token.category.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};
                    matchState.removeTokenAt(pi, ti);
                    _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                    if (!matchState.hasTokensInCategory(pi, token.category)) {
                      setState(() { _playerOverlay[pi] = -1; });
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
                  setState(() { _playerOverlay[playerIndex] = -1; });
                  return;
                }
              }
              matchState.addToken(playerIndex, ActiveToken(
                name: td.name, category: td.category, destroyTrigger: td.destroyTrigger,
                customImagePath: td.customImagePath,
                health: td.category == TokenCategory.ally ? td.health : null,
                maxHealth: td.category == TokenCategory.ally ? td.health : null,
                turnPlayed: turnCount, playerPlayed: playerIndex, phasePlayed: currentPhase,
              ));
              _log(playerIndex, LogEventType.tokenAdded, '${td.name} added', undoData: {'name': td.name, 'category': td.category.index});
              setState(() { _playerOverlay[playerIndex] = -1; });
            },
            onCustomTokenAdded: (TokenData td) { setState(() { customTokens.add(td); }); },
            onFavoriteToggled: (name, faves) { setState(() { favoriteTokens = faves; }); },
            onClose: () { setState(() { _playerOverlay[playerIndex] = -1; }); },
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

  // --- Player tap halves ---
  Widget _buildPlayerTapHalf({required int index, required int delta, required String label, required Alignment labelAlignment, required EdgeInsets labelPadding, required Border? border}) {
    final settings = context.read<GameSettingsProvider>();
    final double blurSigma = settings.frostedGlass ? 5.0 : 0.0;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final actualDelta = matchState.applyHealthDelta(index, delta);
          if (actualDelta == 0) return;
          _log(index, LogEventType.healthChange, 'Health', value: actualDelta);
          _spawnFloatingNumber(index, actualDelta);
        },
        child: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), border: border),
            child: Align(
              alignment: Alignment(labelAlignment.x, -0.1),
              child: Padding(
                padding: labelPadding,
                child: Stack(
                  children: [
                    Text(label, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, fontFamily: 'Inter', foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = Colors.black)),
                    Text(label, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Colors.black.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }

  // --- Single player panel ---
  Widget _buildPlayerPanel(int index) {
    final settings = context.read<GameSettingsProvider>();
    final double screenWidth = MediaQuery.of(context).size.width;

    return Consumer<MatchState>(
      builder: (context, state, child) {
        final bool isActive = _showTurnTracker && state.activePlayer == index;
        return Container(
          decoration: BoxDecoration(border: Border.all(color: isActive ? Colors.blue : Colors.black, width: 3)),
          child: child,
        );
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final heroId = widget.playerHeroes[index];
                final hero = [...heroLibrary, ..._getCustomHeroes()].cast<HeroData?>().firstWhere(
                  (h) => h?.id == heroId,
                  orElse: () => null,
                );
                if (hero == null) {
                  return Container(color: Colors.grey[900]);
                }
                if (hero.customImagePath != null) {
                  return Image.file(
                    File(hero.customImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
                  );
                }
                return HeroImage(
                  hero: hero,
                  fit: BoxFit.cover,
                  placeholder: Container(color: Colors.grey[900]),
                );
              },
            ),
          ),
          Positioned.fill(
            child: Row(children: [
              _buildPlayerTapHalf(index: index, delta: -1, label: '-', labelAlignment: Alignment.center, labelPadding: EdgeInsets.only(right: 1), border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 0.5))),
              _buildPlayerTapHalf(index: index, delta: 1, label: '+', labelAlignment: Alignment.center, labelPadding: EdgeInsets.only(left: 1), border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 0.5))),
            ]),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, -0.85),
              child: Consumer<MatchState>(
                builder: (context, _, _) => _buildTokenChips(index),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment(0, -0.1),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                // Health number — always centered, never displaced
                Consumer<MatchState>(
                  builder: (context, state, _) {
                    final h = state.healthOf(index);
                    return Stack(
                      children: [
                        // Black outline
                        Text('$h', style: TextStyle(fontSize: 106, fontWeight: FontWeight.w900, fontFamily: 'Inter', foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.black)),
                        // Fill
                        Text('$h', style: TextStyle(fontSize: 106, fontWeight: FontWeight.w900, fontFamily: 'Inter', color: const Color.fromARGB(255, 14, 21, 22))),
                      ],
                    );
                  },
                ),
                // Totals display — negative above-left, positive above-right
                Positioned(
                  top: -1,
                  left: -20,
                  child: _buildTotalsDisplaySide(index, negative: true),
                ),
                Positioned(
                  top: -1,
                  right: -20,
                  child: _buildTotalsDisplaySide(index, negative: false),
                ),
                // Floating numbers — left side (damage)
                Positioned(
                  left: -44,
                  top: 0,
                  child: _buildFloatingNumbersSide(index, negative: true),
                ),
                // Floating numbers — right side (healing)
                Positioned(
                  right: -44,
                  top: 0,
                  child: _buildFloatingNumbersSide(index, negative: false),
                ),
              ] ,
              ),
            )),
          ),
          if (context.read<GameSettingsProvider>().addTokenButtonEnabled)
            Builder(builder: (context) {
              final bool hasPitch = settings.resourceTrackerSetting == 0 || settings.resourceTrackerSetting == 2;
              final double inset = (hasPitch ? _panelInsetWithResource : _panelInsetNoResource) * screenWidth;
              return Positioned(
                left: index == 1 ? null : inset,
                right: index == 1 ? inset : null,
                bottom: 0,
                top: 0,
                child: Align(
                  alignment: Alignment(0, 0.50),
                  child: GestureDetector(
                    onTap: () { setState(() { _playerOverlay[index] = -2; }); },
                    child: Container(
                      width: screenWidth * _panelButtonWidth,
                      height: screenWidth * _panelButtonHeight,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: -10,
                          right: -10,
                          top: -10,
                          bottom: -10,
                          child: Image.asset(
                            AppAssets.addTokenButton,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(color: Colors.black.withValues(alpha: 0.5)),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Icon(Icons.add, size: 28, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            );
            }),
          // Pitch counter on player panel — rendered last so it's on top of tap halves
          if (context.read<GameSettingsProvider>().resourceTrackerSetting == 0 || context.read<GameSettingsProvider>().resourceTrackerSetting == 2)
            Builder(builder: (context) {
              final double inset = (settings.addTokenButtonEnabled ? _panelInsetWithResource : _panelInsetNoResource) * screenWidth;
              return Positioned(
                left: index == 1 ? inset : null,
                right: index == 0 ? inset : null,
                bottom: 0,
                top: 0,
                child: IgnorePointer(
                ignoring: false,
                child: Align(
                  alignment: Alignment(0, 0.50),
                  child: Consumer<MatchState>(
                    builder: (context, _, _) => _buildPitchCounter(index, screenWidth: screenWidth),
                  ),
                ),
              ),
            );
            }),
        ],
      ),
    );
  }

  Widget _buildPlayerWidget(int index) {
    Widget content = _buildPlayerPanel(index);
    final int? qt = _getQuarterTurns(index);
    if (qt != null) content = RotatedBox(quarterTurns: qt, child: content);
    return content;
  }

  Widget _turnTrackerBackground() {
    return Transform.flip(
      child: Image.asset(
        AppAssets.turnTrackerOverlay,
        width: MediaQuery.of(context).size.width * 2,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _turnTrackerContainer({required Widget child}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: child,
    );
  }

  Widget _buildPitchCounter(int playerIndex, {double? screenWidth}) {
  const double iconSize = 20.0;
  const double numSize = 22.0;
  final int pitchValue = matchState.pitchOf(playerIndex);
  Color pitchColor;
  if (pitchValue >= 3) {
    pitchColor = const Color.fromARGB(255, 60, 163, 247);
  } else if (pitchValue == 2) {
    pitchColor = const Color.fromARGB(255, 241, 229, 117);
  } else if (pitchValue == 1) {
    pitchColor = const Color.fromARGB(255, 190, 50, 40);
  } else {
    pitchColor = Colors.white;
  }
  final String pitchIconPath = AppAssets.pitchIconFor(pitchValue);

  // Shadow offsets reproduce the prior 2-Icon/2-Text stack: black layer drawn
  // with no offset behind the colored layer, also with no offset. The original
  // had them perfectly stacked (no offset), so a single shadow at Offset.zero
  // with a small blur reproduces the visible outline.
  final List<Shadow> iconShadows = const [
    Shadow(color: Colors.black, offset: Offset(0, 0), blurRadius: 0),
  ];
  final List<Shadow> numberShadows = [
    Shadow(color: Colors.black, offset: const Offset(-1.5, 0), blurRadius: 0),
    Shadow(color: Colors.black, offset: const Offset(1.5, 0), blurRadius: 0),
    Shadow(color: Colors.black, offset: const Offset(0, -1.5), blurRadius: 0),
    Shadow(color: Colors.black, offset: const Offset(0, 1.5), blurRadius: 0),
  ];

  final double w = screenWidth ?? 390;
  return Container(
    width: w * _CounterScreenState._panelButtonWidth,
    height: w * _CounterScreenState._panelButtonHeight,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Pitch icon background
        Positioned.fill(
          child: Transform.scale(
            scale: 1.3,
            child: Image.asset(
              pitchIconPath,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        ),

        // Dark overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Full-area tap layer: left half decrements, right half increments
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final v = matchState.pitchOf(playerIndex);
                    if (v > 0) matchState.setPitch(playerIndex, v - 1);
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.remove,
                        size: iconSize,
                        color: pitchColor,
                        shadows: iconShadows,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final v = matchState.pitchOf(playerIndex);
                    if (v < 99) matchState.setPitch(playerIndex, v + 1);
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.add,
                        size: iconSize,
                        color: pitchColor,
                        shadows: iconShadows,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Center number — non-interactive, sits on top
        IgnorePointer(
          child: Text(
            '${matchState.pitchOf(playerIndex)}',
            style: TextStyle(
              fontSize: numSize,
              fontWeight: FontWeight.bold,
              color: pitchColor,
              height: 1.0,
              shadows: numberShadows,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTurnTrackerControls() {
    return _buildTurnTrackerPanel();
  }

  // --- Turn tracker ---
  Widget _buildTurnTrackerPanel() {
    final settings = context.read<GameSettingsProvider>();
    final int setting = settings.resourceTrackerSetting;
    final bool showAP = setting == 0 || setting == 1;

    Widget apCounter(int playerIndex) {
      const double iconSize = 20.0;
      const double numSize = 22.0;
      const double labelSize = 10.0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final v = matchState.apOf(playerIndex);
              if (v > 0) matchState.setAP(playerIndex, v - 1);
            },
            child: Icon(Icons.remove, size: iconSize, color: Color(0xFFF5E8C4)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('AP', style: TextStyle(fontSize: labelSize, color: Color(0xFFF5E8C4), height: 1.0, fontFamily: 'CormorantGaramond')),
              Text('${matchState.apOf(playerIndex)}', style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold, color: Color(0xFFF5E8C4), height: 1.0)),
            ]),
          ),
          GestureDetector(
            onTap: () {
              final v = matchState.apOf(playerIndex);
              if (v < 99) matchState.setAP(playerIndex, v + 1);
            },
            child: Icon(Icons.add, size: iconSize, color: Color(0xFFF5E8C4)),
          ),
        ],
      );
    }

    Widget centerContent;
    if (_showTurnTracker) {
      centerContent = RotatedBox(
        quarterTurns: activePlayer == 0 ? 2 : 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.arrow_left, color: Color(0xFFF5E8C4), size: 20), onPressed: _retreatPhase, padding: EdgeInsets.zero, constraints: BoxConstraints()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${widget.playerNames[activePlayer].length > 6 ? '${widget.playerNames[activePlayer].substring(0, 6)}..' : widget.playerNames[activePlayer]}\'s Turn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF5E8C4), height: 1.0)),
                    SizedBox(height: 2),
                    Text(fabPhases[currentPhase], style: TextStyle(fontSize: 11, color: Color(0xFFF5E8C4), height: 1.0)),
                  ]),
                ),
                IconButton(icon: Icon(Icons.arrow_right, color: Color(0xFFF5E8C4), size: 20), onPressed: _advancePhase, padding: EdgeInsets.zero, constraints: BoxConstraints()),
              ],
            ),
          ],
        ),
      );
    } else {
      centerContent = SizedBox.shrink();
    }

    if (!showAP) {
      return _turnTrackerContainer(child: centerContent);
    }

    return _turnTrackerContainer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            RotatedBox(quarterTurns: 2, child: apCounter(0)),
            Expanded(child: centerContent),
            apCounter(1),
          ],
        ),
      ),
    );
  }

  // --- Grid ---
  Widget _buildPlayerGrid() {
    if (_showMiddleBar) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Column(children: [
            Expanded(child: _buildPlayerWidget(0)),
            SizedBox(height: 55),
            Expanded(child: _buildPlayerWidget(1)),
          ]),
          Positioned(
            left: -20,
            right: -20,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Column(
                children: [
                  Spacer(),
                  _turnTrackerBackground(),
                  Spacer(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Column(
              children: [
                Spacer(),
                Consumer<MatchState>(
                  builder: (context, _, _) => _buildTurnTrackerControls(),
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      );
    }
    return Column(children: [
      Expanded(child: _buildPlayerWidget(0)),
      Expanded(child: _buildPlayerWidget(1)),
    ]);
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
          if (settings.clockEnabled) Positioned(top: 35, left: 0, right: 0, child: Center(child: RotatedBox(quarterTurns: 2, child: TimerDisplay(
            secondsRemaining: _timerSecondsRemaining, isRunning: _timerRunning, flashOn: _timerFlashOn, onReset: _resetTimer, onToggle: _timerRunning ? _pauseTimer : _startTimer,
          )))),
          if (settings.clockEnabled) Positioned(bottom: 35, left: 0, right: 0, child: Center(child: TimerDisplay(
            secondsRemaining: _timerSecondsRemaining, isRunning: _timerRunning, flashOn: _timerFlashOn, onReset: _resetTimer, onToggle: _timerRunning ? _pauseTimer : _startTimer,
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
          // Home
          Positioned(top: 40, left: 16, child: Container(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: IconButton(icon: Icon(Icons.home, color: Colors.white), onPressed: () {
            if (gameLog.entries.isNotEmpty) {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text('Leave Game', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text('A game is in progress. Are you sure you want to return to the home screen?', style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 16)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                  TextButton(onPressed: () { _timer?.cancel(); Navigator.pop(ctx); Navigator.popUntil(context, (r) => r.isFirst); }, child: Text('Leave', style: TextStyle(color: Colors.red))),
                ],
              ));
            } else { _timer?.cancel(); Navigator.popUntil(context, (r) => r.isFirst); }
          }),
          )),
          // Reset
          Positioned(top: 40, right: 16, child: Container(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: () {
              showDialog(context: context, builder: (ctx) => AlertDialog(
                title: Text('Reset Game', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Text('Reset all health, tokens, timer, and log?', style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 16)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                  TextButton(onPressed: () { setState(() {
                  matchState.resetAll();
                  _playerOverlay = List.filled(2, -1);
                  _showFirstTurnChooser = true;
                  _showDiceOverlay = false;
                }); _resetTimer(); Navigator.pop(ctx); }, child: Text('Reset', style: TextStyle(color: Colors.red))),
              ]));
            }),
          )),
          // Settings
          Positioned(bottom: 24, right: 16, child: Container(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: IconButton(icon: Icon(Icons.settings, color: Colors.white), onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            }),
          )),
          // Log
          Positioned(bottom: 24, left: 16, child: Container(
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
            child: IconButton(icon: Icon(Icons.list_alt, color: Colors.white), onPressed: () {
              showDialog(context: context, builder: (ctx) => Dialog(insetPadding: EdgeInsets.all(16), child: LogScreen(gameLog: gameLog, onUndo: _undoLastEntry, playerNames: widget.playerNames)));
            }),
          )),
          // First turn chooser
          if (_showFirstTurnChooser && !_showDiceOverlay) Positioned.fill(child: _buildFirstTurnChooser()),
          // Dice overlay
          if (_showDiceOverlay) Positioned.fill(child: DiceOverlay(
            playerNames: widget.playerNames,
            onChoice: (int winner, bool goFirst) {
              _onDiceChoice(winner, goFirst);
            },
          )),
          // Player overlays
          for (int i = 0; i < 2; i++)
            if (_playerOverlay[i] >= 0 && _playerOverlay[i] < TokenCategory.values.length)
              _buildPlayerOverlayPositioned(i, _buildCategoryOverlay(i, TokenCategory.values[_playerOverlay[i]])),
          for (int i = 0; i < 2; i++)
            if (_playerOverlay[i] == -2)
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
  final Set<TokenCategory> selectedCategories = {};
  final searchController = TextEditingController();
  late List<String> currentFavorites;
  final Map<TokenCategory, String> catNames = {TokenCategory.boonAura: 'Buffs', TokenCategory.debuffAura: 'Debuffs', TokenCategory.item: 'Items', TokenCategory.ally: 'Allies'};

  @override
  void initState() { super.initState(); currentFavorites = List.from(widget.favoriteTokens); }
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  List<TokenData> _getFiltered() {
    var tokens = List<TokenData>.from(widget.allTokens);
    if (selectedCategories.isNotEmpty) tokens = tokens.where((t) => selectedCategories.contains(t.category)).toList();
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
            for (var c in [TokenCategory.boonAura, TokenCategory.debuffAura, TokenCategory.item, TokenCategory.ally])
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
                      subtitle: Text(catNames[td.category] ?? '', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
