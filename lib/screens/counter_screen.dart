import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';
import 'settings_screen.dart';
import 'log_screen.dart';
import '../data/token_library.dart';
import '../data/token_preferences.dart';
import '../data/game_log.dart';
import '../data/active_token.dart';
import '../data/armor_slot_state.dart';
import 'widgets/armor_slot_widget.dart';
import 'widgets/timer_display.dart';
import 'widgets/dice_overlay.dart';
import 'dart:ui';
import 'package:wakelock_plus/wakelock_plus.dart';
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
  late List<int> playerHealth;
  late List<List<ActiveToken>> playerTokens;

  int activePlayer = 0;
  int currentPhase = 0;
  int turnCount = 0;

  // Fix #6: Dynamic resource lists sized to playerCount
  late List<int> _playerPitch;
  late List<int> _playerAP;

  // Fix #5: ArmorSlotState instead of magic numbers
  late List<List<ArmorSlotState>> _playerArmor;

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

  final GameLog gameLog = GameLog();

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
    TokenCategory.ally: Colors.orange,
    TokenCategory.boonAura: Colors.lightBlueAccent,
    TokenCategory.debuffAura: Colors.purpleAccent,
    TokenCategory.item: Color(0xFFD2A679),
  };

  bool get _showTurnTracker {
    final settings = context.read<GameSettingsProvider>();
    return settings.turnTrackerEnabled && settings.selectedGame == 'fab';
  }

  bool get _showMiddleBar {
    final settings = context.read<GameSettingsProvider>();
    if (_showTurnTracker) return true;
    return settings.resourceTrackerSetting != 3;
  }

  String? get _currentPhaseName =>
      _showTurnTracker ? fabPhases[currentPhase] : null;

  void _log(int playerIndex, LogEventType type, String description, {int value = 0, Map<String, dynamic>? undoData}) {
    final int minutes = _timerSecondsRemaining ~/ 60;
    final int seconds = _timerSecondsRemaining % 60;
    final String timerStamp = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    gameLog.addEntry(LogEntry(
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

    setState(() {
      switch (entry.type) {
        case LogEventType.healthChange:
          playerHealth[entry.playerIndex] -= entry.value;
          break;
        case LogEventType.tokenAdded:
          if (entry.undoData != null) {
            final name = entry.undoData!['name'] as String;
            final idx = playerTokens[entry.playerIndex].lastIndexWhere((t) => t.name == name);
            if (idx >= 0) playerTokens[entry.playerIndex].removeAt(idx);
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
            final insertIdx = d['index'] as int? ?? playerTokens[entry.playerIndex].length;
            if (insertIdx <= playerTokens[entry.playerIndex].length) {
              playerTokens[entry.playerIndex].insert(insertIdx, token);
            } else {
              playerTokens[entry.playerIndex].add(token);
            }
          }
          break;
        case LogEventType.tokenCountChange:
          if (entry.undoData != null) {
            final name = entry.undoData!['name'] as String;
            for (var t in playerTokens[entry.playerIndex]) {
              if (t.name == name) { t.count -= entry.value; break; }
            }
          }
          break;
        case LogEventType.allyHealthChange:
          if (entry.undoData != null) {
            final name = entry.undoData!['name'] as String;
            for (var t in playerTokens[entry.playerIndex]) {
              if (t.name == name) { t.health = (t.health ?? 0) - entry.value; break; }
            }
          }
          break;
        default:
          break;
      }
      gameLog.entries.removeAt(targetIndex);
    });
  }

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(2, widget.startingLife);
    playerTokens = List.generate(2, (_) => []);
    _playerOverlay = List.filled(2, -1);
    _timerSecondsRemaining = widget.matchTimerMinutes * 60;

    // Fix #6: Size resource lists to actual player count
    _playerPitch = List.filled(2, 0);
    _playerAP = List.filled(2, 0);

    _playerArmor = List.generate(2, (_) =>
      List.generate(4, (_) => ArmorSlotState()),
    );

    _loadTokenPreferences();
    WakelockPlus.enable();
    // First turn chooser shows automatically — no _handleFirstTurn needed
  }

  void _onFirstTurnDirectChoice(int player) {
    setState(() {
      activePlayer = player;
      _playerAP[activePlayer] = 1;
      _showFirstTurnChooser = false;
    });
  }

  void _onDiceChoice(int winner, bool goFirst) {
    setState(() {
      activePlayer = goFirst ? winner : (winner == 0 ? 1 : 0);
      _playerAP[activePlayer] = 1;
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
              child: ElevatedButton(
                onPressed: () => _onFirstTurnDirectChoice(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${widget.playerNames[0]}\n'),
                    TextSpan(text: 'Goes First'),
                  ]),
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Dice button — center
            ElevatedButton(
              onPressed: _showDiceRoll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.casino, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text('Roll Dice', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Player 2 "Go First" — normal orientation
            ElevatedButton(
              onPressed: () => _onFirstTurnDirectChoice(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${widget.playerNames[1]}\n'),
                    TextSpan(text: 'Goes First'),
                  ]),
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
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
    _timerRunning = true;
    _hasExpiredBuzzStarted = false;
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
    setState(() {});
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
    final settings = context.read<GameSettingsProvider>();
    final customs = await TokenPreferences.getCustomTokens(settings.selectedGame);
    final favs = await TokenPreferences.getFavorites(settings.selectedGame);
    setState(() { customTokens = customs; favoriteTokens = favs; });
  }

  int? _getQuarterTurns(int index) {
    return index == 0 ? 2 : null;
  }

  // --- Phase / turn ---
  // Fix #8: Auto-destroy now fires on each phase advance, not just on turn wrap
  void _advancePhase() {
    setState(() {
      if (currentPhase < fabPhases.length - 1) {
        currentPhase++;
        _checkAutoDestroy();
      } else {
        currentPhase = 0;
        _playerPitch[activePlayer] = 0;
        _playerAP[activePlayer] = 0;
        activePlayer = activePlayer == 0 ? 1 : 0;
        _playerAP[activePlayer] = 1;
        turnCount++;
        _checkAutoDestroy();
      }
    });
  }

  void _retreatPhase() { setState(() { if (currentPhase > 0) { currentPhase--; } }); }

  void _checkAutoDestroy() {
    if (!_showTurnTracker) return;
    for (int pi = 0; pi < playerTokens.length; pi++) {
      playerTokens[pi].removeWhere((t) {
        if (t.destroyTrigger == null) return false;
        bool r = t.count <= 0 || _shouldAutoRemove(t, pi);
        if (r) _log(pi, LogEventType.tokenDestroyed, '${t.name} destroyed', undoData: {'name': t.name, 'category': t.category.index, 'destroyTrigger': t.destroyTrigger?.index, 'count': t.count, 'health': t.health, 'maxHealth': t.maxHealth, 'turnPlayed': t.turnPlayed, 'playerPlayed': t.playerPlayed});
        return r;
      });
    }
  }

  bool _shouldAutoRemove(ActiveToken t, int pi) {
    // Phase indices: 0=Start, 1=Action, 2=End
    switch (t.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn:
        // Destroy at the END of the start phase on your next turn (so you see it activate first)
        if (pi != activePlayer) return false;
        if (turnCount > t.turnPlayed && currentPhase >= 1) return true;
        return false;
      case DestroyTrigger.startOfOpponentTurn:
        if (pi == activePlayer) return false;
        if (turnCount > t.turnPlayed && currentPhase >= 1) return true;
        return false;
      case DestroyTrigger.beginningOfActionPhase:
        if (pi != activePlayer) return false;
        if (turnCount > t.turnPlayed && currentPhase >= 1) return true;
        if (turnCount == t.turnPlayed && t.phasePlayed < 1 && currentPhase >= 1) return true;
        return false;
      case DestroyTrigger.beginningOfEndPhase:
        if (pi != activePlayer) return false;
        if (turnCount > t.turnPlayed && currentPhase >= 2) return true;
        if (turnCount == t.turnPlayed && t.phasePlayed < 2 && currentPhase >= 2) return true;
        return false;
    }
  }

  bool _isTokenTriggering(ActiveToken t, int pi) {
    if (!_showTurnTracker || t.destroyTrigger == null) return false;
    // Phase indices: 0=Start, 1=Action, 2=End
    bool isAct = pi == activePlayer;
    switch (t.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn:
        // Highlight during Start Phase on next turn
        return isAct && turnCount > t.turnPlayed && currentPhase == 0;
      case DestroyTrigger.startOfOpponentTurn:
        return !isAct && turnCount > t.turnPlayed && currentPhase == 0;
      case DestroyTrigger.beginningOfActionPhase:
        if (!isAct) return false;
        if (turnCount > t.turnPlayed && currentPhase == 1) return true;
        if (turnCount == t.turnPlayed && t.phasePlayed < 1 && currentPhase == 1) return true;
        return false;
      case DestroyTrigger.beginningOfEndPhase:
        if (!isAct) return false;
        if (turnCount > t.turnPlayed && currentPhase == 2) return true;
        if (turnCount == t.turnPlayed && t.phasePlayed < 2 && currentPhase == 2) return true;
        return false;
    }
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
        decoration: BoxDecoration(
          color: _categoryColors[cat]!.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(4),
          border: hasTriggering
              ? Border.all(color: Colors.amber, width: 2)
              : Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasTriggering) Icon(Icons.flash_on, size: 14, color: Colors.amber),
            Text(_categoryNames[cat] ?? '', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text('$count', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
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
    final tokens = <int>[];
    for (int i = 0; i < playerTokens[playerIndex].length; i++) {
      if (playerTokens[playerIndex][i].category == cat) tokens.add(i);
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
          child: Column(
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
                          _buildTokenTile(playerTokens[playerIndex][ti], playerIndex, ti, MediaQuery.of(context).size.width * 0.8),
                      ],
                    ),
                  ),
                ),
            ],
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
                height: 26,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    token.name,
                    style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'CormorantGaramond'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
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
                      child: _TokenArtBackground(tokenName: token.name),
                    ),
                    // Dark overlay for readability
                    Positioned.fill(
                      child: Container(color: Colors.black.withValues(alpha: 0.3)),
                    ),
                    // Controls
                    Row(
                  children: [
                    // Left half: subtract
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () { setState(() {
                          if (isAlly) {
                            final int newHealth = token.health! - 1;
                            if (newHealth <= 0) {
                              final undoData = {'name': token.name, 'category': token.category.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'phasePlayed': token.phasePlayed, 'index': ti};
                              playerTokens[pi].removeAt(ti);
                              _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                              if (playerTokens[pi].where((t) => t.category == token.category).isEmpty) _playerOverlay[pi] = -1;
                            } else {
                              token.health = newHealth;
                              _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: -1, undoData: {'name': token.name});
                            }
                          } else {
                            token.count--;
                            _log(pi, LogEventType.tokenCountChange, token.name, value: -1, undoData: {'name': token.name, 'category': token.category.index});
                            if (token.count <= 0) {
                              final undoData = {'name': token.name, 'category': token.category.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': 0, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'index': ti};
                              playerTokens[pi].removeAt(ti);
                              _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                              if (playerTokens[pi].where((t) => t.category == token.category).isEmpty) _playerOverlay[pi] = -1;
                            }
                          }
                        }); },
                        child: Center(child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.7)))),
                      ),
                    ),
                    // Center: count/health
                    Text(
                      '$displayValue',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    // Right half: add
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () { setState(() {
                          if (isAlly) {
                            if (token.health! < 99) {
                              token.health = token.health! + 1;
                              _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: 1, undoData: {'name': token.name});
                            }
                          } else {
                            if (token.count < 99) {
                              token.count++;
                              _log(pi, LogEventType.tokenCountChange, token.name, value: 1, undoData: {'name': token.name, 'category': token.category.index});
                            }
                          }
                        }); },
                        child: Center(child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.7)))),
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
                  onTap: () { setState(() {
                    final undoData = {'name': token.name, 'category': token.category.index, 'destroyTrigger': token.destroyTrigger?.index, 'count': token.count, 'health': token.health, 'maxHealth': token.maxHealth, 'turnPlayed': token.turnPlayed, 'playerPlayed': token.playerPlayed, 'index': ti};
                    playerTokens[pi].removeAt(ti);
                    _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed', undoData: undoData);
                    if (playerTokens[pi].where((t) => t.category == token.category).isEmpty) _playerOverlay[pi] = -1;
                  }); },
                  child: Padding(
                    padding: EdgeInsets.only(top: 2, right: 2),
                    child: Icon(Icons.delete_outline, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  // --- Add token picker overlay ---
  Widget _buildAddTokenOverlay(int playerIndex) {
    final settings = context.read<GameSettingsProvider>();
    final List<TokenData> allTokens = [...(tokenLibrary[settings.selectedGame] ?? []), ...customTokens];

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
            gameId: settings.selectedGame,
            onTokenAdded: (TokenData td) {
              setState(() {
                if (td.destroyTrigger != null && td.category != TokenCategory.ally) {
                  final existingIdx = playerTokens[playerIndex].indexWhere((t) =>
                    t.name == td.name && !_isTokenTriggering(t, playerIndex));
                  if (existingIdx >= 0) {
                    playerTokens[playerIndex][existingIdx].count++;
                    _log(playerIndex, LogEventType.tokenCountChange, td.name, value: 1, undoData: {'name': td.name, 'category': td.category.index});
                    _playerOverlay[playerIndex] = -1;
                    return;
                  }
                }
                playerTokens[playerIndex].add(ActiveToken(
                  name: td.name, category: td.category, destroyTrigger: td.destroyTrigger,
                  health: td.category == TokenCategory.ally ? td.health : null,
                  maxHealth: td.category == TokenCategory.ally ? td.health : null,
                  turnPlayed: turnCount, playerPlayed: playerIndex, phasePlayed: currentPhase,
                ));
                _log(playerIndex, LogEventType.tokenAdded, '${td.name} added', undoData: {'name': td.name, 'category': td.category.index});
                _playerOverlay[playerIndex] = -1;
              });
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
          final newHealth = (playerHealth[index] + delta).clamp(-99, 99);
          if (newHealth == playerHealth[index]) return;
          final actualDelta = newHealth - playerHealth[index];
          setState(() { playerHealth[index] = newHealth; _log(index, LogEventType.healthChange, 'Health', value: actualDelta); });
          _spawnFloatingNumber(index, actualDelta);
        },
        child: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), border: border),
            child: Align(
              alignment: Alignment(labelAlignment.x, -0.1),
              child: Padding(
                padding: labelPadding,
                child: Text(label, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w500, fontFamily: 'Inter', color: Colors.black.withValues(alpha: 0.85))),
              ),
            ),
          ),
        )),
      ),
    );
  }

  // --- Single player panel ---
  Widget _buildPlayerPanel(int index) {
    final bool isActive = _showTurnTracker && activePlayer == index;

    return Container(
      decoration: isActive ? BoxDecoration(border: Border.all(color: Colors.blue, width: 3)) : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final heroId = widget.playerHeroes[index];
                final hero = heroLibrary.cast<HeroData?>().firstWhere(
                  (h) => h?.id == heroId,
                  orElse: () => null,
                );
                if (hero == null) {
                  return Container(color: Colors.grey[900]);
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
            child: Align(alignment: Alignment(0, -.955), child: _buildTokenChips(index)),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, -0.1),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                // Health number — always centered, never displaced
                Text('${playerHealth[index]}', style: TextStyle(fontSize: 106, fontWeight: FontWeight.w900, fontFamily: 'Inter', color: const Color.fromARGB(255, 14, 21, 22))),
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
              ],
            ),
          )),
          if (context.read<GameSettingsProvider>().addTokenButtonEnabled)
            Positioned.fill(
              child: Align(
                alignment: Alignment(0, 0.60),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () { setState(() { _playerOverlay[index] = -2; }); },
                  child: Padding(padding: EdgeInsets.all(12), child: Icon(Icons.add_box, size: 36, color: Colors.black)),
                ),
              ),
            ),
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

  // --- Turn tracker ---
  Widget _buildTurnTrackerPanel() {
    final settings = context.read<GameSettingsProvider>();
    final int setting = settings.resourceTrackerSetting;
    final bool showPitch = setting == 0 || setting == 2;
    final bool showAP = setting == 0 || setting == 1;
    final bool bothVisible = showPitch && showAP;
    final bool singleVisible = (showPitch || showAP) && !bothVisible;

    Widget pitchCounter(int playerIndex, {bool large = false}) {
      final double iconSize = large ? 20.0 : 16.0;
      final double numSize = large ? 22.0 : 16.0;
      final double labelSize = large ? 10.0 : 8.0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () { if (_playerPitch[playerIndex] > 0) setState(() { _playerPitch[playerIndex]--; }); },
            child: Icon(Icons.remove, size: iconSize, color: Colors.black54),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Pitch', style: TextStyle(fontSize: labelSize, color: Colors.black54, height: 1.0, fontFamily: 'CormorantGaramond')),
              Text('${_playerPitch[playerIndex]}', style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold, color: Colors.black, height: 1.0)),
            ]),
          ),
          GestureDetector(
            onTap: () { if (_playerPitch[playerIndex] < 99) setState(() { _playerPitch[playerIndex]++; }); },
            child: Icon(Icons.add, size: iconSize, color: Colors.black54),
          ),
        ],
      );
    }

    Widget apCounter(int playerIndex, {bool large = false}) {
      final double iconSize = large ? 20.0 : 16.0;
      final double numSize = large ? 22.0 : 16.0;
      final double labelSize = large ? 10.0 : 8.0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () { if (_playerAP[playerIndex] > 0) setState(() { _playerAP[playerIndex]--; }); },
            child: Icon(Icons.remove, size: iconSize, color: Colors.black54),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('AP', style: TextStyle(fontSize: labelSize, color: Colors.black54, height: 1.0, fontFamily: 'CormorantGaramond')),
              Text('${_playerAP[playerIndex]}', style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold, color: Colors.black, height: 1.0)),
            ]),
          ),
          GestureDetector(
            onTap: () { if (_playerAP[playerIndex] < 99) setState(() { _playerAP[playerIndex]++; }); },
            child: Icon(Icons.add, size: iconSize, color: Colors.black54),
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
                IconButton(icon: Icon(Icons.arrow_left, color: Colors.black, size: 20), onPressed: _retreatPhase, padding: EdgeInsets.zero, constraints: BoxConstraints()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${widget.playerNames[activePlayer].length > 8 ? '${widget.playerNames[activePlayer].substring(0, 8)}..' : widget.playerNames[activePlayer]}\'s Turn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, height: 1.0)),
                    SizedBox(height: 2),
                    Text(fabPhases[currentPhase], style: TextStyle(fontSize: 14, color: Colors.black, height: 1.0)),
                  ]),
                ),
                IconButton(icon: Icon(Icons.arrow_right, color: Colors.black, size: 20), onPressed: _advancePhase, padding: EdgeInsets.zero, constraints: BoxConstraints()),
              ],
            ),
          ],
        ),
      );
    } else {
      centerContent = SizedBox.shrink();
    }

    if (!showPitch && !showAP) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: centerContent,
      );
    }

    if (bothVisible) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              RotatedBox(quarterTurns: 2, child: pitchCounter(0)),
              SizedBox(height: 4),
              pitchCounter(1),
            ]),
            Expanded(child: centerContent),
            Column(mainAxisSize: MainAxisSize.min, children: [
              RotatedBox(quarterTurns: 2, child: apCounter(0)),
              SizedBox(height: 4),
              apCounter(1),
            ]),
          ],
        ),
      );
    }

    if (singleVisible) {
      Widget Function(int, {bool large}) counter = showAP ? apCounter : pitchCounter;
      return Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            RotatedBox(quarterTurns: 2, child: counter(0, large: true)),
            Expanded(child: centerContent),
            counter(1, large: true),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  // --- Grid ---
  Widget _buildPlayerGrid() {
    if (_showMiddleBar) {
      return Column(children: [
        Expanded(child: _buildPlayerWidget(0)),
        _buildTurnTrackerPanel(),
        Expanded(child: _buildPlayerWidget(1)),
      ]);
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

    return PopScope(
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
              child: RotatedBox(quarterTurns: 2, child: Column(mainAxisSize: MainAxisSize.min, children: [
                ArmorSlotWidget(state: _playerArmor[0][0], slotIndex: 0, onIncrement: () { setState(() { _playerArmor[0][0].increment(); }); }, onDecrement: () { setState(() { _playerArmor[0][0].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[0][0].destroy(); }); }),
                ArmorSlotWidget(state: _playerArmor[0][1], slotIndex: 1, onIncrement: () { setState(() { _playerArmor[0][1].increment(); }); }, onDecrement: () { setState(() { _playerArmor[0][1].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[0][1].destroy(); }); }),
              ])),
            ),
          if (settings.armorTrackingEnabled)
            Positioned(
              top: 90, right: 8,
              child: RotatedBox(quarterTurns: 2, child: Column(mainAxisSize: MainAxisSize.min, children: [
                ArmorSlotWidget(state: _playerArmor[0][2], slotIndex: 2, onIncrement: () { setState(() { _playerArmor[0][2].increment(); }); }, onDecrement: () { setState(() { _playerArmor[0][2].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[0][2].destroy(); }); }),
                ArmorSlotWidget(state: _playerArmor[0][3], slotIndex: 3, onIncrement: () { setState(() { _playerArmor[0][3].increment(); }); }, onDecrement: () { setState(() { _playerArmor[0][3].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[0][3].destroy(); }); }),
              ])),
            ),
          // Player 2 armor
          if (settings.armorTrackingEnabled)
            Positioned(
              bottom: 90, left: 8,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ArmorSlotWidget(state: _playerArmor[1][0], slotIndex: 0, onIncrement: () { setState(() { _playerArmor[1][0].increment(); }); }, onDecrement: () { setState(() { _playerArmor[1][0].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[1][0].destroy(); }); }),
                ArmorSlotWidget(state: _playerArmor[1][1], slotIndex: 1, onIncrement: () { setState(() { _playerArmor[1][1].increment(); }); }, onDecrement: () { setState(() { _playerArmor[1][1].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[1][1].destroy(); }); }),
              ]),
            ),
          if (settings.armorTrackingEnabled)
            Positioned(
              bottom: 90, right: 8,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ArmorSlotWidget(state: _playerArmor[1][2], slotIndex: 2, onIncrement: () { setState(() { _playerArmor[1][2].increment(); }); }, onDecrement: () { setState(() { _playerArmor[1][2].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[1][2].destroy(); }); }),
                ArmorSlotWidget(state: _playerArmor[1][3], slotIndex: 3, onIncrement: () { setState(() { _playerArmor[1][3].increment(); }); }, onDecrement: () { setState(() { _playerArmor[1][3].decrement(); }); }, onDestroy: () { setState(() { _playerArmor[1][3].destroy(); }); }),
              ]),
            ),
          // Home
          Positioned(top: 40, left: 16, child: IconButton(icon: Icon(Icons.home, color: Colors.white), onPressed: () {
            if (gameLog.entries.isNotEmpty) {
              showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Leave Game'), content: Text('A game is in progress. Are you sure you want to return to the home screen?'), actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                TextButton(onPressed: () { _timer?.cancel(); Navigator.pop(ctx); Navigator.popUntil(context, (r) => r.isFirst); }, child: Text('Leave', style: TextStyle(color: Colors.red))),
              ]));
            } else { _timer?.cancel(); Navigator.popUntil(context, (r) => r.isFirst); }
          })),
          // Reset
          Positioned(top: 40, right: 16, child: IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: () {
            showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('Reset Game'), content: Text('Reset all health, tokens, timer, and log?'), actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
              TextButton(onPressed: () { setState(() {
                playerHealth = List.filled(2, widget.startingLife);
                playerTokens = List.generate(2, (_) => []);
                _playerOverlay = List.filled(2, -1);
                activePlayer = 0; currentPhase = 0; turnCount = 0;
                _playerPitch = List.filled(2, 0);
                _playerAP = List.filled(2, 0);
                _playerArmor = List.generate(2, (_) => List.generate(4, (_) => ArmorSlotState()));
                gameLog.clear();
                _showFirstTurnChooser = true;
                _showDiceOverlay = false;
              }); _resetTimer(); Navigator.pop(ctx); }, child: Text('Reset', style: TextStyle(color: Colors.red))),
            ]));
          })),
          // Settings
          Positioned(bottom: 24, right: 16, child: IconButton(icon: Icon(Icons.settings, color: Colors.white), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          })),
          // Log
          Positioned(bottom: 24, left: 16, child: IconButton(icon: Icon(Icons.list_alt, color: Colors.white), onPressed: () {
            showDialog(context: context, builder: (ctx) => Dialog(insetPadding: EdgeInsets.all(16), child: LogScreen(gameLog: gameLog, onUndo: _undoLastEntry, playerNames: widget.playerNames)));
          })),
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
    );
  }
}

