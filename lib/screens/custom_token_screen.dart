import 'package:flutter/material.dart';
import '../data/token_preferences.dart';
import '../data/token_library.dart';

class CustomTokenScreen extends StatefulWidget {
  final String currentGame;

  CustomTokenScreen({required this.currentGame});

  @override
  _CustomTokenScreenState createState() => _CustomTokenScreenState();
}

class _CustomTokenScreenState extends State<CustomTokenScreen> {
  List<TokenData> customTokens = [];
  String selectedGame = '';

  final List<Map<String, String>> availableGames = [
    {'id': 'fab', 'name': 'Flesh and Blood'},
    {'id': 'mtg', 'name': 'Magic: The Gathering'},
  ];

  final Map<TokenCategory, String> categoryNames = {
    TokenCategory.ally: 'Ally',
    TokenCategory.item: 'Item',
    TokenCategory.boonAura: 'Boon Aura',
    TokenCategory.debuffAura: 'Debuff Aura',
  };

  final Map<DestroyTrigger, String> triggerNames = {
    DestroyTrigger.startOfYourTurn: 'Start of your turn',
    DestroyTrigger.startOfOpponentTurn: "Start of opponent's turn",
    DestroyTrigger.beginningOfActionPhase: 'Beginning of action phase',
    DestroyTrigger.beginningOfEndPhase: 'Beginning of end phase',
  };

  @override
  void initState() {
    super.initState();
    selectedGame = widget.currentGame.isEmpty ? 'fab' : widget.currentGame;
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final tokens = await TokenPreferences.getCustomTokensFull(selectedGame);
    setState(() {
      customTokens = tokens;
    });
  }

  String _getSubtitle(TokenData token) {
    String subtitle = categoryNames[token.category] ?? 'Unknown';
    if (token.category == TokenCategory.ally && token.health != null) {
      subtitle += ' • ${token.health} HP';
    }
    if (token.destroyTrigger != null) {
      subtitle += ' • ${triggerNames[token.destroyTrigger]}';
    }
    return subtitle;
  }

  void _showEditDialog(int index) {
    final token = customTokens[index];
    final nameController = TextEditingController(text: token.name);
    final healthController = TextEditingController(
      text: token.health?.toString() ?? '',
    );
    TokenCategory selectedCategory = token.category;
    DestroyTrigger? selectedTrigger = token.destroyTrigger;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Token'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(hintText: 'Token name'),
                    ),
                    SizedBox(height: 16),
                    Text('Category'),
                    SizedBox(height: 8),
                    DropdownButton<TokenCategory>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: TokenCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(categoryNames[cat] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (TokenCategory? value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                            if (value != TokenCategory.boonAura &&
                                value != TokenCategory.debuffAura) {
                              selectedTrigger = null;
                            }
                            if (value != TokenCategory.ally) {
                              healthController.clear();
                            }
                          });
                        }
                      },
                    ),
                    if (selectedCategory == TokenCategory.ally) ...[
                      SizedBox(height: 16),
                      Text('Health'),
                      SizedBox(height: 8),
                      TextField(
                        controller: healthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Health value'),
                      ),
                    ],
                    if (selectedCategory == TokenCategory.boonAura ||
                        selectedCategory == TokenCategory.debuffAura) ...[
                      SizedBox(height: 16),
                      Text('Auto-destroy'),
                      SizedBox(height: 8),
                      DropdownButton<DestroyTrigger?>(
                        value: selectedTrigger,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('None (manual only)'),
                          ),
                          ...DestroyTrigger.values.map((trigger) {
                            return DropdownMenuItem(
                              value: trigger,
                              child: Text(triggerNames[trigger] ?? ''),
                            );
                          }),
                        ],
                        onChanged: (DestroyTrigger? value) {
                          setDialogState(() {
                            selectedTrigger = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final health = int.tryParse(healthController.text);

                    if (newName.isNotEmpty) {
                      if (selectedCategory == TokenCategory.ally &&
                          (health == null || health <= 0)) {
                        return;
                      }

                      await TokenPreferences.removeCustomToken(
                          selectedGame, token.name);

                      final newToken = TokenData(
                        name: newName,
                        category: selectedCategory,
                        destroyTrigger: selectedTrigger,
                        health: selectedCategory == TokenCategory.ally
                            ? health
                            : null,
                      );

                      await TokenPreferences.addCustomTokenFull(
                          selectedGame, newToken);
                      await TokenPreferences.addCustomToken(
                          selectedGame, newName);
                      await _loadTokens();
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Token'),
          content: Text('Remove "${customTokens[index].name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await TokenPreferences.removeCustomToken(
                    selectedGame, customTokens[index].name);
                await _loadTokens();
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final healthController = TextEditingController();
    TokenCategory selectedCategory = TokenCategory.boonAura;
    DestroyTrigger? selectedTrigger;

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
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(hintText: 'Token name'),
                    ),
                    SizedBox(height: 16),
                    Text('Category'),
                    SizedBox(height: 8),
                    DropdownButton<TokenCategory>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: TokenCategory.values.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(categoryNames[cat] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (TokenCategory? value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                            if (value != TokenCategory.boonAura &&
                                value != TokenCategory.debuffAura) {
                              selectedTrigger = null;
                            }
                            if (value != TokenCategory.ally) {
                              healthController.clear();
                            }
                          });
                        }
                      },
                    ),
                    if (selectedCategory == TokenCategory.ally) ...[
                      SizedBox(height: 16),
                      Text('Health'),
                      SizedBox(height: 8),
                      TextField(
                        controller: healthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Health value'),
                      ),
                    ],
                    if (selectedCategory == TokenCategory.boonAura ||
                        selectedCategory == TokenCategory.debuffAura) ...[
                      SizedBox(height: 16),
                      Text('Auto-destroy'),
                      SizedBox(height: 8),
                      DropdownButton<DestroyTrigger?>(
                        value: selectedTrigger,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text('None (manual only)'),
                          ),
                          ...DestroyTrigger.values.map((trigger) {
                            return DropdownMenuItem(
                              value: trigger,
                              child: Text(triggerNames[trigger] ?? ''),
                            );
                          }),
                        ],
                        onChanged: (DestroyTrigger? value) {
                          setDialogState(() {
                            selectedTrigger = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final health = int.tryParse(healthController.text);

                    if (name.isNotEmpty &&
                        !customTokens.any((t) => t.name == name)) {
                      if (selectedCategory == TokenCategory.ally &&
                          (health == null || health <= 0)) {
                        return;
                      }

                      final newToken = TokenData(
                        name: name,
                        category: selectedCategory,
                        destroyTrigger: selectedTrigger,
                        health: selectedCategory == TokenCategory.ally
                            ? health
                            : null,
                      );

                      await TokenPreferences.addCustomTokenFull(
                          selectedGame, newToken);
                      await TokenPreferences.addCustomToken(
                          selectedGame, name);
                      await _loadTokens();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Custom Tokens'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: Icon(Icons.add),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Game',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedGame,
                isExpanded: true,
                underline: SizedBox(),
                items: availableGames.map((game) {
                  return DropdownMenuItem(
                    value: game['id'],
                    child: Text(
                      game['name']!,
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }).toList(),
                onChanged: (String? newGame) {
                  if (newGame != null) {
                    setState(() {
                      selectedGame = newGame;
                    });
                    _loadTokens();
                  }
                },
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Custom Tokens',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: customTokens.isEmpty
                  ? Center(
                      child: Text(
                        'No custom tokens for this game',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: customTokens.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(customTokens[index].name),
                          subtitle: Text(
                            _getSubtitle(customTokens[index]),
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}