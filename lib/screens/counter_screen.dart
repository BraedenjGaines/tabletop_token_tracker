import 'package:flutter/material.dart';
import 'dart:async';
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

  int activePlayer = 0;
  int currentPhase = 0;
  int turnCount = 0;

  List<TokenData> customTokens = [];
  List<String> favoriteTokens = [];

  final GameLog gameLog = GameLog();

  // Match timer state
  late int _timerSecondsRemaining;
  Timer? _timer;
  bool _timerRunning = false;

  final List<String> fabPhases = [
    'Start Phase',
    'Draw Phase',
    'Action Phase',
    'End Phase',
  ];

  bool get _showTurnTracker =>
      turnTrackerEnabled &&
      widget.selectedGame == 'fab' &&
      widget.playerCount == 2;

  String? get _currentPhaseName =>
      _showTurnTracker ? fabPhases[currentPhase] : null;

  void _log(int playerIndex, LogEventType type, String description, {int value = 0}) {
    final int minutes = _timerSecondsRemaining ~/ 60;
    final int seconds = _timerSecondsRemaining % 60;
    final String timerStamp = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    gameLog.addEntry(LogEntry(
      playerIndex: playerIndex,
      type: type,
      description: description,
      value: value,
      timestamp: timerStamp,
      turn: _showTurnTracker ? turnCount : null,
      phase: _currentPhaseName,
    ));
  }

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(widget.playerCount, widget.startingLife);
    playerTokens = List.generate(widget.playerCount, (_) => []);
    currentFont = widget.selectedFont;
    turnTrackerEnabled = widget.turnTrackerEnabled;
    frostedGlass = widget.frostedGlass;
    _timerSecondsRemaining = widget.matchTimerMinutes * 60;
    _loadTokenPreferences();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- Timer methods ---

  void _startTimer() {
    if (_timerRunning || _timerSecondsRemaining <= 0) return;
    _timerRunning = true;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSecondsRemaining > 0) {
          _timerSecondsRemaining--;
        } else {
          _timer?.cancel();
          _timerRunning = false;
        }
      });
    });
    setState(() {});
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerSecondsRemaining = widget.matchTimerMinutes * 60;
    });
  }

  String _formatTimer() {
    final int minutes = _timerSecondsRemaining ~/ 60;
    final int seconds = _timerSecondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_timerSecondsRemaining <= 0) return Colors.red;
    if (_timerSecondsRemaining <= 300) return Colors.orange; // 5 min warning
    return Colors.white;
  }

  // --- Token preferences ---

  Future<void> _loadTokenPreferences() async {
    final customs = await TokenPreferences.getCustomTokensFull(widget.selectedGame);
    final favs = await TokenPreferences.getFavorites(widget.selectedGame);
    setState(() {
      customTokens = customs;
      favoriteTokens = favs;
    });
  }

  bool _isMiddleRow(int playerIndex) {
    final int rowCount = (playerHealth.length + 1) ~/ 2;
    if (rowCount < 3) return false;
    final int playerRow = playerIndex ~/ 2;
    final int middleRow = rowCount ~/ 2;
    return playerRow == middleRow;
  }

  int? _getQuarterTurns(int index) {
    if (playerHealth.length == 2) return index == 0 ? 2 : null;

    final int rowCount = (playerHealth.length + 1) ~/ 2;
    final int currentRow = index ~/ 2;
    final bool isMiddle = _isMiddleRow(index);
    final bool isTop = currentRow < (rowCount / 2).floor() && !isMiddle;

    if (isTop) return 2;
    if (isMiddle) return (index % 2 == 0) ? 1 : 3;
    return null;
  }

  void _advancePhase() {
    setState(() {
      if (currentPhase < fabPhases.length - 1) {
        currentPhase++;
        _logNewlyTriggering();
        _log(activePlayer, LogEventType.phaseChange, fabPhases[currentPhase]);
      } else {
        _checkAutoDestroy();
        currentPhase = 0;
        activePlayer = activePlayer == 0 ? 1 : 0;
        turnCount++;
        _logNewlyTriggering();
        _log(activePlayer, LogEventType.phaseChange, 'Turn ${turnCount + 1} - ${fabPhases[currentPhase]}');
      }
    });
  }

  void _logNewlyTriggering() {
    for (int playerIndex = 0; playerIndex < playerTokens.length; playerIndex++) {
      for (var token in playerTokens[playerIndex]) {
        if (_isTokenTriggering(token, playerIndex)) {
          _log(playerIndex, LogEventType.tokenActivated, '${token.name} active');
        }
      }
    }
  }

  void _retreatPhase() {
    setState(() {
      if (currentPhase > 0) {
        currentPhase--;
        _log(activePlayer, LogEventType.phaseChange, 'Back to ${fabPhases[currentPhase]}');
      }
    });
  }

  void _checkAutoDestroy() {
    if (!_showTurnTracker) return;

    for (int playerIndex = 0; playerIndex < playerTokens.length; playerIndex++) {
      playerTokens[playerIndex].removeWhere((token) {
        if (token.destroyTrigger == null) return false;
        bool shouldRemove = token.count <= 0 || _shouldAutoRemove(token, playerIndex);
        if (shouldRemove) {
          _log(playerIndex, LogEventType.tokenDestroyed, '${token.name} destroyed');
        }
        return shouldRemove;
      });
    }
  }

  bool _shouldAutoRemove(ActiveToken token, int playerIndex) {
    switch (token.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn:
        return playerIndex == activePlayer && turnCount > token.turnPlayed;
      case DestroyTrigger.startOfOpponentTurn:
        return playerIndex != activePlayer && turnCount > token.turnPlayed;
      case DestroyTrigger.beginningOfActionPhase:
        return playerIndex == activePlayer && turnCount > token.turnPlayed;
      case DestroyTrigger.beginningOfEndPhase:
        return playerIndex == activePlayer && turnCount > token.turnPlayed;
    }
  }

  bool _isTokenTriggering(ActiveToken token, int playerIndex) {
    if (!_showTurnTracker || token.destroyTrigger == null) return false;

    bool isActivePlayerToken = playerIndex == activePlayer;

    switch (token.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn:
        return isActivePlayerToken && turnCount > token.turnPlayed && currentPhase >= 0;
      case DestroyTrigger.startOfOpponentTurn:
        return !isActivePlayerToken && turnCount > token.turnPlayed && currentPhase >= 0;
      case DestroyTrigger.beginningOfActionPhase:
        return isActivePlayerToken && turnCount >= token.turnPlayed && currentPhase >= 2;
      case DestroyTrigger.beginningOfEndPhase:
        return isActivePlayerToken && currentPhase >= 3;
    }
  }

  Color _getTokenCategoryColor(TokenCategory category) {
    switch (category) {
      case TokenCategory.ally:
        return Colors.orange.withOpacity(0.3);
      case TokenCategory.boonAura:
        return Colors.green.withOpacity(0.3);
      case TokenCategory.debuffAura:
        return Colors.red.withOpacity(0.3);
      case TokenCategory.item:
        return Colors.blue.withOpacity(0.3);
    }
  }

  void _showGameLog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: LogScreen(gameLog: gameLog),
        );
      },
    );
  }

  void _showTokenPicker(int playerIndex) {
    final List<TokenData> libraryTokens = tokenLibrary[widget.selectedGame] ?? [];
    final List<TokenData> allTokens = [...libraryTokens, ...customTokens];
    final int? quarterTurns = _getQuarterTurns(playerIndex);

    showDialog(
      context: context,
      builder: (context) {
        Widget picker = Dialog(
          insetPadding: EdgeInsets.all(16),
          child: _TokenPickerSheet(
            allTokens: allTokens,
            favoriteTokens: favoriteTokens,
            playerTokens: playerTokens[playerIndex],
            gameId: widget.selectedGame,
            onTokenAdded: (TokenData tokenData) {
              setState(() {
                if (tokenData.category == TokenCategory.ally) {
                  playerTokens[playerIndex].add(ActiveToken(
                    name: tokenData.name,
                    category: tokenData.category,
                    destroyTrigger: tokenData.destroyTrigger,
                    health: tokenData.health,
                    maxHealth: tokenData.health,
                    turnPlayed: turnCount,
                    playerPlayed: playerIndex,
                  ));
                } else {
                  playerTokens[playerIndex].add(ActiveToken(
                    name: tokenData.name,
                    category: tokenData.category,
                    destroyTrigger: tokenData.destroyTrigger,
                    turnPlayed: turnCount,
                    playerPlayed: playerIndex,
                  ));
                }
                _log(playerIndex, LogEventType.tokenAdded, '${tokenData.name} added');
              });
            },
            onCustomTokenAdded: (TokenData tokenData) {
              setState(() {
                customTokens.add(tokenData);
              });
            },
            onFavoriteToggled: (String tokenName, List<String> updatedFavorites) {
              setState(() {
                favoriteTokens = updatedFavorites;
              });
            },
          ),
        );

        if (quarterTurns != null) {
          return RotatedBox(quarterTurns: quarterTurns, child: picker);
        }
        return picker;
      },
    );
  }

  Widget _buildAllyToken(ActiveToken token, int playerIndex, int tokenIndex) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTokenCategoryColor(token.category),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                token.health = token.health! - 1;
                _log(playerIndex, LogEventType.allyHealthChange, '${token.name} health', value: -1);
                if (token.health! <= 0) {
                  playerTokens[playerIndex].removeAt(tokenIndex);
                  _log(playerIndex, LogEventType.tokenDestroyed, '${token.name} destroyed');
                }
              });
            },
            child: Icon(Icons.remove_circle, size: 18, color: Colors.red),
          ),
          SizedBox(width: 4),
          Text('${token.health}/${token.maxHealth}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                token.health = token.health! + 1;
                _log(playerIndex, LogEventType.allyHealthChange, '${token.name} health', value: 1);
              });
            },
            child: Icon(Icons.add_circle, size: 18, color: Colors.green),
          ),
          SizedBox(width: 8),
          Text(token.name, style: TextStyle(fontSize: 11)),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                playerTokens[playerIndex].removeAt(tokenIndex);
                _log(playerIndex, LogEventType.tokenDestroyed, '${token.name} destroyed');
              });
            },
            child: Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterToken(ActiveToken token, int playerIndex, int tokenIndex) {
    final bool triggering = _isTokenTriggering(token, playerIndex);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTokenCategoryColor(token.category),
        borderRadius: BorderRadius.circular(6),
        border: triggering ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (triggering)
            Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.flash_on, size: 16, color: Colors.amber),
            ),
          GestureDetector(
            onTap: () {
              setState(() {
                token.count--;
                _log(playerIndex, LogEventType.tokenCountChange, token.name, value: -1);
                if (token.count <= 0) {
                  playerTokens[playerIndex].removeAt(tokenIndex);
                  _log(playerIndex, LogEventType.tokenDestroyed, '${token.name} destroyed');
                }
              });
            },
            child: Icon(Icons.remove_circle, size: 18),
          ),
          SizedBox(width: 4),
          Text('${token.count}', style: TextStyle(fontSize: 13)),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                token.count++;
                _log(playerIndex, LogEventType.tokenCountChange, token.name, value: 1);
              });
            },
            child: Icon(Icons.add_circle, size: 18),
          ),
          SizedBox(width: 8),
          Text(token.name, style: TextStyle(fontSize: 11)),
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                playerTokens[playerIndex].removeAt(tokenIndex);
                _log(playerIndex, LogEventType.tokenDestroyed, '${token.name} destroyed');
              });
            },
            child: Icon(Icons.close, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTapHalf({
    required int index,
    required int delta,
    required String label,
    required Alignment labelAlignment,
    required EdgeInsets labelPadding,
    required Border? border,
  }) {
    final double blurSigma = frostedGlass ? 5.0 : 0.0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            playerHealth[index] += delta;
            _log(index, LogEventType.healthChange, 'Health', value: delta);
          });
        },
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                border: border,
              ),
              child: Align(
                alignment: labelAlignment,
                child: Padding(
                  padding: labelPadding,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 28, color: Colors.grey.withOpacity(0.8)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerWidget(int index) {
    final bool isActive = _showTurnTracker && activePlayer == index;

    final allies = <int>[];
    final boonAuras = <int>[];
    final debuffAuras = <int>[];
    final items = <int>[];

    for (int i = 0; i < playerTokens[index].length; i++) {
      switch (playerTokens[index][i].category) {
        case TokenCategory.ally:
          allies.add(i);
          break;
        case TokenCategory.boonAura:
          boonAuras.add(i);
          break;
        case TokenCategory.debuffAura:
          debuffAuras.add(i);
          break;
        case TokenCategory.item:
          items.add(i);
          break;
      }
    }

    Widget content = Container(
      decoration: isActive
          ? BoxDecoration(border: Border.all(color: Colors.blue, width: 3))
          : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/${widget.playerHeroes[index]}.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.grey[900]);
              },
            ),
          ),
          Row(
            children: [
              _buildPlayerTapHalf(
                index: index,
                delta: -1,
                label: '-',
                labelAlignment: Alignment.centerRight,
                labelPadding: EdgeInsets.only(right: 60),
                border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5)),
              ),
              _buildPlayerTapHalf(
                index: index,
                delta: 1,
                label: '+',
                labelAlignment: Alignment.centerLeft,
                labelPadding: EdgeInsets.only(left: 60),
                border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 0.5)),
              ),
            ],
          ),
          if (boonAuras.isNotEmpty)
            Positioned(
              top: 8, left: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (int i in boonAuras) _buildCounterToken(playerTokens[index][i], index, i)],
              ),
            ),
          if (debuffAuras.isNotEmpty)
            Positioned(
              top: 8, right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [for (int i in debuffAuras) _buildCounterToken(playerTokens[index][i], index, i)],
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (allies.isNotEmpty)
                  Column(children: [for (int i in allies) _buildAllyToken(playerTokens[index][i], index, i)]),
                SizedBox(height: 4),
                Text('${playerHealth[index]}',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                if (items.isNotEmpty)
                  Column(children: [for (int i in items) _buildCounterToken(playerTokens[index][i], index, i)]),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showTokenPicker(index),
                  child: Icon(Icons.add_box, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final int? quarterTurns = _getQuarterTurns(index);
    if (quarterTurns != null) {
      content = RotatedBox(quarterTurns: quarterTurns, child: content);
    }
    return content;
  }

  Widget _buildTurnTrackerPanel() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: Icon(Icons.arrow_left), onPressed: _retreatPhase),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Player ${activePlayer + 1}\'s Turn',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(fabPhases[currentPhase], style: TextStyle(fontSize: 16)),
            ],
          ),
          IconButton(icon: Icon(Icons.arrow_right), onPressed: _advancePhase),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _resetTimer,
            child: Icon(Icons.replay, color: Colors.white, size: 18),
          ),
          SizedBox(width: 8),
          Text(
            _formatTimer(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _timerColor(),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: _timerRunning ? _pauseTimer : _startTimer,
            child: Icon(
              _timerRunning ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerGrid() {
    if (playerHealth.length == 2) {
      if (_showTurnTracker) {
        return Column(
          children: [
            Expanded(child: _buildPlayerWidget(0)),
            _buildTurnTrackerPanel(),
            Expanded(child: _buildPlayerWidget(1)),
          ],
        );
      }
      return Column(
        children: [
          Expanded(child: _buildPlayerWidget(0)),
          Expanded(child: _buildPlayerWidget(1)),
        ],
      );
    }
    return Column(
      children: [
        for (int i = 0; i < playerHealth.length; i += 2)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPlayerWidget(i)),
                if (i + 1 < playerHealth.length)
                  Expanded(child: _buildPlayerWidget(i + 1)),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        children: [
          _buildPlayerGrid(),

          // Timer - top (rotated for player 1)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: RotatedBox(
                quarterTurns: 2,
                child: _buildTimerDisplay(),
              ),
            ),
          ),

          // Timer - bottom (right-side-up for player 2)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(child: _buildTimerDisplay()),
          ),

          // Home button - top left
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                if (gameLog.entries.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Leave Game'),
                        content: Text('A game is in progress. Are you sure you want to return to the home screen?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              _timer?.cancel();
                              Navigator.pop(context);
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            child: Text('Leave', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  _timer?.cancel();
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
          ),

          // Reset button - top right
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Reset Game'),
                      content: Text('This will reset all health, tokens, the timer, and the game log. Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              playerHealth = List.filled(widget.playerCount, widget.startingLife);
                              playerTokens = List.generate(widget.playerCount, (_) => []);
                              activePlayer = 0;
                              currentPhase = 0;
                              turnCount = 0;
                              gameLog.clear();
                            });
                            _resetTimer();
                            Navigator.pop(context);
                          },
                          child: Text('Reset', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Settings button - bottom right
          Positioned(
            bottom: 24,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      currentFont: currentFont,
                      onFontChanged: (String newFont) {
                        widget.onFontChanged(newFont);
                        setState(() { currentFont = newFont; });
                      },
                      turnTrackerEnabled: turnTrackerEnabled,
                      onTurnTrackerChanged: (bool enabled) {
                        widget.onTurnTrackerChanged(enabled);
                        setState(() { turnTrackerEnabled = enabled; });
                      },
                      frostedGlass: frostedGlass,
                      onFrostedGlassChanged: (bool enabled) {
                        widget.onFrostedGlassChanged(enabled);
                        setState(() { frostedGlass = enabled; });
                      },
                      themeMode: widget.themeMode,
                      onThemeModeChanged: widget.onThemeModeChanged,
                      matchTimerMinutes: widget.matchTimerMinutes,
                      onMatchTimerChanged: widget.onMatchTimerChanged,
                      showPlayerCount: true,
                      onShowPlayerCountChanged: (_) {},
                    ),
                  ),
                );
              },
            ),
          ),

          // Log button - bottom left
          Positioned(
            bottom: 24,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.list_alt, color: Colors.white),
              onPressed: _showGameLog,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _TokenPickerSheet extends StatefulWidget {
  final List<TokenData> allTokens;
  final List<String> favoriteTokens;
  final List<ActiveToken> playerTokens;
  final String gameId;
  final Function(TokenData) onTokenAdded;
  final Function(TokenData) onCustomTokenAdded;
  final Function(String, List<String>) onFavoriteToggled;

  const _TokenPickerSheet({
    required this.allTokens,
    required this.favoriteTokens,
    required this.playerTokens,
    required this.gameId,
    required this.onTokenAdded,
    required this.onCustomTokenAdded,
    required this.onFavoriteToggled,
  });

  @override
  _TokenPickerSheetState createState() => _TokenPickerSheetState();
}

