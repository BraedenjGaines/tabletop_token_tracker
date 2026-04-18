import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'settings_screen.dart';
import 'log_screen.dart';
import '../data/token_library.dart';
import '../data/token_preferences.dart';
import '../data/game_log.dart';
import 'dart:ui';

class ActiveToken {
  final String name;
  final TokenCategory category;
  final DestroyTrigger? destroyTrigger;
  int count;
  int? health;
  int? maxHealth;
  int turnPlayed;
  int playerPlayed;

  ActiveToken({
    required this.name,
    required this.category,
    this.destroyTrigger,
    this.count = 1,
    this.health,
    this.maxHealth,
    this.turnPlayed = 0,
    this.playerPlayed = 0,
  });
}

class CounterScreen extends StatefulWidget {
  final int playerCount;
  final int startingLife;
  final List<String> playerHeroes;
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
  final int firstTurnSetting;
  final Function(int) onFirstTurnSettingChanged;
  final int resourceTrackerSetting;
  final Function(int) onResourceTrackerChanged;

  const CounterScreen({
    super.key,
    required this.playerCount,
    required this.startingLife,
    required this.playerHeroes,
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
    required this.firstTurnSetting,
    required this.onFirstTurnSettingChanged,
    required this.resourceTrackerSetting,
    required this.onResourceTrackerChanged,
  });

  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late List<int> playerHealth;
  late List<List<ActiveToken>> playerTokens;
  late String currentFont;
  late bool turnTrackerEnabled;
  late bool frostedGlass;
  late int resourceTrackerSetting;

  int activePlayer = 0;
  int currentPhase = 0;
  int turnCount = 0;

  List<int> _playerPitch = [0, 0];
  List<int> _playerAP = [0, 0];

  List<TokenData> customTokens = [];
  List<String> favoriteTokens = [];

  final GameLog gameLog = GameLog();

  // Match timer
  late int _timerSecondsRemaining;
  Timer? _timer;
  bool _timerRunning = false;

  // Dice roll overlay
  bool _showDiceOverlay = false;
  bool _diceRolling = false;
  bool _diceFinished = false;
  bool _showChoicePrompt = false;
  List<int> _p1Dice = [1, 1];
  List<int> _p2Dice = [1, 1];
  int _diceWinner = 0;
  Timer? _diceTimer;
  final _random = Random();

  // Per-player overlay state: -1 = none, -2 = add token picker, 0-3 = category index
  List<int> _playerOverlay = [];

  final List<String> fabPhases = ['Start Phase', 'Draw Phase', 'Action Phase', 'End Phase'];

  final Map<TokenCategory, String> _categoryNames = {
    TokenCategory.ally: 'Allies',
    TokenCategory.item: 'Items',
    TokenCategory.boonAura: 'Boons',
    TokenCategory.debuffAura: 'Debuffs',
  };

  final Map<TokenCategory, Color> _categoryColors = {
    TokenCategory.ally: Colors.orange,
    TokenCategory.boonAura: Colors.green,
    TokenCategory.debuffAura: Colors.red,
    TokenCategory.item: Colors.blue,
  };

  bool get _showTurnTracker =>
      turnTrackerEnabled && widget.selectedGame == 'fab' && widget.playerCount == 2;

  String? get _currentPhaseName =>
      _showTurnTracker ? fabPhases[currentPhase] : null;

