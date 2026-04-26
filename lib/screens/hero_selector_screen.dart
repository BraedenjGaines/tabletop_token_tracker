import 'package:flutter/material.dart';
import '../data/hero_library.dart';
import 'widgets/hero_image.dart';

class HeroSelectorScreen extends StatefulWidget {
  final String? currentHeroId;

  const HeroSelectorScreen({super.key, this.currentHeroId});

  @override
  State<HeroSelectorScreen> createState() => _HeroSelectorScreenState();
}

enum SortMode { alphabetical, byClass, byTalent }

class _HeroSelectorScreenState extends State<HeroSelectorScreen> {
  String searchQuery = '';
  final searchController = TextEditingController();
  SortMode sortMode = SortMode.alphabetical;
  final Set<HeroClass> selectedClasses = {};
  final Set<HeroTalent> selectedTalents = {};
  bool? showYoungOnly;

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
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<HeroData> _getFiltered() {
    var heroes = List<HeroData>.from(heroLibrary);

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

    if (showYoungOnly == true) {
      heroes = heroes.where((h) => h.isYoung).toList();
    } else if (showYoungOnly == false) {
      heroes = heroes.where((h) => !h.isYoung).toList();
    }

    switch (sortMode) {
      case SortMode.alphabetical:
        heroes.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case SortMode.byClass:
        heroes.sort((a, b) {
          final classComp = classNames[a.heroClass]!.compareTo(classNames[b.heroClass]!);
          return classComp != 0 ? classComp : a.displayName.compareTo(b.displayName);
        });
        break;
      case SortMode.byTalent:
        heroes.sort((a, b) {
          final aTalent = a.talents.first;
          final bTalent = b.talents.first;
          final talentComp = talentNames[aTalent]!.compareTo(talentNames[bTalent]!);
          return talentComp != 0 ? talentComp : a.displayName.compareTo(b.displayName);
        });
        break;
    }

    return heroes;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Hero'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            // Search bar
            Padding(
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
            // Sort mode
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<SortMode>(
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8, horizontal: 4)),
                        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                      ),
                      segments: [
                        ButtonSegment(value: SortMode.alphabetical, label: Text('A-Z')),
                        ButtonSegment(value: SortMode.byClass, label: Text('Class')),
                        ButtonSegment(value: SortMode.byTalent, label: Text('Talent')),
                      ],
                      selected: {sortMode},
                      onSelectionChanged: (s) => setState(() { sortMode = s.first; }),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Young/Adult filter
                  PopupMenuButton<bool?>(
                    icon: Icon(Icons.filter_list, size: 22),
                    onSelected: (value) => setState(() { showYoungOnly = showYoungOnly == value ? null : value; }),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: true, child: Row(children: [
                        if (showYoungOnly == true) Icon(Icons.check, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Young only'),
                      ])),
                      PopupMenuItem(value: false, child: Row(children: [
                        if (showYoungOnly == false) Icon(Icons.check, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Adult only'),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
            // Hero count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${filtered.length} heroes', style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'CormorantGaramond')),
              ),
            ),
            // Hero grid
            Expanded(
              child: filtered.isEmpty
                ? Center(child: Text('No heroes found', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                    padding: EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final hero = filtered[index];
                      final bool isSelected = hero.id == widget.currentHeroId;
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
                                    child: HeroImage(hero: hero, fit: BoxFit.cover),
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
                                      '${classNames[hero.heroClass]}${hero.isYoung ? ' (Y)' : ''}',
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
                  ),
            ),
          ],
        ),
      ),
    );
  }
}