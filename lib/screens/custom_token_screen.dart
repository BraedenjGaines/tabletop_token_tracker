import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/custom_hero_repository.dart';
import '../data/token_library.dart';
import '../data/token_preferences.dart';
import '../data/hero_library.dart';
import 'widgets/custom_detail_view.dart';

class CustomTokenScreen extends StatefulWidget {
  const CustomTokenScreen({super.key});

  @override
  State<CustomTokenScreen> createState() => _CustomTokenScreenState();
}

class _CustomTokenScreenState extends State<CustomTokenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TokenData> customTokens = [];
  List<HeroData> customHeroes = [];
  final ImagePicker _picker = ImagePicker();

  /// Per-tab search query. Index 0 is heroes, 1 is tokens.
  final List<String> _searchQuery = ['', ''];
  late final List<TextEditingController> _searchControllers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  static const Map<HeroClass, String> _classNames = {
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

  static const Map<HeroTalent, String> _talentNames = {
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

  static const Map<TokenCategory, String> _catNames = {
    TokenCategory.ally: 'Ally',
    TokenCategory.aura: 'Aura',
    TokenCategory.item: 'Item',
    TokenCategory.genericToken: 'Generic Token',
    TokenCategory.landmark: 'Landmark',
  };

  static const Map<AuraType, String> _auraTypeNames = {
    AuraType.buff: 'Buff',
    AuraType.debuff: 'Debuff',
  };

  static const Map<DestroyTrigger?, String> _triggerNames = {
    null: 'None (Manual)',
    DestroyTrigger.startOfYourTurn: 'Start of Your Turn',
    DestroyTrigger.startOfOpponentTurn: 'Start of Opponent Turn',
    DestroyTrigger.beginningOfActionPhase: 'Beginning of Action Phase',
    DestroyTrigger.beginningOfEndPhase: 'Beginning of End Phase',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchControllers = List.generate(2, (_) => TextEditingController());
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in _searchControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final tokens = await TokenPreferences.getCustomTokens();
    final heroes = await CustomHeroRepository.loadAll();
    setState(() {
      customTokens = tokens;
      customHeroes = heroes;
    });
  }

  Future<String?> _pickAndSaveImage(String prefix) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = p.join(dir.path, 'custom_images', fileName);
    await Directory(p.dirname(savedPath)).create(recursive: true);
    await File(image.path).copy(savedPath);
    return savedPath;
  }

  // --- Custom Hero ---

  void _showAddHeroDialog({HeroData? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final intellectController = TextEditingController(
      text: existing != null && existing.intellect > 0
          ? existing.intellect.toString()
          : '',
    );
    final healthController = TextEditingController(
      text: existing != null && existing.health > 0
          ? existing.health.toString()
          : '',
    );
    final cardTextController = TextEditingController(
      text: existing?.cardText ?? '',
    );
    HeroClass selectedClass = existing?.heroClass ?? HeroClass.warrior;
    final selectedTalents = <HeroTalent>{
      ...?existing?.talents.where((t) => t != HeroTalent.none),
    };
    String? imagePath = existing?.customImagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Custom Hero' : 'Add Custom Hero'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Hero Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HeroClass>(
                  initialValue: selectedClass,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: _classNames.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedClass = val);
                  },
                ),
                const SizedBox(height: 12),
                _TalentMultiSelect(
                  talentNames: _talentNames,
                  selected: selectedTalents,
                  onChanged: (next) =>
                      setDialogState(() {
                        selectedTalents
                          ..clear()
                          ..addAll(next);
                      }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: intellectController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Intellect',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: healthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Life',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ImagePickerArea(
                  imagePath: imagePath,
                  onPick: () async {
                    final path = await _pickAndSaveImage('hero');
                    if (path != null) setDialogState(() => imagePath = path);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cardTextController,
                  maxLines: 4,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Card Text',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final talents = selectedTalents.isEmpty
                    ? <HeroTalent>[HeroTalent.none]
                    : selectedTalents.toList();
                // Preserve the existing id when editing so persisted records
                // match. Generate a new id only when adding.
                final id = isEditing
                    ? existing.id
                    : 'custom_${nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
                final hero = HeroData(
                  id: id,
                  name: nameController.text.trim(),
                  heroClass: selectedClass,
                  talents: talents,
                  isYoung: false,
                  intellect: int.tryParse(intellectController.text) ?? 0,
                  health: int.tryParse(healthController.text) ?? 0,
                  customImagePath: imagePath,
                  cardText: cardTextController.text.trim(),
                );
                final navigator = Navigator.of(ctx);
                final updated = isEditing
                    ? await CustomHeroRepository.update(hero)
                    : await CustomHeroRepository.add(hero);
                if (!mounted) return;
                setState(() => customHeroes = updated);
                navigator.pop();
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCustomHero(int index) async {
    final hero = customHeroes[index];
    if (hero.customImagePath != null) {
      final file = File(hero.customImagePath!);
      if (file.existsSync()) file.deleteSync();
    }
    final updated = await CustomHeroRepository.removeById(hero.id);
    if (mounted) setState(() => customHeroes = updated);
  }

  // --- Custom Token ---

  void _showAddTokenDialog({TokenData? existing}) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final healthController = TextEditingController(
      text: existing?.health?.toString() ?? '',
    );
    final cardTextController = TextEditingController(
      text: existing?.cardText ?? '',
    );
    TokenCategory selectedCategory = existing?.category ?? TokenCategory.aura;
    AuraType selectedAuraType = existing?.auraType ?? AuraType.buff;
    DestroyTrigger? selectedTrigger = existing?.destroyTrigger;
    String? imagePath = existing?.customImagePath;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final showAuraFields = selectedCategory == TokenCategory.aura;
          final showHealthField = selectedCategory == TokenCategory.ally;

          return AlertDialog(
            title: Text(isEditing ? 'Edit Custom Token' : 'Add Custom Token'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Token Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TokenCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Sub-Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _catNames.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedCategory = val;
                          // Clear conditionally-relevant fields when switching.
                          if (val != TokenCategory.aura) {
                            selectedTrigger = null;
                          }
                          if (val != TokenCategory.ally) {
                            healthController.clear();
                          }
                        });
                      }
                    },
                  ),
                  if (showAuraFields) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AuraType>(
                      initialValue: selectedAuraType,
                      decoration: const InputDecoration(
                        labelText: 'Aura Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _auraTypeNames.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedAuraType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DestroyTrigger?>(
                      initialValue: selectedTrigger,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Destroy Trigger',
                        border: OutlineInputBorder(),
                      ),
                      items: _triggerNames.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedTrigger = val),
                    ),
                  ],
                  if (showHealthField) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: healthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Life',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _ImagePickerArea(
                    imagePath: imagePath,
                    onPick: () async {
                      final path = await _pickAndSaveImage('token');
                      if (path != null) setDialogState(() => imagePath = path);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cardTextController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Card Text',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  final token = TokenData(
                    name: nameController.text.trim(),
                    category: selectedCategory,
                    auraType: selectedCategory == TokenCategory.aura
                        ? selectedAuraType
                        : null,
                    destroyTrigger: selectedCategory == TokenCategory.aura
                        ? selectedTrigger
                        : null,
                    health: selectedCategory == TokenCategory.ally
                        ? int.tryParse(healthController.text)
                        : null,
                    customImagePath: imagePath,
                    cardText: cardTextController.text.trim(),
                  );
                  final navigator = Navigator.of(ctx);
                  if (isEditing) {
                    await TokenPreferences.updateCustomToken(
                      existing.name,
                      token,
                    );
                    if (!mounted) return;
                    setState(() {
                      final i = customTokens
                          .indexWhere((t) => t.name == existing.name);
                      if (i >= 0) {
                        customTokens[i] = token;
                      } else {
                        customTokens.add(token);
                      }
                    });
                  } else {
                    await TokenPreferences.addCustomToken(token);
                    if (!mounted) return;
                    setState(() => customTokens.add(token));
                  }
                  navigator.pop();
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteCustomToken(int index) {
    final tokenName = customTokens[index].name;
    setState(() => customTokens.removeAt(index));
    TokenPreferences.removeCustomToken(tokenName);
  }

  /// Subtitle text for token list rows. Includes aura sub-type when relevant.
  String _tokenSubtitle(TokenData token) {
    final base = _catNames[token.category] ?? 'Unknown';
    if (token.category == TokenCategory.aura && token.auraType != null) {
      return '$base · ${_auraTypeNames[token.auraType]}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Library'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddHeroDialog();
          } else {
            _showAddTokenDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSegmentedSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPanelContent(
                  isEmpty: customHeroes.isEmpty,
                  emptyText: 'No custom heroes yet.\nTap + to add one.',
                  list: _buildHeroList(),
                ),
                _buildPanelContent(
                  isEmpty: customTokens.isEmpty,
                  emptyText: 'No custom tokens yet.\nTap + to add one.',
                  list: _buildTokenList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final tabIndex = _tabController.index;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            key: ValueKey('search_$tabIndex'),
            controller: _searchControllers[tabIndex],
            onChanged: (q) => setState(() => _searchQuery[tabIndex] = q),
            decoration: InputDecoration(
              hintText: 'Search by name',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentedSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Custom Heroes')),
              ButtonSegment(value: 1, label: Text('Custom Tokens')),
            ],
            selected: {_tabController.index},
            onSelectionChanged: (set) {
              if (set.isEmpty) return;
              setState(() {
                _tabController.animateTo(set.first);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildPanelContent({
    required bool isEmpty,
    required String emptyText,
    required Widget list,
  }) {
    if (isEmpty) {
      return Center(
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return list;
  }

  Widget _buildHeroList() {
    final query = _searchQuery[0].toLowerCase();
    final filtered = query.isEmpty
        ? customHeroes
        : customHeroes
            .where((h) => h.name.toLowerCase().contains(query))
            .toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'No custom heroes yet.\nTap + to add one.'
              : 'No heroes match.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final hero = filtered[index];
        final heroClassName = _classNames[hero.heroClass] ?? 'Unknown';
        return Card(
          child: ListTile(
            leading: hero.customImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(hero.customImagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
            title: Text(hero.name),
            subtitle: Text(heroClassName),
            onTap: () => _openHeroDetail(hero),
          ),
        );
      },
    );
  }

  Widget _buildTokenList() {
    final query = _searchQuery[1].toLowerCase();
    final filtered = query.isEmpty
        ? customTokens
        : customTokens
            .where((t) => t.name.toLowerCase().contains(query))
            .toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty
              ? 'No custom tokens yet.\nTap + to add one.'
              : 'No tokens match.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final token = filtered[index];
        return Card(
          child: ListTile(
            leading: token.customImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(token.customImagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: const Icon(Icons.token, color: Colors.grey),
                  ),
            title: Text(token.name),
            subtitle: Text(_tokenSubtitle(token)),
            onTap: () => _openTokenDetail(token),
          ),
        );
      },
    );
  }

  void _openHeroDetail(HeroData hero) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomDetailView(
          hero: hero,
          onEdit: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            // Reopen the add-hero dialog in edit mode. The dialog handles
            // persistence and updates the list. After save, the detail view
            // is gone so the user sees the refreshed list.
            _showAddHeroDialog(existing: hero);
          },
          onDelete: () async {
            final navigator = Navigator.of(context);
            final index = customHeroes.indexWhere((h) => h.id == hero.id);
            if (index < 0) return;
            await _deleteCustomHero(index);
            if (navigator.canPop()) navigator.pop();
          },
        ),
      ),
    );
  }

  void _openTokenDetail(TokenData token) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomDetailView(
          token: token,
          onEdit: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            _showAddTokenDialog(existing: token);
          },
          onDelete: () {
            final navigator = Navigator.of(context);
            final index = customTokens.indexWhere((t) => t.name == token.name);
            if (index < 0) return;
            _deleteCustomToken(index);
            if (navigator.canPop()) navigator.pop();
          },
        ),
      ),
    );
  }
}

/// Multi-select talent picker, rendered as a labeled wrap of FilterChips.
/// Excludes [HeroTalent.none] from the user-facing options — empty selection
/// is the natural way to indicate "no talents" and gets persisted as
/// `[HeroTalent.none]` for storage compatibility.
class _TalentMultiSelect extends StatelessWidget {
  final Map<HeroTalent, String> talentNames;
  final Set<HeroTalent> selected;
  final ValueChanged<Set<HeroTalent>> onChanged;

  const _TalentMultiSelect({
    required this.talentNames,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = HeroTalent.values
        .where((t) => t != HeroTalent.none)
        .toList();

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Talents',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final t in options)
            FilterChip(
              label: Text(talentNames[t] ?? t.name),
              selected: selected.contains(t),
              showCheckmark: false,
              onSelected: (active) {
                final next = Set<HeroTalent>.from(selected);
                active ? next.add(t) : next.remove(t);
                onChanged(next);
              },
            ),
        ],
      ),
    );
  }
}

class _ImagePickerArea extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;

  const _ImagePickerArea({required this.imagePath, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
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
                children: const [
                  Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Add Photo', style: TextStyle(color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}