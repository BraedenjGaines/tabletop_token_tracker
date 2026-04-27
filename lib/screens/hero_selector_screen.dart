import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/hero_library.dart';
import 'widgets/hero_image.dart';

class HeroSelectorScreen extends StatefulWidget {
  final String? currentHeroId;

  const HeroSelectorScreen({super.key, this.currentHeroId});

  @override
  State<HeroSelectorScreen> createState() => _HeroSelectorScreenState();
}

enum FilterTab { alphabetical, heroClass, talent, age }

class _HeroSelectorScreenState extends State<HeroSelectorScreen> {
  String searchQuery = '';
  final searchController = TextEditingController();
  FilterTab activeTab = FilterTab.alphabetical;
  FilterTab? expandedTab;

  final Set<HeroClass> selectedClasses = {};
  final Set<HeroTalent> selectedTalents = {};
  final Set<String> selectedAges = {};

  List<HeroData> customHeroesAsData = [];

  final Map<HeroClass, String> classNames = {
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

  final Map<HeroTalent, String> talentNames = {
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

  @override
  void initState() {
    super.initState();
    _loadCustomHeroes();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomHeroes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('custom_heroes') ?? '[]';
    final List<dynamic> list = jsonDecode(jsonStr);
    setState(() {
      customHeroesAsData = list.map((map) {
        return HeroData(
          id: map['id'] ?? 'custom_unknown',
          name: map['name'] ?? 'Unknown',
          heroClass: HeroClass.values[map['heroClass'] ?? 0],
          talents: [HeroTalent.values[map['talent'] ?? 0]],
          isYoung: false,
          intellect: 0,
          health: 0,
          customImagePath: map['imagePath'],
        );
      }).toList();
    });
  }

  String _heroSubtitle(HeroData hero) {
    final parts = <String>[classNames[hero.heroClass] ?? ''];
    for (final t in hero.talents) {
      if (t != HeroTalent.none) {
        parts.add(talentNames[t] ?? '');
      }
    }
    return parts.join(', ');
  }

  List<HeroData> _getFiltered() {
    var heroes = [...heroLibrary, ...customHeroesAsData];

    if (searchQuery.isNotEmpty) {
      heroes = heroes.where((h) =>
        h.displayName.toLowerCase().contains(searchQuery.toLowerCase()) ||
        classNames[h.heroClass]!.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    if (selectedClasses.isNotEmpty) {
      heroes = heroes.where((h) => selectedClasses.contains(h.heroClass)).toList();
    }

    if (selectedTalents.isNotEmpty) {
      heroes = heroes.where((h) => h.talents.any((t) => selectedTalents.contains(t))).toList();
    }

    if (selectedAges.isNotEmpty) {
      if (selectedAges.contains('Young') && !selectedAges.contains('Adult')) {
        heroes = heroes.where((h) => h.isYoung).toList();
      } else if (selectedAges.contains('Adult') && !selectedAges.contains('Young')) {
        heroes = heroes.where((h) => !h.isYoung).toList();
      }
    }

    switch (activeTab) {
      case FilterTab.alphabetical:
        heroes.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case FilterTab.heroClass:
        heroes.sort((a, b) {
          final classComp = classNames[a.heroClass]!.compareTo(classNames[b.heroClass]!);
          return classComp != 0 ? classComp : a.displayName.compareTo(b.displayName);
        });
        break;
      case FilterTab.talent:
        heroes.sort((a, b) {
          final aTalent = a.talents.first;
          final bTalent = b.talents.first;
          final talentComp = talentNames[aTalent]!.compareTo(talentNames[bTalent]!);
          return talentComp != 0 ? talentComp : a.displayName.compareTo(b.displayName);
        });
        break;
      case FilterTab.age:
        heroes.sort((a, b) {
          final ageComp = (a.isYoung ? 0 : 1).compareTo(b.isYoung ? 0 : 1);
          return ageComp != 0 ? ageComp : a.displayName.compareTo(b.displayName);
        });
        break;
    }

    return heroes;
  }

  void _onTabTap(FilterTab tab) {
    setState(() {
      activeTab = tab;
      if (expandedTab == tab) {
        expandedTab = null;
      } else if (tab != FilterTab.alphabetical) {
        expandedTab = tab;
      } else {
        expandedTab = null;
      }
    });
  }

  int get _activeFilterCount {
    return selectedClasses.length + selectedTalents.length + selectedAges.length;
  }

  Widget _buildFilterChips() {
    if (expandedTab == null) return SizedBox.shrink();

    List<Widget> chips = [];

    if (expandedTab == FilterTab.heroClass) {
      for (final entry in classNames.entries) {
        final selected = selectedClasses.contains(entry.key);
        chips.add(
          FilterChip(
            label: Text(entry.value, style: TextStyle(fontSize: 11)),
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              setState(() {
                selected ? selectedClasses.remove(entry.key) : selectedClasses.add(entry.key);
              });
            },
          ),
        );
      }
    } else if (expandedTab == FilterTab.talent) {
      for (final entry in talentNames.entries) {
        final selected = selectedTalents.contains(entry.key);
        chips.add(
          FilterChip(
            label: Text(entry.value, style: TextStyle(fontSize: 11)),
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              setState(() {
                selected ? selectedTalents.remove(entry.key) : selectedTalents.add(entry.key);
              });
            },
          ),
        );
      }
    } else if (expandedTab == FilterTab.age) {
      for (final age in ['Young', 'Adult']) {
        final selected = selectedAges.contains(age);
        chips.add(
          FilterChip(
            label: Text(age, style: TextStyle(fontSize: 11)),
            selected: selected,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              setState(() {
                selected ? selectedAges.remove(age) : selectedAges.add(age);
              });
            },
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: chips,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Hero'),
        centerTitle: true,
        actions: [
          if (_activeFilterCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  selectedClasses.clear();
                  selectedTalents.clear();
                  selectedAges.clear();
                });
              },
              child: Text('Clear', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: CustomScrollView(
          slivers: [
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search heroes...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, size: 18), onPressed: () { searchController.clear(); setState(() { searchQuery = ''; }); })
                      : null,
                  ),
                  onChanged: (value) => setState(() { searchQuery = value; }),
                ),
              ),
            ),
            // Filter tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SegmentedButton<FilterTab>(
                  showSelectedIcon: false,
                  multiSelectionEnabled: false,
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                  ),
                  segments: [
                    ButtonSegment(value: FilterTab.alphabetical, label: Text('A-Z')),
                    ButtonSegment(value: FilterTab.heroClass, label: Text('Class${selectedClasses.isNotEmpty ? ' (${selectedClasses.length})' : ''}')),
                    ButtonSegment(value: FilterTab.talent, label: Text('Talent${selectedTalents.isNotEmpty ? ' (${selectedTalents.length})' : ''}')),
                    ButtonSegment(value: FilterTab.age, label: Text('Age${selectedAges.isNotEmpty ? ' (${selectedAges.length})' : ''}')),
                  ],
                  selected: {activeTab},
                  onSelectionChanged: (s) => _onTabTap(s.first),
                ),
              ),
            ),
            // Filter chips
            SliverToBoxAdapter(child: _buildFilterChips()),
            // Hero count
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${filtered.length} heroes', style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'CormorantGaramond')),
                ),
              ),
            ),
            // Hero grid
            filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(child: Text('No heroes found', style: TextStyle(color: Colors.grey))),
                )
              : SliverPadding(
                  padding: EdgeInsets.all(12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hero = filtered[index];
                        final bool isSelected = hero.id == widget.currentHeroId;
                        final bool isCustom = hero.customImagePath != null;
                        return GestureDetector(
                          onTap: () => Navigator.pop(context, hero),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                ? Border.all(color: Colors.blue, width: 3)
                                : Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: isCustom
                                          ? Image.file(File(hero.customImagePath!), fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(color: Colors.grey[800], child: Center(child: Icon(Icons.person, size: 32, color: Colors.grey))))
                                          : HeroImage(hero: hero, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        hero.displayName,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _heroSubtitle(hero),
                                        style: TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'CormorantGaramond'),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}