import 'package:flutter/material.dart';
import '../data/token_preferences.dart';

class CustomTokenScreen extends StatefulWidget {
  final String currentGame;

  CustomTokenScreen({required this.currentGame});

  @override
  _CustomTokenScreenState createState() => _CustomTokenScreenState();
}

class _CustomTokenScreenState extends State<CustomTokenScreen> {
  List<String> customTokens = [];
  String selectedGame = '';

  final List<Map<String, String>> availableGames = [
    {'id': 'fab', 'name': 'Flesh and Blood'},
    {'id': 'mtg', 'name': 'Magic: The Gathering'},
  ];

  @override
  void initState() {
    super.initState();
    selectedGame = widget.currentGame.isEmpty ? 'fab' : widget.currentGame;
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final tokens = await TokenPreferences.getCustomTokens(selectedGame);
    setState(() {
      customTokens = tokens;
    });
  }

  void _showEditDialog(int index) {
    final controller = TextEditingController(text: customTokens[index]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Token'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Token name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.dispose();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != customTokens[index]) {
                  await TokenPreferences.removeCustomToken(
                      selectedGame, customTokens[index]);
                  await TokenPreferences.addCustomToken(selectedGame, newName);
                  await _loadTokens();
                }
                Navigator.pop(context);
                controller.dispose();
              },
              child: Text('Save'),
            ),
          ],
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
          content: Text('Remove "${customTokens[index]}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await TokenPreferences.removeCustomToken(
                    selectedGame, customTokens[index]);
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
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Custom Token'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Token name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.dispose();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty && !customTokens.contains(name)) {
                  await TokenPreferences.addCustomToken(selectedGame, name);
                  await _loadTokens();
                }
                Navigator.pop(context);
                controller.dispose();
              },
              child: Text('Add'),
            ),
          ],
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
                          title: Text(customTokens[index]),
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