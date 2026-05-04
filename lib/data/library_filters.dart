import 'card.dart';

/// Single-value category for the top-level "Showing" filter.
enum LibraryCategory {
  all('All'),
  heroes('Heroes'),
  tokens('Tokens'),
  deckCards('Deck Cards');

  final String label;
  const LibraryCategory(this.label);
}

/// Format legality choices. Multi-select with OR semantics — a card passes
/// if it's legal in any selected format. Empty selection = no format filter.
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
  final LibraryCategory category;
  final Set<FormatChoice> formats;
  final Set<String> classes;
  final Set<String> types;
  final Set<String> setIds;
  final String containsText;

  const LibraryFilters({
    this.category = LibraryCategory.all,
    this.formats = const {},
    this.classes = const {},
    this.types = const {},
    this.setIds = const {},
    this.containsText = '',
  });

  /// True if no filters narrow the list (everything passes).
  bool get isEmpty =>
      category == LibraryCategory.all &&
      formats.isEmpty &&
      classes.isEmpty &&
      types.isEmpty &&
      setIds.isEmpty &&
      containsText.isEmpty;

  /// Number of active filter facets, for the "Filter (N)" badge.
  int get activeCount {
    int n = 0;
    if (category != LibraryCategory.all) n++;
    if (formats.isNotEmpty) n++;
    if (classes.isNotEmpty) n++;
    if (types.isNotEmpty) n++;
    if (setIds.isNotEmpty) n++;
    if (containsText.isNotEmpty) n++;
    return n;
  }

  LibraryFilters copyWith({
    LibraryCategory? category,
    Set<FormatChoice>? formats,
    Set<String>? classes,
    Set<String>? types,
    Set<String>? setIds,
    String? containsText,
  }) {
    return LibraryFilters(
      category: category ?? this.category,
      formats: formats ?? this.formats,
      classes: classes ?? this.classes,
      types: types ?? this.types,
      setIds: setIds ?? this.setIds,
      containsText: containsText ?? this.containsText,
    );
  }

  /// Tests if a card passes all active filters.
  bool passes(CardData card) {
    // Category
    if (!_passesCategory(card)) return false;

    // Class: card's types must include at least one selected class.
    if (classes.isNotEmpty) {
      if (!card.types.any(classes.contains)) return false;
    }

    // Type: card's types must include at least one selected type.
    if (types.isNotEmpty) {
      if (!card.types.any(types.contains)) return false;
    }

    // Set: at least one printing must be in a selected set.
    if (setIds.isNotEmpty) {
      if (!card.printings.any((p) => setIds.contains(p.setId))) return false;
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

  bool _passesCategory(CardData card) {
    switch (category) {
      case LibraryCategory.all:
        return true;
      case LibraryCategory.heroes:
        return card.types.contains('Hero');
      case LibraryCategory.tokens:
        return card.types.contains('Token');
      case LibraryCategory.deckCards:
        return !card.types.contains('Hero') && !card.types.contains('Token');
    }
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
          if (l.blitzLegal && !l.blitzBanned && !l.blitzSuspended && !l.blitzLivingLegend) {
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