enum TokenCategory { ally, aura, item, genericToken, landmark }

enum AuraType { buff, debuff }

enum DestroyTrigger {
  startOfYourTurn,
  startOfOpponentTurn,
  beginningOfActionPhase,
  beginningOfEndPhase,
}

class TokenData {
  final String name;
  final TokenCategory category;
  final AuraType? auraType; // Set only when category is aura.
  final DestroyTrigger? destroyTrigger; // Set only when category is aura.
  final int? health; // Set only when category is ally.
  final String? customImagePath;
  /// Free-form rules text users can attach to a custom token. Empty for
  /// stock tokens from the bundled library.
  final String cardText;

  TokenData({
    required this.name,
    required this.category,
    this.auraType,
    this.destroyTrigger,
    this.health,
    this.customImagePath,
    this.cardText = '',
  });

  String get id => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), '_');

  String get cardArtPath => 'assets/images/tokens/${id}_token.jpg';
}

/// Static library of FaB tokens. Auras have boon/debuff distinction via the
/// [auraType] field. Items, allies, generic tokens, and landmarks have no
/// such sub-categorization.
final List<TokenData> tokenLibrary = [
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

  // Buff Auras
  TokenData(name: 'Agility', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.startOfYourTurn),
  TokenData(name: 'Ash', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Bait', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Confidence', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.startOfYourTurn),
  TokenData(name: 'Courage', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Eloquence', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Embodiment of Earth', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.beginningOfActionPhase),
  TokenData(name: 'Embodiment of Lightning', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Fealty', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Flurry', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Lightning Flow', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Might', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.startOfYourTurn),
  TokenData(name: 'Ponder', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
  TokenData(name: 'Quicken', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Runechant', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Seismic Surge', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.beginningOfActionPhase),
  TokenData(name: 'Sigil of Fate', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.beginningOfActionPhase),
  TokenData(name: 'Soul Shackle', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Spectral Shield', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Spellbane Aegis', category: TokenCategory.aura, auraType: AuraType.buff),
  TokenData(name: 'Toughness', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.startOfOpponentTurn),
  TokenData(name: 'Vigor', category: TokenCategory.aura, auraType: AuraType.buff, destroyTrigger: DestroyTrigger.startOfYourTurn),
  TokenData(name: 'Zen State', category: TokenCategory.aura, auraType: AuraType.buff),

  // Debuff Auras
  TokenData(name: 'Bloodrot Pox', category: TokenCategory.aura, auraType: AuraType.debuff, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
  TokenData(name: 'Frailty', category: TokenCategory.aura, auraType: AuraType.debuff, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
  TokenData(name: 'Frostbite', category: TokenCategory.aura, auraType: AuraType.debuff, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
  TokenData(name: 'Inertia', category: TokenCategory.aura, auraType: AuraType.debuff, destroyTrigger: DestroyTrigger.beginningOfEndPhase),
  TokenData(name: 'Marked', category: TokenCategory.aura, auraType: AuraType.debuff),
];

/// User-facing token display buckets. Used by the play screen UI to group
/// tokens. Differs from [TokenCategory] in that auras are split into Buff
/// and Debuff buckets based on auraType, and the new categories
/// (genericToken, landmark) get their own buckets.
enum TokenDisplayBucket {
  buffAura,
  debuffAura,
  item,
  ally,
  genericToken,
  landmark,
}

/// Resolve display bucket from category + aura type. Single source of truth
/// shared between [TokenData] and [ActiveToken] via their respective
/// extensions.
TokenDisplayBucket resolveDisplayBucket(
  TokenCategory category,
  AuraType? auraType,
) {
  switch (category) {
    case TokenCategory.aura:
      // An aura without an explicit type defaults to buff for legacy safety.
      return auraType == AuraType.debuff
          ? TokenDisplayBucket.debuffAura
          : TokenDisplayBucket.buffAura;
    case TokenCategory.ally:
      return TokenDisplayBucket.ally;
    case TokenCategory.item:
      return TokenDisplayBucket.item;
    case TokenCategory.genericToken:
      return TokenDisplayBucket.genericToken;
    case TokenCategory.landmark:
      return TokenDisplayBucket.landmark;
  }
}

extension TokenDataDisplayBucket on TokenData {
  TokenDisplayBucket get displayBucket =>
      resolveDisplayBucket(category, auraType);
}