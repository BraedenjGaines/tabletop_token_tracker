import 'package:flutter/material.dart';
import 'dart:math';
import 'settings_screen.dart';
import '../data/token_library.dart';
import '../data/token_preferences.dart';

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
  final String selectedFont;
  final Function(String) onFontChanged;
  final String selectedGame;
  final bool turnTrackerEnabled;
  final Function(bool) onTurnTrackerChanged;
  final bool skipGameSelect;
  final Function(String, bool) onGameChanged;

  CounterScreen({
    required this.playerCount,
    required this.startingLife,
    required this.selectedFont,
    required this.onFontChanged,
    required this.selectedGame,
    required this.turnTrackerEnabled,
    required this.onTurnTrackerChanged,
    required this.skipGameSelect,
    required this.onGameChanged,
  });

  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  late List<int> playerHealth;
  late List<List<ActiveToken>> playerTokens;
  late String currentFont;
  late bool turnTrackerEnabled;

  int activePlayer = 0;
  int currentPhase = 0;
  int turnCount = 0;

  List<String> customTokens = [];
  List<String> favoriteTokens = [];

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

  @override
  void initState() {
    super.initState();
    playerHealth = List.filled(widget.playerCount, widget.startingLife);
    playerTokens = List.generate(widget.playerCount, (_) => []);
    currentFont = widget.selectedFont;
    turnTrackerEnabled = widget.turnTrackerEnabled;
    _loadTokenPreferences();
  }

  Future<void> _loadTokenPreferences() async {
    final customs = await TokenPreferences.getCustomTokens(widget.selectedGame);
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

  double? _getRotationAngle(int index) {
    if (playerHealth.length == 2) return index == 0 ? pi : null;

    final int rowCount = (playerHealth.length + 1) ~/ 2;
    final int currentRow = index ~/ 2;
    final bool isMiddle = _isMiddleRow(index);
    final bool isTop = currentRow < (rowCount / 2).floor() && !isMiddle;

    if (isTop) return pi;
    if (isMiddle) return (index % 2 == 0) ? pi / 2 : -pi / 2;
    return null;
  }

  void _advancePhase() {
    setState(() {
      if (currentPhase < fabPhases.length - 1) {
        currentPhase++;
        _checkAutoDestroy();
      } else {
        currentPhase = 0;
        activePlayer = activePlayer == 0 ? 1 : 0;
        turnCount++;
        _checkAutoDestroy();
      }
    });
  }

  void _retreatPhase() {
    setState(() {
      if (currentPhase > 0) {
        currentPhase--;
      }
    });
  }

  void _checkAutoDestroy() {
    if (!_showTurnTracker) return;

    String currentPhaseName = fabPhases[currentPhase];

    for (int playerIndex = 0; playerIndex < playerTokens.length; playerIndex++) {
      playerTokens[playerIndex].removeWhere((token) {
        if (token.destroyTrigger == null) return false;

        switch (token.destroyTrigger!) {
          case DestroyTrigger.startOfYourTurn:
            return currentPhaseName == 'Start Phase' &&
                playerIndex == activePlayer &&
                turnCount > token.turnPlayed;

          case DestroyTrigger.startOfOpponentTurn:
            return currentPhaseName == 'Start Phase' &&
                playerIndex != activePlayer &&
                turnCount > token.turnPlayed;

          case DestroyTrigger.beginningOfActionPhase:
            return currentPhaseName == 'Action Phase' &&
                playerIndex == activePlayer &&
                turnCount >= token.turnPlayed;

          case DestroyTrigger.beginningOfEndPhase:
            return currentPhaseName == 'End Phase' &&
                playerIndex == activePlayer;
        }
      });
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

  TokenData? _findTokenData(String name) {
    final List<TokenData> libraryTokens = tokenLibrary[widget.selectedGame] ?? [];
    try {
      return libraryTokens.firstWhere((t) => t.name == name);
    } catch (e) {
      return null;
    }
  }

  void _showTokenPicker(int playerIndex) {
  final List<TokenData> libraryTokens = tokenLibrary[widget.selectedGame] ?? [];

  final List<TokenData> customTokenData = customTokens.map((name) {
    return TokenData(name: name, category: TokenCategory.boonAura);
  }).toList();

  final List<TokenData> allTokens = [...libraryTokens, ...customTokenData];

  final double? angle = _getRotationAngle(playerIndex);

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
            });
          },
          onCustomTokenAdded: (String tokenName) {
            setState(() {
              customTokens.add(tokenName);
            });
          },
          onFavoriteToggled: (String tokenName, List<String> updatedFavorites) {
            setState(() {
              favoriteTokens = updatedFavorites;
            });
          },
        ),
      );

      if (angle != null) {
        return Transform.rotate(angle: angle, child: picker);
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
              if (token.health! <= 0) {
                playerTokens[playerIndex].removeAt(tokenIndex);
              }
            });
          },
          child: Icon(Icons.remove_circle, size: 18, color: Colors.red),
        ),
        SizedBox(width: 4),
        Text(
          '${token.health}/${token.maxHealth}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              token.health = token.health! + 1;
            });
          },
          child: Icon(Icons.add_circle, size: 18, color: Colors.green),
        ),
        SizedBox(width: 8),
        Text(
          token.name,
          style: TextStyle(fontSize: 11),
        ),
        SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              playerTokens[playerIndex].removeAt(tokenIndex);
            });
          },
          child: Icon(Icons.close, size: 16, color: Colors.grey),
        ),
      ],
    ),
  );
}

  Widget _buildCounterToken(ActiveToken token, int playerIndex, int tokenIndex) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 2),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _getTokenCategoryColor(token.category),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              token.count--;
              if (token.count <= 0) {
                playerTokens[playerIndex].removeAt(tokenIndex);
              }
            });
          },
          child: Icon(Icons.remove_circle, size: 18),
        ),
        SizedBox(width: 4),
        Text(
          '${token.count}',
          style: TextStyle(fontSize: 13),
        ),
        SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              token.count++;
            });
          },
          child: Icon(Icons.add_circle, size: 18),
        ),
        SizedBox(width: 8),
        Text(
          token.name,
          style: TextStyle(fontSize: 11),
        ),
        SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            setState(() {
              playerTokens[playerIndex].removeAt(tokenIndex);
            });
          },
          child: Icon(Icons.close, size: 16, color: Colors.grey),
        ),
      ],
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
        ? BoxDecoration(
            border: Border.all(color: Colors.blue, width: 3),
          )
        : null,
    child: Stack(
      children: [
        // Boon auras - top left
        if (boonAuras.isNotEmpty)
          Positioned(
            top: 8,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i in boonAuras)
                  _buildCounterToken(playerTokens[index][i], index, i),
              ],
            ),
          ),

        // Debuff auras - top right
        if (debuffAuras.isNotEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i in debuffAuras)
                  _buildCounterToken(playerTokens[index][i], index, i),
              ],
            ),
          ),

        // Center content - allies, health, items
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Allies above health
              if (allies.isNotEmpty)
                Column(
                  children: [
                    for (int i in allies)
                      _buildAllyToken(playerTokens[index][i], index, i),
                  ],
                ),
              SizedBox(height: 4),
              // Health row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() { playerHealth[index]--; });
                    },
                    child: Text('-'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '${playerHealth[index]}',
                      style: TextStyle(
                        fontSize: 32,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() { playerHealth[index]++; });
                    },
                    child: Text('+'),
                  ),
                ],
              ),
              SizedBox(height: 4),
              // Items below health
              if (items.isNotEmpty)
                Column(
                  children: [
                    for (int i in items)
                      _buildCounterToken(playerTokens[index][i], index, i),
                  ],
                ),
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

  final double? angle = _getRotationAngle(index);
  if (angle != null) {
    content = Transform.rotate(angle: angle, child: content);
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
          IconButton(
            icon: Icon(Icons.arrow_left),
            onPressed: _retreatPhase,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Player ${activePlayer + 1}\'s Turn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                fabPhases[currentPhase],
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.arrow_right),
            onPressed: _advancePhase,
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
    return Scaffold(
      body: Stack(
        children: [
          _buildPlayerGrid(),

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  playerHealth = List.filled(
                    widget.playerCount,
                    widget.startingLife,
                  );
                  playerTokens = List.generate(widget.playerCount, (_) => []);
                  activePlayer = 0;
                  currentPhase = 0;
                  turnCount = 0;
                });
              },
            ),
          ),

          Positioned(
            bottom: 24,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      currentFont: currentFont,
                      onFontChanged: (String newFont) {
                        widget.onFontChanged(newFont);
                        setState(() {
                          currentFont = newFont;
                        });
                      },
                      turnTrackerEnabled: turnTrackerEnabled,
                      onTurnTrackerChanged: (bool enabled) {
                        widget.onTurnTrackerChanged(enabled);
                        setState(() {
                          turnTrackerEnabled = enabled;
                        });
                      },
                      currentGame: widget.selectedGame,
                      skipGameSelect: widget.skipGameSelect,
                      onGameChanged: widget.onGameChanged,
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: 24,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.more_horiz),
              onPressed: () {
                // TODO: future feature
              },
            ),
          ),
        ],
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
  final Function(String) onCustomTokenAdded;
  final Function(String, List<String>) onFavoriteToggled;
  final bool isDialog;

  _TokenPickerSheet({
    required this.allTokens,
    required this.favoriteTokens,
    required this.playerTokens,
    required this.gameId,
    required this.onTokenAdded,
    required this.onCustomTokenAdded,
    required this.onFavoriteToggled,
    this.isDialog = false,
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
      tokens = tokens
          .where((t) => t.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    final List<TokenData> favs = tokens
        .where((t) => currentFavorites.contains(t.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final List<TokenData> nonFavs = tokens
        .where((t) => !currentFavorites.contains(t.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return [...favs, ...nonFavs];
  }

  void _showAddCustomDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Custom Token'),
          content: TextField(
            controller: customTokenController,
            decoration: InputDecoration(
              hintText: 'Token name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                customTokenController.clear();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = customTokenController.text.trim();
                if (name.isNotEmpty &&
                    !widget.allTokens.any((t) => t.name == name)) {
                  TokenPreferences.addCustomToken(widget.gameId, name);
                  widget.onCustomTokenAdded(name);
                  widget.allTokens.add(
                    TokenData(name: name, category: TokenCategory.boonAura),
                  );
                }
                Navigator.pop(context);
                customTokenController.clear();
                setState(() {});
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryLabel(TokenCategory category) {
    return categoryNames[category] ?? 'Unknown';
  }

  @override
    Widget build(BuildContext context) {
      final sortedTokens = _getSortedFilteredTokens();

      return Container(
        padding: EdgeInsets.all(16),
        height: widget.isDialog ? MediaQuery.of(context).size.height * 0.6 : MediaQuery.of(context).size.height * 0.7,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Token',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _showAddCustomDialog,
                icon: Icon(Icons.add),
                label: Text('Custom'),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search tokens...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: FilterChip(
                    label: Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = null;
                      });
                    },
                  ),
                ),
                for (var category in TokenCategory.values)
                  Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: FilterChip(
                      label: Text(_getCategoryLabel(category)),
                      selected: selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory =
                              selectedCategory == category ? null : category;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: sortedTokens.isEmpty
                ? Center(child: Text('No tokens found'))
                : ListView.builder(
                    itemCount: sortedTokens.length,
                    itemBuilder: (context, index) {
                      final tokenData = sortedTokens[index];
                      final bool alreadyAdded = widget.playerTokens
                          .any((t) => t.name == tokenData.name);
                      final bool isFavorite =
                          currentFavorites.contains(tokenData.name);

                      return ListTile(
                        leading: GestureDetector(
                          onTap: () async {
                            await TokenPreferences.toggleFavorite(
                                widget.gameId, tokenData.name);
                            setState(() {
                              if (isFavorite) {
                                currentFavorites.remove(tokenData.name);
                              } else {
                                currentFavorites.add(tokenData.name);
                              }
                            });
                            widget.onFavoriteToggled(
                                tokenData.name, List.from(currentFavorites));
                          },
                          child: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            color: isFavorite ? Colors.amber : Colors.grey,
                          ),
                        ),
                        title: Text(tokenData.name),
                        subtitle: Text(
                          _getCategoryLabel(tokenData.category),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: alreadyAdded
                            ? Icon(Icons.check, color: Colors.green)
                            : Icon(Icons.add_circle_outline),
                        onTap: () {
                          if (!alreadyAdded) {
                            widget.onTokenAdded(tokenData);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}