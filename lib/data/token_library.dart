enum TokenCategory { ally, item, boonAura, debuffAura }

enum DestroyTrigger {
  startOfYourTurn,
  startOfOpponentTurn,
  beginningOfActionPhase,
  beginningOfEndPhase,
}

class TokenData {
  final String name;
  final TokenCategory category;
  final DestroyTrigger? destroyTrigger;
  final int? health;
  final String? customImagePath;

  TokenData({
    required this.name,
    required this.category,
    this.destroyTrigger,
    this.health,
    this.customImagePath,
  });

  String get id => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), '_');
  String get cardArtPath => 'assets/images/tokens/${id}_token.jpg';
}

final Map<String, List<TokenData>> tokenLibrary = {
  'fab': [
    // Allies
    TokenData(name: 'Aether Ashwing', category: TokenCategory.ally, health: 1),
    TokenData(name: 'Blasmophet, the Soul Harvester', category: TokenCategory.ally, health: 6),
    TokenData(name: 'Cintari Sellsword', category: TokenCategory.ally, health: 2),
    TokenData(name: 'Nasreth, the Soul Harrower', category: TokenCategory.ally, health: 6),
    TokenData(name: 'Ursur, the Soul Reaper', category: TokenCategory.ally, health: 6),

    // Items
    TokenData(name: 'Copper', category: TokenCategory.item),
    TokenData(name: 'Diamond', category: TokenCategory.item),
    TokenData(name: 'Gold', category: TokenCategory.item),
    TokenData(name: 'Golden Cog', category: TokenCategory.item),
    TokenData(name: 'Goldkiss Rum', category: TokenCategory.item),
    TokenData(name: 'Hyper Driver', category: TokenCategory.item),
    TokenData(name: 'Silver', category: TokenCategory.item),

    // Boon Auras
    TokenData(name: 'Agility', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.startOfYourTurn),
    TokenData(name: 'Ash', category: TokenCategory.boonAura),
    TokenData(name: 'Bait', category: TokenCategory.boonAura),
    TokenData(name: 'Confidence', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.startOfYourTurn),
    TokenData(name: 'Courage', category: TokenCategory.boonAura),
    TokenData(name: 'Eloquence', category: TokenCategory.boonAura),
    TokenData(name: 'Embodiment of Earth', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.beginningOfActionPhase),
    TokenData(name: 'Embodiment of Lightning', category: TokenCategory.boonAura),
    TokenData(name: 'Fealty', category: TokenCategory.boonAura),
    TokenData(name: 'Flurry', category: TokenCategory.boonAura),
    TokenData(name: 'Lightning Flow', category: TokenCategory.boonAura),
    TokenData(name: 'Might', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.startOfYourTurn),
    TokenData(name: 'Ponder', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
    TokenData(name: 'Quicken', category: TokenCategory.boonAura),
    TokenData(name: 'Runechant', category: TokenCategory.boonAura),
    TokenData(name: 'Seismic Surge', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.beginningOfActionPhase),
    TokenData(name: 'Sigil of Fate', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.beginningOfActionPhase),
    TokenData(name: 'Soul Shackle', category: TokenCategory.boonAura),
    TokenData(name: 'Spectral Shield', category: TokenCategory.boonAura),
    TokenData(name: 'Spellbane Aegis', category: TokenCategory.boonAura),
    TokenData(name: 'Toughness', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.startOfOpponentTurn),
    TokenData(name: 'Vigor', category: TokenCategory.boonAura, destroyTrigger: DestroyTrigger.startOfYourTurn),
    TokenData(name: 'Zen State', category: TokenCategory.boonAura),

    // Debuff Auras
    TokenData(name: 'Bloodrot Pox', category: TokenCategory.debuffAura, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
    TokenData(name: 'Frailty', category: TokenCategory.debuffAura, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
    TokenData(name: 'Frostbite', category: TokenCategory.debuffAura, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
    TokenData(name: 'Inertia', category: TokenCategory.debuffAura, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
    TokenData(name: 'Marked', category: TokenCategory.debuffAura),
  ],
  'mtg': [],
};