  void _log(int playerIndex, LogEventType type, String description, {int value = 0}) {
    final int minutes = _timerSecondsRemaining ~/ 60;
    final int seconds = _timerSecondsRemaining % 60;
    final String timerStamp = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    gameLog.addEntry(LogEntry(
      playerIndex: playerIndex, type: type, description: description,
      value: value, timestamp: timerStamp,
      turn: _showTurnTracker ? turnCount : null, phase: _currentPhaseName,
    ));
  }

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(widget.playerCount, widget.startingLife);
    playerTokens = List.generate(widget.playerCount, (_) => []);
    _playerOverlay = List.filled(widget.playerCount, -1);
    currentFont = widget.selectedFont;
    turnTrackerEnabled = widget.turnTrackerEnabled;
    frostedGlass = widget.frostedGlass;
    resourceTrackerSetting = widget.resourceTrackerSetting;
    _timerSecondsRemaining = widget.matchTimerMinutes * 60;
    _loadTokenPreferences();
    _handleFirstTurn();
    _playerAP[activePlayer] = 1;
  }

  void _handleFirstTurn() {
    if (widget.playerCount != 2) return;
    switch (widget.firstTurnSetting) {
      case 0: activePlayer = 0; break;
      case 1: activePlayer = 1; break;
      case 2:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() { _showDiceOverlay = true; });
          _startDiceRoll();
        });
        break;
    }
  }

  void _startDiceRoll() {
    setState(() { _diceRolling = true; _diceFinished = false; _showChoicePrompt = false; });
    int tickCount = 0;
    _diceTimer = Timer.periodic(Duration(milliseconds: 80), (timer) {
      setState(() {
        _p1Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
        _p2Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
      });
      tickCount++;
      if (tickCount >= 25) { timer.cancel(); _finalizeDiceRoll(); }
    });
  }

  void _finalizeDiceRoll() {
    int p1Total, p2Total;
    do {
      _p1Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
      _p2Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
      p1Total = _p1Dice[0] + _p1Dice[1];
      p2Total = _p2Dice[0] + _p2Dice[1];
    } while (p1Total == p2Total);
    setState(() { _diceRolling = false; _diceFinished = true; _diceWinner = p1Total > p2Total ? 0 : 1; });
    Future.delayed(Duration(milliseconds: 800), () { if (mounted) setState(() { _showChoicePrompt = true; }); });
  }

  void _onFirstTurnChoice(bool goFirst) {
    setState(() {
      activePlayer = goFirst ? _diceWinner : (_diceWinner == 0 ? 1 : 0);
      _playerAP[activePlayer] = 1;
      _showDiceOverlay = false; _showChoicePrompt = false; _diceFinished = false;
    });
  }

  IconData _dieIcon(int value) {
    switch (value) {
      case 1: return Icons.looks_one; case 2: return Icons.looks_two; case 3: return Icons.looks_3;
      case 4: return Icons.looks_4; case 5: return Icons.looks_5; case 6: return Icons.looks_6;
      default: return Icons.casino;
    }
  }

  @override
  void dispose() { _timer?.cancel(); _diceTimer?.cancel(); super.dispose(); }

  // --- Timer ---
  void _startTimer() {
    if (_timerRunning || _timerSecondsRemaining <= 0) return;
    _timerRunning = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() { if (_timerSecondsRemaining > 0) _timerSecondsRemaining--; else { _timer?.cancel(); _timerRunning = false; } });
    });
    setState(() {});
  }
  void _pauseTimer() { _timer?.cancel(); setState(() { _timerRunning = false; }); }
  void _resetTimer() { _timer?.cancel(); setState(() { _timerRunning = false; _timerSecondsRemaining = widget.matchTimerMinutes * 60; }); }
  String _formatTimer() {
    final m = _timerSecondsRemaining ~/ 60; final s = _timerSecondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  Color _timerColor() {
    if (_timerSecondsRemaining <= 0) return Colors.red;
    if (_timerSecondsRemaining <= 300) return Colors.orange;
    return Colors.white;
  }

  // --- Token prefs ---
  Future<void> _loadTokenPreferences() async {
    final customs = await TokenPreferences.getCustomTokensFull(widget.selectedGame);
    final favs = await TokenPreferences.getFavorites(widget.selectedGame);
    setState(() { customTokens = customs; favoriteTokens = favs; });
  }

  // --- Layout helpers ---
  bool _isMiddleRow(int pi) {
    final rc = (playerHealth.length + 1) ~/ 2;
    if (rc < 3) return false;
    return (pi ~/ 2) == (rc ~/ 2);
  }

  int? _getQuarterTurns(int index) {
    if (playerHealth.length == 2) return index == 0 ? 2 : null;
    final rc = (playerHealth.length + 1) ~/ 2;
    final cr = index ~/ 2;
    final isMiddle = _isMiddleRow(index);
    final isTop = cr < (rc / 2).floor() && !isMiddle;
    if (isTop) return 2;
    if (isMiddle) return (index % 2 == 0) ? 1 : 3;
    return null;
  }

  // --- Phase / turn ---
  void _advancePhase() {
    setState(() {
      if (currentPhase < fabPhases.length - 1) { currentPhase++; _logNewlyTriggering(); _log(activePlayer, LogEventType.phaseChange, fabPhases[currentPhase]); }
      else {
        _checkAutoDestroy();
        currentPhase = 0;
        // Reset outgoing player's resources
        _playerPitch[activePlayer] = 0;
        _playerAP[activePlayer] = 0;
        // Switch player
        activePlayer = activePlayer == 0 ? 1 : 0;
        // New player starts with 1 AP
        _playerAP[activePlayer] = 1;
        turnCount++;
        _logNewlyTriggering();
        _log(activePlayer, LogEventType.phaseChange, 'Turn ${turnCount + 1} - ${fabPhases[currentPhase]}');
      }
    });
  }
  void _logNewlyTriggering() { for (int pi = 0; pi < playerTokens.length; pi++) for (var t in playerTokens[pi]) if (_isTokenTriggering(t, pi)) _log(pi, LogEventType.tokenActivated, '${t.name} active'); }
  void _retreatPhase() { setState(() { if (currentPhase > 0) { currentPhase--; _log(activePlayer, LogEventType.phaseChange, 'Back to ${fabPhases[currentPhase]}'); } }); }

  void _checkAutoDestroy() {
    if (!_showTurnTracker) return;
    for (int pi = 0; pi < playerTokens.length; pi++) {
      playerTokens[pi].removeWhere((t) {
        if (t.destroyTrigger == null) return false;
        bool r = t.count <= 0 || _shouldAutoRemove(t, pi);
        if (r) _log(pi, LogEventType.tokenDestroyed, '${t.name} destroyed');
        return r;
      });
    }
  }

  bool _shouldAutoRemove(ActiveToken t, int pi) {
    switch (t.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn: return pi == activePlayer && turnCount > t.turnPlayed;
      case DestroyTrigger.startOfOpponentTurn: return pi != activePlayer && turnCount > t.turnPlayed;
      case DestroyTrigger.beginningOfActionPhase: return pi == activePlayer && turnCount > t.turnPlayed;
      case DestroyTrigger.beginningOfEndPhase: return pi == activePlayer && turnCount > t.turnPlayed;
    }
  }

  bool _isTokenTriggering(ActiveToken t, int pi) {
    if (!_showTurnTracker || t.destroyTrigger == null) return false;
    bool isAct = pi == activePlayer;
    switch (t.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn: return isAct && turnCount > t.turnPlayed && currentPhase >= 0;
      case DestroyTrigger.startOfOpponentTurn: return !isAct && turnCount > t.turnPlayed && currentPhase >= 0;
      case DestroyTrigger.beginningOfActionPhase: return isAct && turnCount >= t.turnPlayed && currentPhase >= 2;
      case DestroyTrigger.beginningOfEndPhase: return isAct && currentPhase >= 3;
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
          color: _categoryColors[cat]!.withOpacity(0.75),
          borderRadius: BorderRadius.circular(4),
          border: hasTriggering
              ? Border.all(color: Colors.amber, width: 2)
              : Border.all(color: Colors.black.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasTriggering)
              Icon(Icons.flash_on, size: 14, color: Colors.amber),
            Text(
              _categoryNames[cat] ?? '',
              style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenChips(int playerIndex) {
    final byCategory = _getTokensByCategory(playerIndex);

    final List<TokenCategory> order = [
      TokenCategory.boonAura,
      TokenCategory.ally,
      TokenCategory.item,
      TokenCategory.debuffAura,
    ];

    final active = order.where((cat) => byCategory.containsKey(cat)).toList();
    if (active.isEmpty) return SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth * 0.9;
        final double chipWidth = totalWidth / 4;
        final double chipHeight = chipWidth * 1.4;

        return SizedBox(
          height: chipHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var cat in order)
                if (byCategory.containsKey(cat))
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: _buildCategoryChip(cat, byCategory[cat]!.length, playerIndex, chipWidth, chipHeight),
                  )
                else
                  SizedBox(width: chipWidth + 4),
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
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_categoryNames[cat] ?? '', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  GestureDetector(
                    onTap: () { setState(() { _playerOverlay[playerIndex] = -1; }); },
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (tokens.isEmpty)
                Padding(padding: EdgeInsets.all(16), child: Text('No ${_categoryNames[cat]?.toLowerCase()} in play', style: TextStyle(color: Colors.grey)))
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (int ti in tokens)
                        _buildTokenManageRow(playerTokens[playerIndex][ti], playerIndex, ti),
                    ],
                  ),
                ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () { setState(() { _playerOverlay[playerIndex] = -2; }); },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: _categoryColors[cat], borderRadius: BorderRadius.circular(8)),
                  child: Text('+ Add ${_categoryNames[cat]}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenManageRow(ActiveToken token, int pi, int ti) {
    final bool triggering = _isTokenTriggering(token, pi);
    final bool isAlly = token.category == TokenCategory.ally;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _categoryColors[token.category]!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: triggering ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Row(
        children: [
          if (triggering) Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.flash_on, size: 14, color: Colors.amber)),
          Expanded(child: Text(token.name, style: TextStyle(fontSize: 13, color: Colors.white))),
          if (isAlly) ...[
            GestureDetector(
              onTap: () { setState(() { token.health = token.health! - 1; _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: -1); if (token.health! <= 0) { playerTokens[pi].removeAt(ti); _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed'); _playerOverlay[pi] = -1; } }); },
              child: Icon(Icons.remove_circle, size: 18, color: Colors.red),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('${token.health}/${token.maxHealth}', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
            GestureDetector(
              onTap: () { setState(() { token.health = token.health! + 1; _log(pi, LogEventType.allyHealthChange, '${token.name} health', value: 1); }); },
              child: Icon(Icons.add_circle, size: 18, color: Colors.green),
            ),
          ] else ...[
            GestureDetector(
              onTap: () { setState(() { token.count--; _log(pi, LogEventType.tokenCountChange, token.name, value: -1); if (token.count <= 0) { playerTokens[pi].removeAt(ti); _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed'); _playerOverlay[pi] = -1; } }); },
              child: Icon(Icons.remove_circle, size: 18, color: Colors.red),
            ),
            Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('${token.count}', style: TextStyle(fontSize: 13, color: Colors.white))),
            GestureDetector(
              onTap: () { setState(() { token.count++; _log(pi, LogEventType.tokenCountChange, token.name, value: 1); }); },
              child: Icon(Icons.add_circle, size: 18, color: Colors.green),
            ),
          ],
          SizedBox(width: 6),
          GestureDetector(
            onTap: () { setState(() { playerTokens[pi].removeAt(ti); _log(pi, LogEventType.tokenDestroyed, '${token.name} destroyed'); if (playerTokens[pi].where((t) => t.category == token.category).isEmpty) _playerOverlay[pi] = -1; }); },
            child: Icon(Icons.delete, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- Add token picker overlay ---
  Widget _buildAddTokenOverlay(int playerIndex) {
    final List<TokenData> allTokens = [...(tokenLibrary[widget.selectedGame] ?? []), ...customTokens];

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(maxHeight: 350),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: _InlineTokenPicker(
            allTokens: allTokens,
            favoriteTokens: favoriteTokens,
            playerTokens: playerTokens[playerIndex],
            gameId: widget.selectedGame,
            onTokenAdded: (TokenData td) {
              setState(() {
                playerTokens[playerIndex].add(ActiveToken(
                  name: td.name, category: td.category, destroyTrigger: td.destroyTrigger,
                  health: td.category == TokenCategory.ally ? td.health : null,
                  maxHealth: td.category == TokenCategory.ally ? td.health : null,
                  turnPlayed: turnCount, playerPlayed: playerIndex,
                ));
                _log(playerIndex, LogEventType.tokenAdded, '${td.name} added');
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
    if (playerHealth.length == 2) {
      final double halfHeight = MediaQuery.of(context).size.height / 2;
      final int? qt = _getQuarterTurns(index);
      return Positioned(
        top: index == 0 ? 0 : halfHeight,
        left: 0,
        right: 0,
        height: halfHeight,
        child: qt != null ? RotatedBox(quarterTurns: qt, child: overlay) : overlay,
      );
    }
    // For 3+ players, fall back to full screen overlay
    return Positioned.fill(child: overlay);
  }

  // --- Player tap halves (fills entire panel including behind system bars) ---
  Widget _buildPlayerTapHalf({required int index, required int delta, required String label, required Alignment labelAlignment, required EdgeInsets labelPadding, required Border? border}) {
    final double blurSigma = frostedGlass ? 5.0 : 0.0;
    return Expanded(
      child: GestureDetector(
        onTap: () { setState(() { playerHealth[index] += delta; _log(index, LogEventType.healthChange, 'Health', value: delta); }); },
        child: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), border: border),
            child: Align(alignment: labelAlignment, child: Padding(padding: labelPadding, child: Text(label, style: TextStyle(fontSize: 28, color: Colors.black.withOpacity(0.4))))),
          ),
        )),
      ),
    );
  }

  // --- Single player panel: background + tap halves fill full space, content is padded ---
  Widget _buildPlayerPanel(int index) {
    final bool isActive = _showTurnTracker && activePlayer == index;

    return Container(
      decoration: isActive ? BoxDecoration(border: Border.all(color: Colors.blue, width: 3)) : null,
      child: Stack(
        children: [
          // Hero background
          Positioned.fill(
            child: Image.asset(
              'assets/images/${widget.playerHeroes[index]}.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            ),
          ),
          // Tap halves
          Positioned.fill(
            child: Row(children: [
              _buildPlayerTapHalf(index: index, delta: -1, label: '-', labelAlignment: Alignment.centerRight, labelPadding: EdgeInsets.only(right: 60), border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5))),
              _buildPlayerTapHalf(index: index, delta: 1, label: '+', labelAlignment: Alignment.centerLeft, labelPadding: EdgeInsets.only(left: 60), border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5))),
            ]),
          ),
          // Center content — biased toward the middle of the screen
          // Token chips — positioned toward the center divider
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, -.9),
              child: _buildTokenChips(index),
            ),
          ),
          // Health number — fixed at center
          Center(
            child: Text('${playerHealth[index]}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          // Add token button — fixed below center
          Positioned.fill(
            child: Align(
              alignment: Alignment(0, 0.3),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () { setState(() { _playerOverlay[index] = -2; }); },
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.add_box, size: 28, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Player widget with rotation applied ---
  Widget _buildPlayerWidget(int index) {
    Widget content = _buildPlayerPanel(index);
    final int? qt = _getQuarterTurns(index);
    if (qt != null) content = RotatedBox(quarterTurns: qt, child: content);
    return content;
  }

  // --- Turn tracker ---
 Widget _buildTurnTrackerPanel() {
    final int setting = resourceTrackerSetting;
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pitch', style: TextStyle(fontSize: labelSize, color: Colors.black54, height: 1.0, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                Text('${_playerPitch[playerIndex]}', style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold, color: Colors.black, height: 1.0)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _playerPitch[playerIndex]++; }); },
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AP', style: TextStyle(fontSize: labelSize, color: Colors.black54, height: 1.0, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                Text('${_playerAP[playerIndex]}', style: TextStyle(fontSize: numSize, fontWeight: FontWeight.bold, color: Colors.black, height: 1.0)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () { setState(() { _playerAP[playerIndex]++; }); },
            child: Icon(Icons.add, size: iconSize, color: Colors.black54),
          ),
        ],
      );
    }

    Widget centerContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_left, color: Colors.black, size: 20),
              onPressed: _retreatPhase,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Player ${activePlayer + 1}\'s Turn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black, height: 1.0)),
                  SizedBox(height: 2),
                  Text(fabPhases[currentPhase], style: TextStyle(fontSize: 14, color: Colors.black, height: 1.0)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_right, color: Colors.black, size: 20),
              onPressed: _advancePhase,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ],
    );

    // Layout: No trackers
    if (!showPitch && !showAP) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        child: centerContent,
      );
    }

    // Layout: Both trackers — stacked on each side
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

    // Layout: Single tracker — split to flanking sides, larger
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
  // --- Timer display ---
  Widget _buildTimerDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: _resetTimer, child: Icon(Icons.replay, color: Colors.white, size: 18)),
        SizedBox(width: 8),
        Text(_formatTimer(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _timerColor(), fontFeatures: [FontFeature.tabularFigures()])),
        SizedBox(width: 8),
        GestureDetector(onTap: _timerRunning ? _pauseTimer : _startTimer, child: Icon(_timerRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20)),
      ]),
    );
  }

  // --- Dice overlay ---
  Widget _buildDiceOverlay() {
    Widget choiceButtons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(onPressed: () => _onFirstTurnChoice(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: Text('Go First', style: TextStyle(fontSize: 18, color: Colors.white))),
        SizedBox(width: 24),
        ElevatedButton(onPressed: () => _onFirstTurnChoice(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: Text('Go Second', style: TextStyle(fontSize: 18, color: Colors.white))),
      ],
    );

    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Column(children: [
        Expanded(child: RotatedBox(quarterTurns: 2, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Player 1', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(_dieIcon(_p1Dice[0]), size: 64, color: Colors.white), SizedBox(width: 16), Icon(_dieIcon(_p1Dice[1]), size: 64, color: Colors.white)]),
          SizedBox(height: 8),
          Text('Total: ${_p1Dice[0] + _p1Dice[1]}', style: TextStyle(color: Colors.white70, fontSize: 18)),
          if (_diceFinished && !_diceRolling) ...[SizedBox(height: 8), Text(_diceWinner == 0 ? 'WINNER!' : '', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold))],
          if (_showChoicePrompt && _diceWinner == 0) ...[SizedBox(height: 16), choiceButtons],
        ])))),
        Container(height: 2, color: Colors.white24),
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Player 2', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(_dieIcon(_p2Dice[0]), size: 64, color: Colors.white), SizedBox(width: 16), Icon(_dieIcon(_p2Dice[1]), size: 64, color: Colors.white)]),
          SizedBox(height: 8),
          Text('Total: ${_p2Dice[0] + _p2Dice[1]}', style: TextStyle(color: Colors.white70, fontSize: 18)),
          if (_diceFinished && !_diceRolling) ...[SizedBox(height: 8), Text(_diceWinner == 1 ? 'WINNER!' : '', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold))],
          if (_showChoicePrompt && _diceWinner == 1) ...[SizedBox(height: 16), choiceButtons],
        ]))),
      ]),
    );
  }

  // --- Grid: full edge-to-edge, no padding here ---
  Widget _buildPlayerGrid() {
    if (playerHealth.length == 2) {
      if (_showTurnTracker) {
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
    return Column(children: [
      for (int i = 0; i < playerHealth.length; i += 2)
        Expanded(child: Row(children: [
          Expanded(child: _buildPlayerWidget(i)),
          if (i + 1 < playerHealth.length) Expanded(child: _buildPlayerWidget(i + 1)),
        ])),
    ]);
  }

  // --- Main build ---
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          _buildPlayerGrid(),
          // Timer top (rotated for P1)
          Positioned(top: 40, left: 0, right: 0, child: Center(child: RotatedBox(quarterTurns: 2, child: _buildTimerDisplay()))),
          Positioned(bottom: 40, left: 0, right: 0, child: Center(child: _buildTimerDisplay())),
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
              TextButton(onPressed: () { setState(() { playerHealth = List.filled(widget.playerCount, widget.startingLife); playerTokens = List.generate(widget.playerCount, (_) => []); _playerOverlay = List.filled(widget.playerCount, -1); activePlayer = 0; currentPhase = 0; turnCount = 0; _playerPitch = [0, 0]; _playerAP = [1, 0]; gameLog.clear(); }); _resetTimer(); Navigator.pop(ctx); }, child: Text('Reset', style: TextStyle(color: Colors.red))),
            ]));
          })),
          // Settings
          Positioned(bottom: 24, right: 16, child: IconButton(icon: Icon(Icons.settings, color: Colors.white), onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
              currentFont: currentFont, onFontChanged: (f) { widget.onFontChanged(f); setState(() { currentFont = f; }); },
              turnTrackerEnabled: turnTrackerEnabled, onTurnTrackerChanged: (e) { widget.onTurnTrackerChanged(e); setState(() { turnTrackerEnabled = e; }); },
              frostedGlass: frostedGlass, onFrostedGlassChanged: (e) { widget.onFrostedGlassChanged(e); setState(() { frostedGlass = e; }); },
              themeMode: widget.themeMode, onThemeModeChanged: widget.onThemeModeChanged,
              matchTimerMinutes: widget.matchTimerMinutes, onMatchTimerChanged: widget.onMatchTimerChanged,
              firstTurnSetting: widget.firstTurnSetting, onFirstTurnSettingChanged: widget.onFirstTurnSettingChanged,
              resourceTrackerSetting: resourceTrackerSetting, onResourceTrackerChanged: (int val) { widget.onResourceTrackerChanged(val); setState(() { resourceTrackerSetting = val; }); },
            )));
          })),
          // Log
          Positioned(bottom: 24, left: 16, child: IconButton(icon: Icon(Icons.list_alt, color: Colors.white), onPressed: () { showDialog(context: context, builder: (ctx) => Dialog(insetPadding: EdgeInsets.all(16), child: LogScreen(gameLog: gameLog))); })),
          // Dice overlay
          if (_showDiceOverlay) Positioned.fill(child: _buildDiceOverlay()),
          // Player overlays — on top of everything including timer and buttons
          for (int i = 0; i < widget.playerCount; i++)
            if (_playerOverlay[i] >= 0 && _playerOverlay[i] < TokenCategory.values.length)
              _buildPlayerOverlayPositioned(i, _buildCategoryOverlay(i, TokenCategory.values[_playerOverlay[i]])),
          for (int i = 0; i < widget.playerCount; i++)
            if (_playerOverlay[i] == -2)
              _buildPlayerOverlayPositioned(i, _buildAddTokenOverlay(i)),
        ]),
      ),
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
  _InlineTokenPickerState createState() => _InlineTokenPickerState();
}

