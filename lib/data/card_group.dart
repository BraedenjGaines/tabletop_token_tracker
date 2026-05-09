import 'card.dart';

/// A group of cards that share a name. For most cards this is one entry; for
/// attack cards with multiple pitch variants, this is up to three entries.
///
/// The representative card is used for display purposes (showing image in
/// detail view, sorting, etc.). Variants is the full list including the rep.
class CardGroup {
  final String name;
  final CardData representative;
  final List<CardData> variants;

  CardGroup({
    required this.name,
    required this.representative,
    required this.variants,
  });

  /// True if this group has more than one variant.
  bool get hasMultipleVariants => variants.length > 1;

  /// Pitch values in this group, deduplicated and sorted (1, 2, 3).
  /// Cards without numeric pitch are excluded.
  List<int> get pitchValues {
    final pitches = <int>{};
    for (final v in variants) {
      final n = int.tryParse(v.pitch);
      if (n != null) pitches.add(n);
    }
    final sorted = pitches.toList()..sort();
    return sorted;
  }

  /// Group a flat list of cards by name. Within each group, cards are sorted
  /// by pitch ascending so the "first" variant is the lowest-pitch one.
  static List<CardGroup> from(List<CardData> cards) {
    final byName = <String, List<CardData>>{};
    for (final card in cards) {
      byName.putIfAbsent(card.name, () => []).add(card);
    }
    final groups = <CardGroup>[];
    for (final entry in byName.entries) {
      final variants = List<CardData>.from(entry.value);
      variants.sort((a, b) {
        final ap = int.tryParse(a.pitch) ?? 999;
        final bp = int.tryParse(b.pitch) ?? 999;
        return ap.compareTo(bp);
      });
      groups.add(CardGroup(
        name: entry.key,
        representative: variants.first,
        variants: variants,
      ));
    }
    return groups;
  }
}