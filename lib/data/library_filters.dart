import 'card.dart';

/// Format legality choices. Multi-select with OR semantics.
enum FormatChoice {
  classicConstructed('Classic Constructed'),
  blitz('Blitz'),
  livingLegend('Living Legend'),
  commoner('Commoner');

  final String label;
  const FormatChoice(this.label);
}

/// All filter state for the library. An immutable snapshot — mutate via
/// [copyWith] to produce a new instance.
class LibraryFilters {
  final Set<FormatChoice> formats;
  final Set<String> types;
  final Set<String> subTypes;
  final Set<String> classes;
  final Set<String> talents;
  final Set<String> setIds;
  final String containsText;

  const LibraryFilters({
    this.formats = const {},
    this.types = const {},
    this.subTypes = const {},
    this.classes = const {},
    this.talents = const {},
    this.setIds = const {},
    this.containsText = '',
  });

  /// True if no filters narrow the list (everything passes).
  bool get isEmpty =>
      formats.isEmpty &&
      types.isEmpty &&
      subTypes.isEmpty &&
      classes.isEmpty &&
      talents.isEmpty &&
      setIds.isEmpty &&
      containsText.isEmpty;

  /// Number of active filter facets, for the "Filter (N)" badge.
  int get activeCount {
    int n = 0;
    if (formats.isNotEmpty) n++;
    if (types.isNotEmpty) n++;
    if (subTypes.isNotEmpty) n++;
    if (classes.isNotEmpty) n++;
    if (talents.isNotEmpty) n++;
    if (setIds.isNotEmpty) n++;
    if (containsText.isNotEmpty) n++;
    return n;
  }

  LibraryFilters copyWith({
    Set<FormatChoice>? formats,
    Set<String>? types,
    Set<String>? subTypes,
    Set<String>? classes,
    Set<String>? talents,
    Set<String>? setIds,
    String? containsText,
  }) {
    return LibraryFilters(
      formats: formats ?? this.formats,
      types: types ?? this.types,
      subTypes: subTypes ?? this.subTypes,
      classes: classes ?? this.classes,
      talents: talents ?? this.talents,
      setIds: setIds ?? this.setIds,
      containsText: containsText ?? this.containsText,
    );
  }

  /// Tests if a card passes all active filters.
  bool passes(CardData card) {
    // Type: card's types must include at least one selected type.
    if (types.isNotEmpty && !card.types.any(types.contains)) return false;

    // Sub-Type: same logic against subTypes set.
    if (subTypes.isNotEmpty && !card.types.any(subTypes.contains)) return false;

    // Class: card's types must include at least one selected class.
    if (classes.isNotEmpty && !card.types.any(classes.contains)) return false;

    // Talent: card's types must include at least one selected talent.
    if (talents.isNotEmpty && !card.types.any(talents.contains)) return false;

    // Set: at least one printing must be in a selected set.
    if (setIds.isNotEmpty &&
        !card.printings.any((p) => setIds.contains(p.setId))) {
      return false;
    }

    // Contains text: substring match against functional_text_plain.
    if (containsText.isNotEmpty) {
      final q = containsText.toLowerCase();
      if (!card.functionalTextPlain.toLowerCase().contains(q)) return false;
    }

    // Format legality: card must be legal in at least one selected format.
    if (formats.isNotEmpty && !_passesAnyFormat(card)) return false;

    return true;
  }

  bool _passesAnyFormat(CardData card) {
    final l = card.legality;
    for (final f in formats) {
      switch (f) {
        case FormatChoice.classicConstructed:
          if (l.ccLegal && !l.ccBanned && !l.ccSuspended && !l.ccLivingLegend) {
            return true;
          }
        case FormatChoice.blitz:
          if (l.blitzLegal &&
              !l.blitzBanned &&
              !l.blitzSuspended &&
              !l.blitzLivingLegend) {
            return true;
          }
        case FormatChoice.livingLegend:
          if (l.llLegal && !l.llBanned) {
            return true;
          }
        case FormatChoice.commoner:
          if (l.commonerLegal && !l.commonerBanned && !l.commonerSuspended) {
            return true;
          }
      }
    }
    return false;
  }
}