class _TokenPickerSheetState extends State<_TokenPickerSheet> {
  String searchQuery = '';
  TokenCategory? selectedCategory;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController customTokenController = TextEditingController();
  late List<String> currentFavorites;

  final Map<TokenCategory, String> categoryNames = {
    TokenCategory.ally: 'Allies',
    TokenCategory.item: 'Items',
    TokenCategory.boonAura: 'Boon Auras',
    TokenCategory.debuffAura: 'Debuff Auras',
  };

  @override
  void initState() {
    super.initState();
    currentFavorites = List.from(widget.favoriteTokens);
  }

  @override
  void dispose() {
    searchController.dispose();
    customTokenController.dispose();
    super.dispose();
  }

  List<TokenData> _getSortedFilteredTokens() {
    List<TokenData> tokens = List.from(widget.allTokens);
    if (selectedCategory != null) {
      tokens = tokens.where((t) => t.category == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      tokens = tokens.where((t) => t.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    final favs = tokens.where((t) => currentFavorites.contains(t.name)).toList()..sort((a, b) => a.name.compareTo(b.name));
    final nonFavs = tokens.where((t) => !currentFavorites.contains(t.name)).toList()..sort((a, b) => a.name.compareTo(b.name));
    return [...favs, ...nonFavs];
  }

  void _showAddCustomDialog() {
    final nameController = TextEditingController();
    final healthController = TextEditingController();
    TokenCategory dialogCategory = TokenCategory.boonAura;
    DestroyTrigger? dialogTrigger;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Custom Token'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameController, decoration: InputDecoration(hintText: 'Token name')),
                    SizedBox(height: 16),
                    Text('Category'),
                    SizedBox(height: 8),
                    DropdownButton<TokenCategory>(
                      value: dialogCategory,
                      isExpanded: true,
                      items: TokenCategory.values.map((cat) => DropdownMenuItem(value: cat, child: Text(_getCategoryLabel(cat)))).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            dialogCategory = value;
                            if (value != TokenCategory.boonAura && value != TokenCategory.debuffAura) dialogTrigger = null;
                            if (value != TokenCategory.ally) healthController.clear();
                          });
                        }
                      },
                    ),
                    if (dialogCategory == TokenCategory.ally) ...[
                      SizedBox(height: 16), Text('Health'), SizedBox(height: 8),
                      TextField(controller: healthController, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Health value')),
                    ],
                    if (dialogCategory == TokenCategory.boonAura || dialogCategory == TokenCategory.debuffAura) ...[
                      SizedBox(height: 16), Text('Auto-destroy'), SizedBox(height: 8),
                      DropdownButton<DestroyTrigger?>(
                        value: dialogTrigger, isExpanded: true,
                        items: [
                          DropdownMenuItem(value: null, child: Text('None (manual only)')),
                          DropdownMenuItem(value: DestroyTrigger.startOfYourTurn, child: Text('Start of your turn')),
                          DropdownMenuItem(value: DestroyTrigger.startOfOpponentTurn, child: Text("Start of opponent's turn")),
                          DropdownMenuItem(value: DestroyTrigger.beginningOfActionPhase, child: Text('Beginning of action phase')),
                          DropdownMenuItem(value: DestroyTrigger.beginningOfEndPhase, child: Text('Beginning of end phase')),
                        ],
                        onChanged: (value) { setDialogState(() { dialogTrigger = value; }); },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final health = int.tryParse(healthController.text);
                    if (name.isNotEmpty && !widget.allTokens.any((t) => t.name == name)) {
                      if (dialogCategory == TokenCategory.ally && (health == null || health <= 0)) return;
                      final newToken = TokenData(name: name, category: dialogCategory, destroyTrigger: dialogTrigger, health: dialogCategory == TokenCategory.ally ? health : null);
                      TokenPreferences.addCustomTokenFull(widget.gameId, newToken);
                      TokenPreferences.addCustomToken(widget.gameId, name);
                      widget.onCustomTokenAdded(newToken);
                      widget.allTokens.add(newToken);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getCategoryLabel(TokenCategory category) => categoryNames[category] ?? 'Unknown';

  @override
  Widget build(BuildContext context) {
    final sortedTokens = _getSortedFilteredTokens();
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Token', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton.icon(onPressed: _showAddCustomDialog, icon: Icon(Icons.add), label: Text('Custom')),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: InputDecoration(hintText: 'Search tokens...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onChanged: (value) { setState(() { searchQuery = value; }); },
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(padding: EdgeInsets.only(right: 4), child: FilterChip(label: Text('All'), selected: selectedCategory == null, onSelected: (_) { setState(() { selectedCategory = null; }); })),
              for (var category in TokenCategory.values)
                Padding(padding: EdgeInsets.only(right: 4), child: FilterChip(label: Text(_getCategoryLabel(category)), selected: selectedCategory == category, onSelected: (_) { setState(() { selectedCategory = selectedCategory == category ? null : category; }); })),
            ]),
          ),
          SizedBox(height: 8),
          Expanded(
            child: sortedTokens.isEmpty
                ? Center(child: Text('No tokens found'))
                : ListView.builder(
                    itemCount: sortedTokens.length,
                    itemBuilder: (context, index) {
                      final tokenData = sortedTokens[index];
                      final alreadyAdded = widget.playerTokens.any((t) => t.name == tokenData.name);
                      final isFavorite = currentFavorites.contains(tokenData.name);
                      return ListTile(
                        leading: GestureDetector(
                          onTap: () async {
                            await TokenPreferences.toggleFavorite(widget.gameId, tokenData.name);
                            setState(() { isFavorite ? currentFavorites.remove(tokenData.name) : currentFavorites.add(tokenData.name); });
                            widget.onFavoriteToggled(tokenData.name, List.from(currentFavorites));
                          },
                          child: Icon(isFavorite ? Icons.star : Icons.star_border, color: isFavorite ? Colors.amber : Colors.grey),
                        ),
                        title: Text(tokenData.name),
                        subtitle: Text(_getCategoryLabel(tokenData.category), style: TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: alreadyAdded ? Icon(Icons.check, color: Colors.green) : Icon(Icons.add_circle_outline),
                        onTap: () { if (!alreadyAdded) widget.onTokenAdded(tokenData); Navigator.pop(context); },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
