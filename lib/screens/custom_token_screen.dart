import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/token_library.dart';
import '../data/token_preferences.dart';
import '../data/hero_library.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CustomTokenScreen extends StatefulWidget {
  final String currentGame;
  const CustomTokenScreen({super.key, required this.currentGame});

  @override
  State<CustomTokenScreen> createState() => _CustomTokenScreenState();
}

class _CustomTokenScreenState extends State<CustomTokenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TokenData> customTokens = [];
  List<Map<String, dynamic>> customHeroes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tokens = await TokenPreferences.getCustomTokens(widget.currentGame);
    final heroes = await _loadCustomHeroes();
    setState(() {
      customTokens = tokens;
      customHeroes = heroes;
    });
  }

  Future<List<Map<String, dynamic>>> _loadCustomHeroes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('custom_heroes') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _saveCustomHeroes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_heroes', jsonEncode(customHeroes));
  }

  Future<String?> _pickAndSaveImage(String prefix) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final XFile? image = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (image == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = p.join(dir.path, 'custom_images', fileName);
    await Directory(p.dirname(savedPath)).create(recursive: true);
    await File(image.path).copy(savedPath);
    return savedPath;
  }

  // --- Custom Hero ---
  void _showAddHeroDialog() {
    final nameController = TextEditingController();
    HeroClass selectedClass = HeroClass.warrior;
    HeroTalent selectedTalent = HeroTalent.none;
    String? imagePath;

    final classNames = {
      HeroClass.brute: 'Brute',
      HeroClass.guardian: 'Guardian',
      HeroClass.illusionist: 'Illusionist',
      HeroClass.mechanologist: 'Mechanologist',
      HeroClass.merchant: 'Merchant',
      HeroClass.ninja: 'Ninja',
      HeroClass.ranger: 'Ranger',
      HeroClass.runeblade: 'Runeblade',
      HeroClass.warrior: 'Warrior',
      HeroClass.wizard: 'Wizard',
      HeroClass.assassin: 'Assassin',
      HeroClass.bard: 'Bard',
      HeroClass.necromancer: 'Necromancer',
      HeroClass.shapeshifter: 'Shapeshifter',
      HeroClass.adjudicator: 'Adjudicator',
      HeroClass.generic: 'Generic',
    };

    final talentNames = {
      HeroTalent.none: 'None',
      HeroTalent.draconic: 'Draconic',
      HeroTalent.earth: 'Earth',
      HeroTalent.elemental: 'Elemental',
      HeroTalent.ice: 'Ice',
      HeroTalent.light: 'Light',
      HeroTalent.lightning: 'Lightning',
      HeroTalent.shadow: 'Shadow',
      HeroTalent.royal: 'Royal',
      HeroTalent.mystic: 'Mystic',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Custom Hero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Hero Name', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<HeroClass>(
                  initialValue: selectedClass,
                  decoration: InputDecoration(labelText: 'Class', border: OutlineInputBorder()),
                  items: classNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) { if (val != null) setDialogState(() { selectedClass = val; }); },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<HeroTalent>(
                  initialValue: selectedTalent,
                  decoration: InputDecoration(labelText: 'Talent', border: OutlineInputBorder()),
                  items: talentNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) { if (val != null) setDialogState(() { selectedTalent = val; }); },
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final path = await _pickAndSaveImage('hero');
                    if (path != null) setDialogState(() { imagePath = path; });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(File(imagePath!), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final id = 'custom_${nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
                final heroMap = {
                  'id': id,
                  'name': nameController.text.trim(),
                  'heroClass': selectedClass.index,
                  'talent': selectedTalent.index,
                  'imagePath': imagePath,
                };
                setState(() { customHeroes.add(heroMap); });
                _saveCustomHeroes();
                Navigator.pop(ctx);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCustomHero(int index) {
    final hero = customHeroes[index];
    if (hero['imagePath'] != null) {
      final file = File(hero['imagePath']);
      if (file.existsSync()) file.deleteSync();
    }
    setState(() { customHeroes.removeAt(index); });
    _saveCustomHeroes();
  }

  // --- Custom Token ---
  void _showAddTokenDialog() {
    final nameController = TextEditingController();
    TokenCategory selectedCategory = TokenCategory.boonAura;
    DestroyTrigger? selectedTrigger;
    String? imagePath;

    final catNames = {
      TokenCategory.boonAura: 'Buff',
      TokenCategory.debuffAura: 'Debuff',
      TokenCategory.item: 'Item',
      TokenCategory.ally: 'Ally',
    };

    final triggerNames = {
      null: 'None (Manual)',
      DestroyTrigger.startOfYourTurn: 'Start of Your Turn',
      DestroyTrigger.startOfOpponentTurn: 'Start of Opponent Turn',
      DestroyTrigger.beginningOfActionPhase: 'Beginning of Action Phase',
      DestroyTrigger.beginningOfEndPhase: 'Beginning of End Phase',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Custom Token'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Token Name', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<TokenCategory>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: catNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (val) { if (val != null) setDialogState(() { selectedCategory = val; }); },
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<DestroyTrigger?>(
                  initialValue: selectedTrigger,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: 'Destroy Trigger', border: OutlineInputBorder()),
                  items: triggerNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (val) { setDialogState(() { selectedTrigger = val; }); },
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final path = await _pickAndSaveImage('token');
                    if (path != null) setDialogState(() { imagePath = path; });
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(File(imagePath!), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('Add Photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                final token = TokenData(
                  name: nameController.text.trim(),
                  category: selectedCategory,
                  destroyTrigger: selectedTrigger,
                  customImagePath: imagePath,
                );
                setState(() { customTokens.add(token); });
                TokenPreferences.addCustomToken(widget.currentGame, token);
                Navigator.pop(ctx);
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCustomToken(int index) {
    final tokenName = customTokens[index].name;
    setState(() { customTokens.removeAt(index); });
    TokenPreferences.removeCustomToken(widget.currentGame, tokenName);
  }

  @override
  Widget build(BuildContext context) {
    final classNames = {
      HeroClass.brute: 'Brute', HeroClass.guardian: 'Guardian', HeroClass.illusionist: 'Illusionist',
      HeroClass.mechanologist: 'Mechanologist', HeroClass.merchant: 'Merchant', HeroClass.ninja: 'Ninja',
      HeroClass.ranger: 'Ranger', HeroClass.runeblade: 'Runeblade', HeroClass.warrior: 'Warrior',
      HeroClass.wizard: 'Wizard', HeroClass.assassin: 'Assassin', HeroClass.bard: 'Bard',
      HeroClass.necromancer: 'Necromancer', HeroClass.shapeshifter: 'Shapeshifter',
      HeroClass.adjudicator: 'Adjudicator', HeroClass.generic: 'Generic',
    };

    final catNames = {
      TokenCategory.boonAura: 'Buff', TokenCategory.debuffAura: 'Debuff',
      TokenCategory.item: 'Item', TokenCategory.ally: 'Ally',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Library'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Custom Heroes'),
            Tab(text: 'Custom Tokens'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddHeroDialog();
          } else {
            _showAddTokenDialog();
          }
        },
        child: Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Custom Heroes Tab ---
          customHeroes.isEmpty
              ? Center(child: Text('No custom heroes yet.\nTap + to add one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: customHeroes.length,
                  itemBuilder: (context, index) {
                    final hero = customHeroes[index];
                    final heroClassName = classNames[HeroClass.values[hero['heroClass'] ?? 0]] ?? 'Unknown';
                    return Card(
                      child: ListTile(
                        leading: hero['imagePath'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(File(hero['imagePath']), width: 48, height: 48, fit: BoxFit.cover),
                              )
                            : Container(width: 48, height: 48, color: Colors.grey[800], child: Icon(Icons.person, color: Colors.grey)),
                        title: Text(hero['name'] ?? 'Unknown'),
                        subtitle: Text(heroClassName),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(context: context, builder: (ctx) => AlertDialog(
                              title: Text('Delete Hero'),
                              content: Text('Delete ${hero['name']}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                                TextButton(onPressed: () { Navigator.pop(ctx); _deleteCustomHero(index); }, child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ));
                          },
                        ),
                      ),
                    );
                  },
                ),

          // --- Custom Tokens Tab ---
          customTokens.isEmpty
              ? Center(child: Text('No custom tokens yet.\nTap + to add one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: customTokens.length,
                  itemBuilder: (context, index) {
                    final token = customTokens[index];
                    return Card(
                      child: ListTile(
                        leading: token.customImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(File(token.customImagePath!), width: 48, height: 48, fit: BoxFit.cover),
                              )
                            : Container(width: 48, height: 48, color: Colors.grey[800], child: Icon(Icons.token, color: Colors.grey)),
                        title: Text(token.name),
                        subtitle: Text(catNames[token.category] ?? 'Unknown'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            showDialog(context: context, builder: (ctx) => AlertDialog(
                              title: Text('Delete Token'),
                              content: Text('Delete ${token.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
                                TextButton(onPressed: () { Navigator.pop(ctx); _deleteCustomToken(index); }, child: Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ));
                          },
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}