class _TokenArtBackground extends StatelessWidget {
  final String tokenName;

  const _TokenArtBackground({required this.tokenName});

  String _getTokenId(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final id = _getTokenId(tokenName);
    final path = 'assets/images/tokens/${id}_token.jpg';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Crop values for token card art region
        const double cropLeft = 0.10;
        const double cropTop = 0.18;
        const double cropRight = 0.90;
        const double cropBottom = 0.48;
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
  final String gameId;
  final Function(TokenData) onTokenAdded;
  final Function(TokenData) onCustomTokenAdded;
  final Function(String, List<String>) onFavoriteToggled;
  final VoidCallback onClose;

  const _InlineTokenPicker({required this.allTokens, required this.favoriteTokens, required this.playerTokens, required this.gameId, required this.onTokenAdded, required this.onCustomTokenAdded, required this.onFavoriteToggled, required this.onClose});

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
              Padding(padding: EdgeInsets.only(right: 4), child: FilterChip(label: Text(catNames[c] ?? '', style: TextStyle(fontSize: 11)), selected: selectedCategories.contains(c), showCheckmark: false, onSelected: (_) { setState(() { selectedCategories.contains(c) ? selectedCategories.remove(c) : selectedCategories.add(c); }); }, visualDensity: VisualDensity.compact)),
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
                          await TokenPreferences.toggleFavorite(widget.gameId, td.name);
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