class _InlineTokenPickerState extends State<_InlineTokenPicker> {
  String searchQuery = '';
  TokenCategory? selectedCategory;
  final searchController = TextEditingController();
  late List<String> currentFavorites;
  final Map<TokenCategory, String> catNames = {TokenCategory.ally: 'Allies', TokenCategory.item: 'Items', TokenCategory.boonAura: 'Boons', TokenCategory.debuffAura: 'Debuffs'};

  @override
  void initState() { super.initState(); currentFavorites = List.from(widget.favoriteTokens); }
  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  List<TokenData> _getFiltered() {
    var tokens = List<TokenData>.from(widget.allTokens);
    if (selectedCategory != null) tokens = tokens.where((t) => t.category == selectedCategory).toList();
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
            Padding(padding: EdgeInsets.only(right: 4), child: FilterChip(label: Text('All', style: TextStyle(fontSize: 11)), selected: selectedCategory == null, onSelected: (_) { setState(() { selectedCategory = null; }); }, visualDensity: VisualDensity.compact)),
            for (var c in TokenCategory.values)
              Padding(padding: EdgeInsets.only(right: 4), child: FilterChip(label: Text(catNames[c] ?? '', style: TextStyle(fontSize: 11)), selected: selectedCategory == c, onSelected: (_) { setState(() { selectedCategory = selectedCategory == c ? null : c; }); }, visualDensity: VisualDensity.compact)),
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
                    final inPlayCount = widget.playerTokens.where((t) => t.name == td.name).length;
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
                          if (inPlayCount > 0) Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Text('x$inPlayCount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
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