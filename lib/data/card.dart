/// One unique Flesh and Blood card entity (name + pitch combination).
///
/// Multiple printings of the same card are rolled up under [printings].
class CardData {
  final String uniqueId;
  final String name;
  final String color;
  final String pitch;
  final String cost;
  final String power;
  final String defense;
  final String health;
  final String intelligence;
  final String arcane;
  final List<String> types;
  final List<String> traits;
  final List<String> cardKeywords;
  final String functionalText;
  final String functionalTextPlain;
  final String typeText;
  final bool playedHorizontally;
  final FormatLegality legality;
  final List<CardPrinting> printings;

  CardData({
    required this.uniqueId,
    required this.name,
    required this.color,
    required this.pitch,
    required this.cost,
    required this.power,
    required this.defense,
    required this.health,
    required this.intelligence,
    required this.arcane,
    required this.types,
    required this.traits,
    required this.cardKeywords,
    required this.functionalText,
    required this.functionalTextPlain,
    required this.typeText,
    required this.playedHorizontally,
    required this.legality,
    required this.printings,
  });

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      uniqueId: json['unique_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '',
      pitch: json['pitch'] as String? ?? '',
      cost: json['cost'] as String? ?? '',
      power: json['power'] as String? ?? '',
      defense: json['defense'] as String? ?? '',
      health: json['health'] as String? ?? '',
      intelligence: json['intelligence'] as String? ?? '',
      arcane: json['arcane'] as String? ?? '',
      types: (json['types'] as List?)?.cast<String>() ?? const [],
      traits: (json['traits'] as List?)?.cast<String>() ?? const [],
      cardKeywords:
          (json['card_keywords'] as List?)?.cast<String>() ?? const [],
      functionalText: json['functional_text'] as String? ?? '',
      functionalTextPlain: json['functional_text_plain'] as String? ?? '',
      typeText: json['type_text'] as String? ?? '',
      playedHorizontally: json['played_horizontally'] as bool? ?? false,
      legality: FormatLegality.fromJson(json),
      printings: (json['printings'] as List?)
              ?.map((p) => CardPrinting.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// True if any of this card's types includes "Hero".
  bool get isHero => types.contains('Hero');
}

/// A single printing of a card. Multiple printings can share the same id but
/// differ by foiling, edition, etc.
class CardPrinting {
  final String id;
  final String setId;
  final String edition;
  final String foiling;
  final String rarity;
  final String imageUrl;
  final int imageRotationDegrees;
  final List<String> artVariations;

  CardPrinting({
    required this.id,
    required this.setId,
    required this.edition,
    required this.foiling,
    required this.rarity,
    required this.imageUrl,
    required this.imageRotationDegrees,
    required this.artVariations,
  });

  factory CardPrinting.fromJson(Map<String, dynamic> json) {
    return CardPrinting(
      id: json['id'] as String? ?? '',
      setId: json['set_id'] as String? ?? '',
      edition: json['edition'] as String? ?? '',
      foiling: json['foiling'] as String? ?? '',
      rarity: json['rarity'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      imageRotationDegrees: json['image_rotation_degrees'] as int? ?? 0,
      artVariations: (json['art_variations'] as List?)?.cast<String>() ?? const [],
    );
  }
}

/// Per-format legality and ban/suspension state.
class FormatLegality {
  final bool blitzLegal;
  final bool ccLegal;
  final bool commonerLegal;
  final bool llLegal;
  final bool silverAgeLegal;
  final bool blitzLivingLegend;
  final bool ccLivingLegend;
  final bool blitzBanned;
  final bool ccBanned;
  final bool commonerBanned;
  final bool llBanned;
  final bool silverAgeBanned;
  final bool blitzSuspended;
  final bool ccSuspended;
  final bool commonerSuspended;
  final bool llRestricted;

  const FormatLegality({
    required this.blitzLegal,
    required this.ccLegal,
    required this.commonerLegal,
    required this.llLegal,
    required this.silverAgeLegal,
    required this.blitzLivingLegend,
    required this.ccLivingLegend,
    required this.blitzBanned,
    required this.ccBanned,
    required this.commonerBanned,
    required this.llBanned,
    required this.silverAgeBanned,
    required this.blitzSuspended,
    required this.ccSuspended,
    required this.commonerSuspended,
    required this.llRestricted,
  });

  factory FormatLegality.fromJson(Map<String, dynamic> json) {
    return FormatLegality(
      blitzLegal: json['blitz_legal'] as bool? ?? false,
      ccLegal: json['cc_legal'] as bool? ?? false,
      commonerLegal: json['commoner_legal'] as bool? ?? false,
      llLegal: json['ll_legal'] as bool? ?? false,
      silverAgeLegal: json['silver_age_legal'] as bool? ?? false,
      blitzLivingLegend: json['blitz_living_legend'] as bool? ?? false,
      ccLivingLegend: json['cc_living_legend'] as bool? ?? false,
      blitzBanned: json['blitz_banned'] as bool? ?? false,
      ccBanned: json['cc_banned'] as bool? ?? false,
      commonerBanned: json['commoner_banned'] as bool? ?? false,
      llBanned: json['ll_banned'] as bool? ?? false,
      silverAgeBanned: json['silver_age_banned'] as bool? ?? false,
      blitzSuspended: json['blitz_suspended'] as bool? ?? false,
      ccSuspended: json['cc_suspended'] as bool? ?? false,
      commonerSuspended: json['commoner_suspended'] as bool? ?? false,
      llRestricted: json['ll_restricted'] as bool? ?? false,
    );
  }
}